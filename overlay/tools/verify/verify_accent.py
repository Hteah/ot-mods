#!/usr/bin/env python3
"""ACCENT under the port: GRID RECORDING trig taps cycle a step off -> FULL ->
SOFT -> off, and the soft step's red LED is dim.

    python3 tools/verify/verify_accent.py REMIX

One load, forked (`ot_emu --scenario`), each scenario from the boot:

  full     REC (grid), trig 1 tapped once: step 1 has a sample trig, no AMP
           VOL lock; trig 1's red LED at level 15.
  soft     ... tapped twice: the trig stays, AMP VOL lock = the Part VOL's
           -6 dB value (round(v*181/256), below v), in the bank blob and its
           battery mirror; red LED at level 5.
  off      ... three times: no trig, no lock; the LED off.
  held     tapped once, then held while encoder A turns (a stock lock edit),
           released: the trig stays and stays FULL (the release that follows
           an edit never reaches ACCENT).
  disabled acc_on poked to 0, tapped twice: stock -- no trig.
  toggle_* TRACK 1 held + CUE once (off) or twice (on), then tapped twice:
           off = stock (no trig), on = SOFT; the cue mask is untouched.
  cue_stock CUE held + TRACK 1 (stock's order): track 1 cued, ACCENT on.
  play_*   tapped once (full) or twice (soft), grid off, PLAY: when step 1
           fires, the live lane's AMP VOL (0x80000810 + 15) is the Part VOL
           or the soft value -- stock applies the lock -- and outside grid
           recording the trig LED's level is stock's 15 again.

Uses OT_PROJECT / ~/.octabam_project when set, else an empty project
directory (stock initialises the absent bank files). Cannot see: the
hardware's LED brightness, MIDI tracks (ACCENT is audio only), MKII.
"""
import os
import pathlib
import shutil
import struct
import subprocess
import sys

sys.path.insert(0, str(pathlib.Path(__file__).resolve().parents[1]))
import toolpath  # noqa: E402,F401
from remix import registry  # noqa: E402

ROOT = pathlib.Path(__file__).resolve().parents[2]
EMU = ROOT / "out/emu/ot_emu"
OUT = ROOT / "out/accent-verify"
BLOB, BANK_LEN = 0x400e21e0, 0x9b340
MIRROR = 0x1001614e
DBPTR, UI_TRACK, UI_PART, UI_PTN = 0x46c82456, 0x100b14cc, 0x100b14cf, 0x100b14d0
PTN_STR, TRK_STR, PART_STR, AMP_VOL = 0x8ed8, 0x91a, 6322, 0x8eea3
LOCK_VOL = 0x59 + 15
K = dict(no=0x32, rec=0x29, play=0x28, stop=0x27, cue=0x2a, t1=0x00, track1=0x10)
CUE_MASK = 0x80000009              # cued tracks, bit t
LANES = 0x80000810               # live lane: 72 bytes a track, AMP VOL at +15


class Script:
    def __init__(self):
        self.t, self.lines = 1500, []

    def send(self, x, gap=60):
        self.lines.append(f"{self.t} {x}"); self.t += gap

    def tap(self, k, gap=300):
        self.send(f"key {K[k]:#x} down", 40); self.send(f"key {K[k]:#x} up", gap)

    def text(self):
        return "\n".join(self.lines + [f"{self.t + 500} quit"]) + "\n"


def scenario(tag):
    s = Script()
    s.tap("no", 400)                               # the boot's date prompt
    if tag in ("toggle_off", "toggle_on"):
        for _ in range(1 if tag == "toggle_off" else 2):
            s.send(f"key {K['track1']:#x} down", 150)    # TRACK held, then CUE
            s.tap("cue", 150)
            s.send(f"key {K['track1']:#x} up", 400)
    if tag == "cue_stock":
        s.send(f"key {K['cue']:#x} down", 150)           # CUE held, then TRACK: stock cue
        s.tap("track1", 150)
        s.send(f"key {K['cue']:#x} up", 400)
        return s
    s.tap("rec", 400)                              # grid recording
    taps = dict(full=1, soft=2, off=3, held=1, disabled=2, play_full=1, play_soft=2,
                toggle_off=2, toggle_on=2)[tag]
    for _ in range(taps):
        s.tap("t1", 400)
    if tag == "held":
        s.send(f"key {K['t1']:#x} down", 150)
        s.send("enc 0 3", 300)
        s.send(f"key {K['t1']:#x} up", 400)
    if tag.startswith("play"):
        s.tap("rec", 400)                          # grid recording off
        s.tap("play", 1500)                        # step 1 fires
    return s


def panel_leds(path):
    sys.path.insert(0, str(ROOT / "tools/panel"))
    from panel_link import PanelLink
    best = None
    for suffix in ("a", "b"):
        f = pathlib.Path(f"{path}.{suffix}")
        if f.is_file() and f.stat().st_size:
            cand = PanelLink(); cand.feed(f.read_bytes())
            if best is None or cand.stats["lcd_blocks"] > best.stats["lcd_blocks"]:
                best = cand
    return best


def main():
    remix = sys.argv[1]
    if "ACCENT" not in registry.remix(remix).modules:
        return 0
    if not EMU.is_file():
        print("  [SKIP] verify_accent: no port (make emu-cf)")
        return 0
    project = os.environ.get("OT_PROJECT", "")
    if not project:
        cfg = pathlib.Path("~/.octabam_project").expanduser()
        project = cfg.read_text().strip() if cfg.exists() else ""
    if OUT.exists():
        shutil.rmtree(OUT)
    OUT.mkdir(parents=True)
    if not project:
        empty = OUT / "empty-project"
        empty.mkdir()
        project = str(empty)            # stock initialises the absent bank files
    env = dict(os.environ, REMIX=remix, XBUS="1", SPEC="1")
    subprocess.run([sys.executable, "tools/build/build_bus.py"], cwd=ROOT, env=env,
                   stdout=subprocess.DEVNULL, check=True)
    image = OUT / "mainos.bin"
    shutil.copy2(ROOT / "out/mainos_bus.bin", image)
    nm = subprocess.run(["m68k-elf-nm", str(ROOT / "out/platform/runtime/runtime.elf")],
                        capture_output=True, text=True).stdout
    sym = {f[2]: int(f[0], 16) for f in (l.split() for l in nm.splitlines()) if len(f) == 3}
    acc_on = sym["acc_on"]
    card = OUT / "card.img"
    subprocess.run([str(ROOT / ".venv/bin/python3"), "tools/emu/ot_emu/stage_card.py",
                    project, "ACCSET", "ACCPRJ", "--out", str(card)], cwd=ROOT,
                   stdout=subprocess.DEVNULL, check=True)

    tags = ("full", "soft", "off", "held", "disabled", "play_full", "play_soft",
            "toggle_off", "toggle_on", "cue_stock")
    cmd = [str(EMU), "--image", str(image), "--card", str(card),
           "--set", "ACCSET", "--project", "ACCPRJ", "--load-ms", "90000"]
    for tag in tags:
        sp = OUT / f"{tag}.script"; sp.write_text(scenario(tag).text())
        dump = (f"{BLOB:#x},{BANK_LEN:#x}={OUT / (tag + '_bank.bin')};"
                f"{MIRROR:#x},{PTN_STR * 16:#x}={OUT / (tag + '_mirror.bin')};"
                f"{DBPTR:#x},4={OUT / (tag + '_db.bin')};"
                f"{UI_TRACK:#x},8={OUT / (tag + '_ui.bin')};"
                f"{LANES:#x},72={OUT / (tag + '_lane.bin')};"
                f"{acc_on:#x},4={OUT / (tag + '_on.bin')};"
                f"{CUE_MASK:#x},1={OUT / (tag + '_cue.bin')}")
        poke = f" --poke {acc_on:#x}=00;{acc_on + 1:#x}=00;{acc_on + 2:#x}=00;{acc_on + 3:#x}=00" \
            if tag == "disabled" else ""
        cmd += ["--scenario", f"{OUT / (tag + '.log')} --live-script {sp}{poke} "
                f"--serial-out {OUT / (tag + '.serial')} --mem-dump {dump}"]
    with (OUT / "port.log").open("w") as f:
        r = subprocess.run(cmd, cwd=ROOT, stdout=f, stderr=subprocess.STDOUT)
    if r.returncode:
        print(f"  [FAIL] verify_accent: ot_emu exit {r.returncode} -- {OUT / 'port.log'}")
        return 1

    fails = 0

    def check(ok, what):
        nonlocal fails
        print(f"  [{'PASS' if ok else 'FAIL'}] verify_accent: {what}")
        fails += not ok

    for tag in tags:
        log = (OUT / f"{tag}.log").read_text(errors="replace")
        bank = (OUT / f"{tag}_bank.bin").read_bytes()
        mirror = (OUT / f"{tag}_mirror.bin").read_bytes()
        db = struct.unpack(">I", (OUT / f"{tag}_db.bin").read_bytes())[0]
        ui = (OUT / f"{tag}_ui.bin").read_bytes()
        trk, part, ptn = ui[0], ui[UI_PART - UI_TRACK], ui[UI_PTN - UI_TRACK]
        base = db - BLOB
        if not 0 <= base < BANK_LEN:
            check(False, f"{tag}: blob pointer {db:#x} outside bank 0 -- dump the right bank")
            continue
        toff = ptn * PTN_STR + trk * TRK_STR
        trac = base + toff
        vol = bank[base + part * PART_STR + AMP_VOL + trk * 24]
        soft = min((vol * 181 + 128) >> 8, vol - 1)
        trig = bool(bank[trac + 7] & 1)            # mask 0, step 1
        lock = bank[trac + LOCK_VOL]
        mlock = mirror[toff + LOCK_VOL]
        link = panel_leds(OUT / f"{tag}.serial")
        red_on = link is not None and link.led_bits().get(0, False)
        level = link.leds.get(0) if link else None
        info = f"trig={int(trig)} lock={lock:#04x} mirror={mlock:#04x} PartVOL={vol} red={int(red_on)} level={level}"
        lane = (OUT / f"{tag}_lane.bin").read_bytes()[15]
        on = struct.unpack(">I", (OUT / f"{tag}_on.bin").read_bytes())[0]
        cued = (OUT / f"{tag}_cue.bin").read_bytes()[0]
        info += f" acc_on={on} cue={cued:#04x}"
        clean = "ended on quit" in log
        if tag == "full":
            check(clean and trig and lock == 0xff and red_on and level == 15,
                  f"full: step 1 FULL, LED red 15 ({info})")
        elif tag == "held":
            ptch = bank[trac + 0x59]
            check(clean and trig and lock == 0xff and ptch != 0xff and red_on and level == 15,
                  f"held: the edit locked PTCH ({ptch:#04x}) and step 1 stays FULL ({info})")
        elif tag == "toggle_off":
            check(clean and on == 0 and not trig and cued == 0,
                  f"toggle_off: TRACK + CUE turned ACCENT off (no cue), two taps = stock off ({info})")
        elif tag == "toggle_on":
            check(clean and on == 1 and trig and lock == soft and level == 5 and cued == 0,
                  f"toggle_on: TRACK + CUE twice = on again, two taps = SOFT ({info})")
        elif tag == "cue_stock":
            check(clean and on == 1 and cued & 1,
                  f"cue_stock: CUE held + TRACK 1 cues track 1, ACCENT stays on ({info})")
        elif tag == "play_full":
            check(clean and lane == vol and level == 15,
                  f"play_full: step 1 fired, live AMP VOL {lane} = Part VOL; LED level 15 off grid ({info})")
        elif tag == "play_soft":
            check(clean and lane == soft and level == 15,
                  f"play_soft: step 1 fired, live AMP VOL {lane} = soft {soft}; LED level back to 15 off grid ({info})")
        elif tag == "soft":
            check(clean and trig and lock == soft and mlock == soft and red_on and level == 5,
                  f"soft: step 1 SOFT, VOL lock {soft} in blob and mirror, LED red 5 ({info})")
        else:
            check(clean and not trig and lock == 0xff and not red_on,
                  f"{tag}: step 1 off, no lock, LED off ({info})")
    return int(bool(fails))


if __name__ == "__main__":
    sys.exit(main())
