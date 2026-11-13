#!/usr/bin/env python3
"""SMPL / RSMP under the port (MKI panel): the two machine rows, their init,
one-button recording and the take lengths.

    python3 tools/verify/verify_smpl.py REMIX

Each scenario boots the remix's image on a private empty card (the port's
test tones on the inputs), dismisses the date dialog and, where it says so,
chooses a machine on track 1:

  win_smpl   double-tap T1, LEFT, DOWN x5, YES: SMPL. T1 is FLEX with the
             signature "SM", 1, its FLEX slot recorder buffer 1 (0x80), and
             its recorder TRIG ONE2, RLEN MAX, SRC3 "-".
  src_rsmp   FUNC + SRC (SRC SETUP), DOWN x6, YES: RSMP. Signature "RS", 1,
             slot 0x80, INAB / INCD "-", SRC3 MAIN, TRIG ONE2, RLEN MAX.
  keep       SMPL, then the window again and YES in its slot list: still SMPL.
  to_flex    SMPL, then the window, LEFT, YES on FLEX: FLEX, no signature.
  smpl_ab    SMPL, the A/B key alone twice 1 s apart: one take, armed and
             ended (ONE2), 1.0 s long; the recorder's word names A/B (0x1000).
  rsmp_ab    RSMP, the same: the word names the internal source (0x4000) only.
  rsmp_smpl  RSMP (INAB / INCD "-"), then the window, LEFT (FLEX), DOWN x4, YES: SMPL
             with INAB A B, INCD C D, SRC3 "-"; an A/B take of the inputs saves a
             file with real audio, not the two values ACCLOOP18 wrote (Heath, 31 Oct).
  silent     SMPL with INAB / INCD poked to "-", an A/B take: NO SOUND IN TAKE, and
             no file (the take is scanned before the normalize; Heath, 1 Nov).
  silent24   the same with 24-bit recorder buffers.
  save24     24-bit recorder buffers, an A/B take of the inputs: saved as a 24-bit
             file with audio at -4 dBFS (the 24-bit gain's 64-bit division), no NO SOUND IN TAKE.
  clear_one  a take, saved (so tied to its file), then the editor's CLEAR SLOT and YES
             once: the buffer is empty, RECORDING CLEARED! (stock first only unties it).
  proc       a 6 s take: PROCESSING n% shown more than once while it is scanned /
             gained, then SAVING TAKE n%; saved at -4 dBFS.
  long24     24-bit, the A/B key at 11 s and 71 s: each take runs to the port's recorder
             limit (16 s at 24-bit here) and stops itself, is scanned, gained in one pass
             and saved: two 16 s files at -4 dBFS. The second take's buffer straddles
             0x46000000 (the port's straddle fix, machine.cpp; before it the scan read
             the first take's samples there and saved at 0.671).
  live_long  DYNAMIC RECORDERS on (poked through the boot, with 24-bit buffers), a 60 s take:
             the editor's view (0x400ce724) zoom to fit (0x40077198, d0) passes stock's
             20,000 frames a pixel and keeps growing with the take to its end (32,168 at
             60 s, ~82 px); the renderer (0x4008e3d8) draws with that step. Stock sits at
             20,000 from ~37 s (Heath's MKI: the live waveform stopped growing at ~42 s).
  dyn16      DYNAMIC RECORDERS on, 16-bit, a 2 s take: the editor's first zoom to fit is to the
             memory cap (213,130 frames a pixel), past stock's 131,072, where the overview bar
             (0x4006f458) divides by length >> 14 -- 0 as the take starts. ACCLOOP20 halted
             there (EXCEPTION VEC:05 ADDR:4006F458, Heath's MKI, 1 Nov 2026); it runs and saves.
  edit_save  a take, SAVE SAMPLES TO = PROJ DIR, then the editor's FILE > SAVE AND ASSIGN
             SAMPLE twice, the prefilled name kept: AUDIO/SMPL/<take>-2 then -3 (an edit of
             the -2 drops its ending), nothing in the pool root or the project, the original
             untouched, the buffer assigned to the -3 (Heath, 2 Nov 2026).
  monitor    SMPL chosen at ~9 s, an A/B take 11 s -> 13 s. T1 plays the inputs it records
             (sm_mon: L = A + C, R = B + D, exactly, as THRU's renderer) while its slot is empty
             and while the take records -- T1's post-FX read-back (core 1's block at 0x80003190,
             host-port channel 1) carries them with no trig; silent as stock FLEX before SMPL is
             chosen and once the take exists; the take saves as before (Heath, 7 Nov 2026: an
             empty SAMPLER is a THRU track, through its own FX; the take stays dry).
  mon_rsmp   RSMP, the same take: T1's read-back stays silent (only SAMPLER monitors).
  mon_stop   SMPL, PLAY, STOP, STOP (the stop releases every AMP envelope), then a take: the
             empty SAMPLER is still heard and heard while it records (sm_envgate reopens its
             envelope). ACCLOOP28 went silent here, as on Heath's MKI (7 Nov 2026).
  mon_armed  (REC THRESHOLD) SMPL, a -50 dBFS sine on the inputs, a ONE2 take 11 s -> 12 s, then
             TRIG THR / LEV -40 dB poked and A/B at 14 s: armed, no take (the sine is under the
             threshold); T1 silent with its take before the arm, monitoring while armed.
  trash      a saved take, then the editor's FILE page, DOWN x6 (its seventh row, TRASH TAKE),
             YES, YES: the file and its .ot are in AUDIO/SMPL/TRASH, not AUDIO/SMPL, the buffer is
             empty and untied, TAKE TRASHED! (Heath, 7 Nov 2026).
  trash_two  the same twice: the retake gets the trashed take's name, so it moves as -2.
  trash_none RSMP, an A/B take of the port's silent MAIN (NO SOUND IN TAKE, no file), then
             the FILE page: its stock six rows (no file to trash); the takes above count 7.
  stock_ab   no machine chosen, quick mode off, the A/B key alone twice:
             nothing (the contrast: stock needs TRACK).
  loop1      LOOPER (RLEN 1: one loop), a recorder trig on step 1 (GRID
             RECORDING with RECORDING SETUP open), PLAY: ONE take of one
             16-step loop, 88,200 samples at 120 BPM, then no more takes while
             the pattern plays on; not saved; the editor opened once.
  loop2      as loop1 with RLEN 2: one take of two loops, 176,400 samples.
  loopmax    as loop1 with RLEN MAX: one take until STOP (7.4 s in: over 3 loops).
  again      loop1, STOP, PLAY: a second take.
  smpl_trig  SAMPLER, a recorder trig on step 1, PLAY: no take (SAMPLER / RESAMPLE are
             red key only, tap in / tap out; Heath, 8 Nov 2026).
  smpl_tap   SAMPLER with a recorder trig and a sample trig on step 1, playing: the red key
             taps a ~3 s take in and out, saved.
  save       SMPL, a 1 s A/B take: the audio editor opens at the take's start
             and is still open at the end; once the take ends it is saved,
             R1-000000-0000.wav (the port's clock is unset) and .ot in the
             set's AUDIO/SMPL (made by that take), one second, not silent.
  save_no    as save, then NO: the editor closes; the file is there.
  save_two   two takes, NO between: two files, the second R1-000000-0000-2.
  save_proj  SAVE SAMPLES TO poked to PROJ DIR, a take: still AUDIO/SMPL, nowhere else.
  play_stop  PLAY, a 2 s key take, STOP: the take is saved and the sequencer stops.
  pin        a take, TRACK 2 mid-take: the editor stays on the take while it records.
  pin_free   a take on T1, stopped and saved, then TRACK 2: the editor follows (not stuck).
  stop_t2    a take, TRACK 2, the red key: the take stops (before: ran to the memory limit).
  pin_live   a 9 s take, TRACK 2 at 3 s, TRACK 1 at 6 s: the recorded length the editor's
             zoom (0x4006f99e) and the waveform renderer (0x4008e43a, 0x4008e524) get grows
             the whole take, never 0. (27 Oct 2026: on TRACK 2 they read track 2's idle
             recorder, 0 -- the editor stayed on the take but drew nothing until it stopped.)
  reopen     a take, TRACK 2, NO (the editor closes), TRACK 2 again, TRACK 2 + BANK: the editor
             opens on the take, not TRACK 2's sample. (27 Oct 2026: the pin held only while
             the editor stayed open; reopened, it showed the current track's sample.)
  reopen_free the take stopped and saved, NO, TRACK 2, TRACK 2 + BANK: TRACK 2's sample (stock).
  play_track as play_stop with a TRACK key between: it arms no second take. (25 Oct 2026:
             a save started while the record key was down took its release, so the panel
             kept the key held: STOP never stopped, and TRACK keys armed takes.)
LOOPER / RELOOPER (Heath, 7 Nov 2026: SAMPLER / RESAMPLE without the auto-save, for live looping):
  lp_win     the machine window, DOWN x7: LOOPER, signature "LP", 1, set up as SMPL.
  rl_src     SRC SETUP, DOWN x8: RELOOPER, "RL", 1, set up as RSMP (rows 7 and 8 have no spare
             PLAYBACK descriptor slot: SRC SETUP reads FLEX's there, sm_pbd1 / sm_pbd2, no fault).
  lp_take    LOOPER, a 1 s A/B take: the editor opens; no AUDIO/SMPL, no file, none of our
             PROCESSING / SAVING / NO SOUND messages.
  rl_take    RELOOPER, the same: the internal source.
  lp_loop    LOOPER, a recorder trig on step 1, PLAY: one loop of 88,200 samples, nothing saved.
  lp_mon     LOOPER monitors as SAMPLER does; nothing saved.
  lp_save    a LOOPER take, then the editor's FILE > SAVE AND ASSIGN twice, the prefilled name
             kept: AUDIO/SMPL/R1-000000-0000 then -2, not normalized, the buffer assigned to it.
With REC THRESHOLD in the remix (TRIG poked to THR, LEV raw 4 = -40 dB, in the Part and its
battery RAM mirror; the inputs fed a WAV from the DSP boot):
  thr_quiet  SMPL, silence, the A/B key: armed, no take.
  thr_late   SMPL, silence then a -20 dBFS sine on A-D, the A/B key in the silence:
             one take, started by the sine, stopped by A/B, saved.
  rsmp_quiet RSMP with SRC3 poked to T2 (an empty track), the same sine on the inputs:
             armed, no take -- RSMP measures its source, not the inputs; the block it
             measures is T2's read-back, 0x80003210 / 0x80003610 as the half flips.
  rsmp_late  RSMP, SRC3 MAIN: the block it measures is MAIN's, 0x80005e60. MAIN is
             silent under the port (a plain RSMP take of it is all zeros), so no take
             here; that a real MAIN fires it is for the hardware.
SAVE LOCK: a take's buffer is locked from its end until its file is written. Each lock_
scenario makes a 1 s A/B take, lets its save finish, then pokes sm_busy so the runtime
believes buffer 1's save is still in flight (sm_cur is 0 from that save):
  lock_edit  LFO (the editor's EDIT page), YES YES = SELECT ALL, then YES, DOWN x7, YES =
             NORMALIZE SELECTION (without a span it only says SELECT SPAN FIRST!): the
             message is not posted (sm_po_drop), the editor's own done callback (0x4007553c)
             runs, the busy flag ends 0, SAVING TAKE.. is shown.
  edit_free  the same without the poke: NORMALIZE SELECTION is posted (contrast).
  lock_take  the A/B key twice: no second take, SAVING TAKE.. shown.
  lock_clear FX2 (the FILE page), DOWN x4, YES = CLEAR SLOT: its dialog (DISASSOCIATE,
             the take is tied to its file) does not open; SAVING TAKE.. shown.
  clear_free the same without the poke: the dialog opens (contrast).
Every take lands in the set's AUDIO/SMPL folder, which the first take creates.

Cannot see: the sound (the port's audio capture is silent here; the track
names RECORDING1 as its sample, and Flex on a recorder buffer is stock),
what the editor draws (the decoded LCD shows the editor; the gate reads its
window pointer), saving a project (the signature sits where CX OSC's does, which survives on
hardware), the hardware.
"""
import os
import pathlib
import re
import shutil
import subprocess
import sys
from concurrent.futures import ThreadPoolExecutor

sys.path.insert(0, str(pathlib.Path(__file__).resolve().parents[1]))
import toolpath  # noqa: E402,F401
from remix import registry  # noqa: E402
sys.path.insert(0, str(pathlib.Path(__file__).resolve().parents[1] / "emu"))
import emu_card  # noqa: E402

ROOT = pathlib.Path(__file__).resolve().parents[2]
EMU = ROOT / "out/emu/ot_emu"
OUT = ROOT / "out/smpl-verify"
BLOB = 0x400E21E0                     # bank 0, part 0 / pattern 0, track 0
MACH, SIG, SLOT, REC = BLOB + 0x8EDA2, BLOB + 0x8EDBC, BLOB + 0x8F04B, BLOB + 0x8F382
MAILBOX, LIMIT, LEN1 = 0x46C7E9FA, 0x46C7FE24, 0x46C922C4 + 128 * 44 + 16
YES, NO, FUNC, SRC, T1, LEFT, DOWN = 0x31, 0x32, 0x2D, 0x22, 0x10, 0x34, 0x20
AB, REC_KEY, PLAY, STOP, TRIG1 = 0x2B, 0x29, 0x28, 0x27, 0x00
RLEN_PART, RLEN_SHADOW = REC + 2, 0x1001614E + 0x8F382 + 2   # the Part's and battery RAM's RLEN, track 1
EDITOR = 0x460E5E4C                   # the audio editor's window; 0 = closed
ED_SLOT = 0x46C8D19C                  # the slot the editor shows (recorder buffer n = 0x80 + n)
T2 = 0x11
BANK = 0x2F


def aed(t, trk=T2):
    """TRACK + BANK: the audio editor on the held track's sample (0x40083ce0). Heath's
    FUNC + BANK opens nothing under the port; both reach the window's open 0x4006e160."""
    return [f"{t} key {trk:#x} down", f"{t + 300} key {BANK:#x} down", f"{t + 450} key {BANK:#x} up",
            f"{t + 700} key {trk:#x} up"]
AUDIO = "OCTABAM/AUDIO/SMPL/"        # the takes' folder, made on the first take
TRANSPORT = 0x800065B8                # 1 = the sequencer runs (STEM_REC.md 1.0)
SAVE_TO = 0x800000A4                  # PERSONALIZE > SAVE SAMPLES TO: 0 AUD POOL, 1 PROJ DIR


def tap(t, k, hold=60):
    return [f"{t} key {k:#x} down", f"{t + hold} key {k:#x} up"]


def downs(t, n):
    return sum((tap(t + 250 * i, DOWN) for i in range(n)), [])


def double(t):
    return [f"{t} key {T1:#x} down", f"{t + 60} key {T1:#x} up",
            f"{t + 210} key {T1:#x} down", f"{t + 270} key {T1:#x} up"]


PRE = tap(1500, YES) + tap(3000, YES) + tap(5000, YES)            # the date dialog
SMPL = PRE + double(6000) + tap(6800, LEFT) + downs(7300, 5) + tap(9200, YES) + tap(10000, NO)
RSMP_WIN = PRE + double(6000) + tap(6800, LEFT) + downs(7300, 6) + tap(9200, YES) + tap(10000, NO)
LOOP = PRE + double(6000) + tap(6800, LEFT) + downs(7300, 7) + tap(9200, YES) + tap(10000, NO)
RLOOP = PRE + double(6000) + tap(6800, LEFT) + downs(7300, 8) + tap(9200, YES) + tap(10000, NO)
RLOOP_SRC = (PRE + [f"6000 key {FUNC:#x} down", f"6300 key {SRC:#x} down", f"6600 key {SRC:#x} up",
                    f"6900 key {FUNC:#x} up"] + downs(7400, 8) + tap(9600, YES))
RSMP_SRC = (PRE + [f"6000 key {FUNC:#x} down", f"6300 key {SRC:#x} down", f"6600 key {SRC:#x} up",
                   f"6900 key {FUNC:#x} up"] + downs(7400, 6) + tap(9200, YES))
RTRIG = (tap(10300, REC_KEY) + [f"10700 key {FUNC:#x} down", f"10760 key {AB:#x} down",
                                f"10820 key {AB:#x} up", f"10880 key {FUNC:#x} up"]
         + tap(11300, TRIG1) + tap(11700, NO) + tap(12100, REC_KEY))

NOIN = [f"10200 poke {REC:#x}=0", f"10200 poke {REC + 1:#x}=0",
        f"10200 poke {RLEN_SHADOW - 2:#x}=0", f"10200 poke {RLEN_SHADOW - 1:#x}=0"]   # INAB, INCD "-"
TRASHES = {"trash", "trash_two", "trash_none"}
FILE_ROWS = 0x460E7096                # the FILE page list's row count (+16; +12 = rows shown)
SILENTS = {"silent", "silent24", "save24", "clear_one", "proc", "long24"} | TRASHES
# RECORDER FORMAT (0x80000053) 24-bit, poked every 100 ms through the boot: under the port
# a project's RECORD_24BIT=1 loads, then a write the watch can't see (an alias) puts 0
# back before the recorder buffers' re-init (0x400970a8 reads it, ~8.9 s); a poke after
# the re-init keeps 16-bit buffers. With these the take is saved 24-bit (1 Nov 2026).
FMT24 = [f"{t} poke 0x80000053=1" for t in range(5200, 10001, 100)]

DYN = [f"{t} poke 0x80000052=1" for t in range(5200, 10001, 100)]   # DYNAMIC RECORDERS, as FMT24

SCENARIOS = {
    "win_smpl": (SMPL, 10600),
    "src_rsmp": (RSMP_SRC, 10200),
    "keep": (SMPL + double(11000) + tap(11800, YES) + tap(12600, NO), 13400),
    "to_flex": (SMPL + double(11000) + tap(11800, LEFT) + tap(12600, YES) + tap(13400, NO), 14200),
    "smpl_ab": (SMPL + tap(11000, AB) + tap(12000, AB), 14000),
    "rsmp_ab": (RSMP_WIN + tap(11000, AB) + tap(12000, AB), 14000),
    "rsmp_smpl": (RSMP_WIN + double(11000) + tap(11800, LEFT) + downs(12300, 4) + tap(14200, YES)
                  + tap(15000, NO) + tap(16000, AB) + tap(17000, AB), 26000),
    "silent": (SMPL + NOIN + tap(11000, AB) + tap(12000, AB), 20000),
    "silent24": (FMT24 + SMPL + NOIN + tap(11000, AB) + tap(12000, AB), 20000),
    "save24": (FMT24 + SMPL + tap(11000, AB) + tap(12000, AB), 20000),
    "clear_one": (SMPL + tap(11000, AB) + tap(12000, AB) + tap(17500, 0x26) + downs(18000, 4)
                  + tap(19500, YES) + tap(20500, YES), 23000),
    "proc": (SMPL + tap(11000, AB) + tap(17000, AB), 30000),
    "trash": (SMPL + tap(11000, AB) + tap(12000, AB) + tap(17500, 0x26) + downs(18000, 6)
              + tap(20000, YES) + tap(21000, YES), 24000),
    "trash_two": (SMPL + tap(11000, AB) + tap(12000, AB) + tap(17500, 0x26) + downs(18000, 6)
                  + tap(20000, YES) + tap(21000, YES) + tap(23000, AB) + tap(24000, AB)
                  + tap(29500, 0x26) + downs(30000, 6) + tap(32000, YES) + tap(33000, YES), 36000),
    "trash_none": (RSMP_WIN + tap(11000, AB) + tap(12000, AB) + tap(17500, 0x26), 20000),
    "live_long": (FMT24 + DYN + SMPL + tap(11000, AB) + tap(71000, AB), 72000),
    "dyn16": (DYN + SMPL + tap(11000, AB) + tap(13000, AB), 22000),
    "long24": (FMT24 + SMPL + tap(11000, AB) + tap(71000, AB), 120000),   # two takes, each to the limit
    "stock_ab": (PRE + tap(11000, AB) + tap(12000, AB), 14000),
    "monitor": (SMPL + tap(11000, AB) + tap(13000, AB), 20000),
    "mon_stop": (SMPL + tap(10050, PLAY) + tap(10250, STOP) + tap(10400, STOP) + tap(12500, AB) + tap(13300, AB), 18000),
    "mon_rsmp": (RSMP_WIN + tap(11000, AB) + tap(13000, AB), 15000),
    "loop1": (LOOP + RTRIG + tap(12600, PLAY), 24000),
    "loop2": (LOOP + [f"10200 poke {RLEN_PART:#x}=1", f"10200 poke {RLEN_SHADOW:#x}=1"] + RTRIG
              + tap(12600, PLAY), 26000),
    "loopmax": (LOOP + [f"10200 poke {RLEN_PART:#x}=64", f"10200 poke {RLEN_SHADOW:#x}=64"] + RTRIG
                + tap(12600, PLAY) + tap(20000, STOP), 30000),
    "again": (LOOP + RTRIG + tap(12600, PLAY) + tap(17000, STOP) + tap(18000, PLAY), 30000),
    "save": (SMPL + tap(11000, AB) + tap(12000, AB), 20000),
    "save_no": (SMPL + tap(11000, AB) + tap(12000, AB) + tap(17000, NO), 20000),
    "save_two": (SMPL + tap(11000, AB) + tap(12000, AB) + tap(17000, NO) + tap(18000, AB) + tap(19000, AB), 26000),
    "save_proj": (SMPL + [f"10500 poke {SAVE_TO:#x}=1"] + tap(11000, AB) + tap(12000, AB), 20000),
    "play_stop": (SMPL + tap(11000, PLAY) + tap(12000, AB) + tap(14000, AB) + tap(30000, STOP), 36000),
    "pin": (SMPL + tap(11000, AB) + tap(12000, T2) + tap(14000, AB) + tap(22000, T1), 30000),
    "pin_free": (SMPL + tap(11000, AB) + tap(13000, AB) + tap(24000, T2), 30000),
    "stop_t2": (SMPL + tap(11000, AB) + tap(12000, T2) + tap(13000, AB), 22000),
    "pin_live": (SMPL + tap(11000, AB) + tap(14000, T2) + tap(17000, T1) + tap(20000, AB), 22000),
    "reopen": (SMPL + tap(11000, AB) + tap(12000, T2) + tap(12600, NO) + tap(13200, T2)
               + aed(13800), 15000),
    "reopen_free": (SMPL + tap(11000, AB) + tap(12000, AB) + tap(18000, NO) + tap(18600, T2)
                    + aed(19200), 20500),
    "lp_win": (LOOP, 10600),
    "rl_src": (RLOOP_SRC, 10600),
    "lp_take": (LOOP + tap(11000, AB) + tap(12000, AB), 20000),
    "rl_take": (RLOOP + tap(11000, AB) + tap(12000, AB), 20000),
    "lp_loop": (LOOP + RTRIG + tap(12600, PLAY), 24000),
    "lp_mon": (LOOP + tap(11000, AB) + tap(13000, AB), 20000),
    "play_track": (SMPL + tap(11000, PLAY) + tap(12000, AB) + tap(14000, AB) + tap(28000, T1 + 1)
                   + tap(32000, STOP), 36000),
}

TRIG_SH, QREC_SH, SRC3_SH = RLEN_SHADOW + 1, RLEN_SHADOW + 7, RLEN_SHADOW + 2
THR = [f"10200 poke {REC + 3:#x}=3", f"10200 poke {TRIG_SH:#x}=3",      # TRIG THR
       f"10200 poke {REC + 9:#x}=4", f"10200 poke {QREC_SH:#x}=4"]      # LEV -40 dB
THR_SCENARIOS = {   # name: (script, quit ms, the inputs' WAV: (silent s, loud s))
    "thr_quiet": (SMPL + THR + tap(11000, AB), 24000, (40, 0)),
    "thr_late": (SMPL + THR + tap(11000, AB) + tap(26000, AB), 50000, (16, 40)),   # 12 s take: normalize + save
    "rsmp_quiet": (RSMP_WIN + THR + [f"10200 poke {REC + 4:#x}=2", f"10200 poke {SRC3_SH:#x}=2"]
                   + tap(11000, AB), 30000, (16, 30)),
    "rsmp_late": (RSMP_WIN + THR + tap(11000, AB), 30000, (16, 30)),
    "mon_armed": (SMPL + tap(11000, AB) + tap(12000, AB)
                  + [ln.replace("10200", "13500", 1) for ln in THR] + tap(14000, AB), 17000, (0, 30, -50)),
}
WAVS = {}
LOCKS = set()
LOCK = {}     # sm_busy, sm_po_drop, sm_s_saving in the linked runtime
MONS = {"monitor", "mon_rsmp", "mon_armed", "mon_stop", "lp_mon"}   # host-port blocks dumped (--block-dump)
TS_OUT = []   # sm_thr_src's return (sm_ts_out) in the linked runtime: a1 = the block measured


def runtime_syms():
    nm = shutil.which("m68k-elf-nm")
    out = subprocess.run([nm, str(ROOT / "out/platform/runtime/runtime.elf")], capture_output=True,
                         text=True, check=True).stdout
    return {p[2]: int(p[0], 16) for p in (ln.split() for ln in out.splitlines()) if len(p) == 3}


def ts_out():
    return runtime_syms()["sm_ts_out"]


LFO, FX2 = 0x24, 0x26
NORM_MSG, NORM_DONE, TOAST, CLEAR_DLG, DIALOG = 0x460E6DF0, 0x4007553C, 0x4005A2B8, 0x40021BC8, 0x4006D57C
TAKE = SMPL + tap(11000, AB) + tap(12000, AB)
_SAVE_ED = lambda t: tap(t, FX2) + downs(t + 500, 3) + tap(t + 2000, YES) + tap(t + 3500, YES) + tap(t + 5000, YES)
PT = tap(12400, REC_KEY) + tap(12700, TRIG1) + tap(13000, REC_KEY)   # a sample trig on step 1
SCENARIOS["smpl_trig"] = (SMPL + RTRIG + tap(12600, PLAY), 24000)
SCENARIOS["smpl_tap"] = (SMPL + RTRIG + PT + tap(13400, PLAY) + tap(20000, AB) + tap(23000, AB), 32000)
SCENARIOS["lp_save"] = (LOOP + tap(11000, AB) + tap(12000, AB) + _SAVE_ED(17500) + _SAVE_ED(24000), 31000)
SCENARIOS["edit_save"] = ([f"10500 poke {SAVE_TO + 3:#x}=1"] + TAKE + _SAVE_ED(17500) + _SAVE_ED(24000), 31000)
EDIT_PATH = 0x100b14f0 + 128 * 1096   # recorder buffer 1's slot record: its file's path


def lock_poke():
    return [f"17000 poke {LOCK['sm_busy'] + 1:#x}=7f"]   # sm_busy = 0x007f0000: a save in flight


def lock_scenarios():
    edit = (tap(17500, LFO) + tap(18000, YES) + tap(18500, YES)      # the menu, SELECT ALL
            + tap(19000, YES) + downs(19500, 7) + tap(21500, YES))   # the menu, NORMALIZE SELECTION
    clear = tap(17500, FX2) + downs(18000, 4) + tap(19500, YES)
    return {
        "lock_edit": (TAKE + lock_poke() + edit, 24000),
        "edit_free": (TAKE + edit, 24000),
        "lock_take": (TAKE + lock_poke() + tap(18000, AB) + tap(19000, AB), 22000),
        "lock_clear": (TAKE + lock_poke() + clear, 22000),
        "clear_free": (TAKE + clear, 22000),
    }


def monitor_blocks(path):
    """The host-port block dump -> per frame: T1's post-FX read-back peak (core 1's channel-1
    block, its first 64 halfwords = 16 stereo samples, hi/lo), and how many of T1's render
    records equal the previous frame's input page summed as sm_mon sums it (A + C, B + D)."""
    import struct as _st
    f = path.read_bytes()
    o, rb, pages, exact = 0, {}, [], 0

    def lg(w, i):
        return (w[2 * i] << 16) | (w[2 * i + 1] & 0xffff)
    while o < len(f):
        _d, fr, ch, core, _ram, n = _st.unpack_from("<BIHBII", f, o)
        o += 16
        raw = f[o:o + 2 * n]
        o += 2 * n
        if ch == 1 and n == 256 and core == 1:
            w = _st.unpack(f"<{n}h", raw)
            rb[fr] = max(abs(x) for x in w[0:64:2])
        elif ch == 7 and n == 128:
            w = _st.unpack(f"<{n}h", raw)
            v = [lg(w, i) for i in range(64)]
            pages = (pages + [(v[32::2], v[33::2], v[0:32:2], v[1:32:2])])[-2:]   # A, B, C, D
        elif ch == 0 and n == 672 and core == 1:
            w = _st.unpack("<168h", raw[:336])
            out = [lg(w, i) for i in range(8, 40)]
            exact += any(any(A) and out[0::2] == [a + c for a, c in zip(A, C)]
                         and out[1::2] == [b + d for b, d in zip(B, D)] for A, B, C, D in pages)
    return rb, exact


def write_wav(path, silent_s, loud_s, dbfs=-20):
    """Silence, then a 1 kHz sine on inputs A-D (4 channels, 16 bit)."""
    import math
    import struct
    import wave
    rate = 44100
    frames = bytearray(8 * int(rate * silent_s))
    for i in range(int(rate * loud_s)):
        v = int(32767 * 10 ** (dbfs / 20) * math.sin(2 * math.pi * 1000 * i / rate))
        frames += struct.pack("<4h", v, v, v, v)
    with wave.open(str(path), "wb") as f:
        f.setnchannels(4)
        f.setsampwidth(2)
        f.setframerate(rate)
        f.writeframes(bytes(frames))


def run(name, image, project):
    work = OUT / name
    work.mkdir(parents=True)
    card = work / "card.img"
    subprocess.run([str(ROOT / ".venv/bin/python3"), "tools/emu/ot_emu/stage_card.py", str(project),
                    "OCTABAM", "SMPLV", "--tree", str(work / "tree"), "--out", str(card)],
                   cwd=ROOT, check=True, capture_output=True)
    script, quit_ms = SCENARIOS[name]
    lines = sorted(script, key=lambda ln: int(ln.split()[0]))   # stable: same-ms order kept
    (work / "script").write_text("\n".join(lines + [f"{quit_ms} quit"]) + "\n")
    dump = (f"{MACH:#x},8={work / 'mach.bin'};{SIG:#x},3={work / 'sig.bin'};"
            f"{SLOT:#x},5={work / 'slot.bin'};{REC:#x},12={work / 'rec.bin'}"
            + (f";{LOCK['sm_pbuf']:#x},32={work / 'pbuf.bin'}" if name in SILENTS else "")
            + (f";{EDIT_PATH:#x},64={work / 'path.bin'}" if name in ("edit_save", "lp_save") or name in TRASHES else ""))
    args = [str(EMU), "--image", str(image), "--card", str(card), "--card-out", str(work / "out.img"), "--set", "OCTABAM", "--project", "SMPLV",
            "--load-ms", "90000", "--dsp", "--main-level", "64",
            *(["--audio-in", str(WAVS[name]), "--audio-in-from-boot"] if name in WAVS else ["--audio-in", "tones"]),
            "--watch-mem", f"{MAILBOX:#x},4;{LIMIT:#x},4;{LEN1:#x},4;{EDITOR:#x},4;{TRANSPORT:#x},4;{SAVE_TO:#x},4;{ED_SLOT:#x},4"
                           + (";0x460e6bcc,4" if name in LOCKS else "") + (f";{FILE_ROWS:#x},4" if name in TRASHES else "") + (";0x400ce734,4" if name == "dyn16" else ""),
            "--watch-pc", ",".join(["0x400069d6", "0x40005e8e"] + [hex(a) for a in TS_OUT]
                                   + ([hex(a) for a in (LOCK["sm_po_drop"], NORM_DONE, TOAST, CLEAR_DLG, DIALOG, 0x40000C42)]
                                      if name in LOCKS else [])
                                   + ([hex(TOAST)] if name in SILENTS or name.startswith(("lp_", "rl_")) else [])
                                   + (["0x4006f99e", "0x4008e43a", "0x4008e524"] if name == "pin_live" else [])
                                   + (["0x40077198", "0x4008e3d8"] if name == "live_long" else [])
), "--mem-dump", dump, "--live-script", str(work / "script"),
            *(["--block-dump", str(work / "blocks")] if name in MONS else [])]
    r = subprocess.run(args, cwd=ROOT, capture_output=True, text=True, timeout=3600 if name in ("long24", "live_long") else 1200)
    (work / "log").write_text(r.stdout + r.stderr)
    return name, r.returncode


def main():
    remix = sys.argv[1]
    if "SMPL" not in registry.remix(remix).modules:
        return 0
    if not EMU.is_file():
        print("  [SKIP] verify_smpl: no port (make emu-cf)")
        return 0
    if OUT.exists():
        shutil.rmtree(OUT)
    OUT.mkdir(parents=True)
    env = dict(os.environ, REMIX=remix, XBUS="1", SPEC="1")
    subprocess.run([sys.executable, "tools/build/build_bus.py"], cwd=ROOT, env=env,
                   stdout=subprocess.DEVNULL, check=True)
    image = OUT / "mainos.bin"
    shutil.copy2(ROOT / "out/mainos_bus.bin", image)
    project = OUT / "project"
    project.mkdir()
    (project / "project.work").write_text("[STATES]\nBANK=0\n\n")

    if "REC THRESHOLD" in registry.remix(remix).modules:
        TS_OUT.append(ts_out())
        for name, (script, quit_ms, wav) in THR_SCENARIOS.items():
            SCENARIOS[name] = (script, quit_ms)
            WAVS[name] = OUT / f"{name}.wav"
            write_wav(WAVS[name], *wav)

    LOCK.update(runtime_syms())
    for name, sc in lock_scenarios().items():
        SCENARIOS[name] = sc
        LOCKS.add(name)

    only = os.environ.get("SMPL_ONLY")   # a comma list of scenarios, for iterating on one
    if only:
        for n in [n for n in SCENARIOS if n not in only.split(",")]:
            del SCENARIOS[n]
    with ThreadPoolExecutor(max_workers=min(8, os.cpu_count() or 2)) as pool:
        codes = dict(pool.map(lambda n: run(n, image, project), SCENARIOS))

    fails = 0

    def check(ok, what):
        nonlocal fails
        print(f"  [{'PASS' if ok else 'FAIL'}] verify_smpl: {what}")
        fails += not ok

    for name in SCENARIOS:
        work = OUT / name
        log = (work / "log").read_text(errors="replace")
        clean = codes[name] == 0 and "ended on quit" in log
        mach, sig = (work / "mach.bin").read_bytes()[0], (work / "sig.bin").read_bytes()
        slot, rec = (work / "slot.bin").read_bytes()[0], (work / "rec.bin").read_bytes()
        words = [int(v, 0) for v in re.findall(r"\[0x46c7e9fa\] <- (\S+)", log)]
        limits = [int(v, 0) for v in re.findall(r"\[0x46c7fe24\] <- (\S+)", log)]
        arms = len(re.findall(r"at 0x400069d6 d0", log))
        ends = len(re.findall(r"at 0x40005e8e d0", log))
        lens = [int(v, 0) for v in re.findall(r"\[0x46c938d4\] <- (\S+)", log)]
        take = lens[-1] if lens else 0
        info = (f"mach={mach} sig={sig.hex()} slot={slot:#x} rec={rec.hex()} arms={arms} ends={ends} "
                f"take={take} words={[hex(w) for w in words if w]} limits={limits}")
        editor = [int(v, 0) for v in re.findall(rf"\[{EDITOR:#x}\] <- (\S+)", log)]
        out_img = work / "out.img"
        files = emu_card.extract_image(out_img.read_bytes()) if out_img.is_file() else {}
        wavs = sorted(k[len(AUDIO):] for k in files if k.startswith(AUDIO) and k.endswith(".wav"))
        ots = sorted(k[len(AUDIO):] for k in files if k.startswith(AUDIO) and k.endswith(".ot"))
        info += f" editor={[hex(e) for e in editor]} wavs={wavs}"

        def frames(n):
            w = files.get(AUDIO + n, b"")
            return (len(w) - 44) // 4 if len(w) > 44 else 0

        def peak(n):
            w = files.get(AUDIO + n, b"")
            d = w[w.find(b"data") + 8:] if b"data" in w else b""
            import struct as _st
            vals = _st.unpack(f"<{len(d) // 2}h", d[:len(d) // 2 * 2]) if d else ()
            return max((abs(x) for x in vals), default=0) / 32768

        def loud(n):
            w = files.get(AUDIO + n, b"")
            d = w[w.find(b"data") + 8:] if b"data" in w else b""
            return any(d[i:i + 2] not in (b"\0\0",) for i in range(0, len(d) - 1, 2))
        smpl_rec = rec[3] == 1 and rec[2] == 0 and rec[4] == 0
        if name == "win_smpl":
            check(clean and mach == 1 and sig == b"SM\x01" and slot == 0x80 and smpl_rec,
                  f"win_smpl: machine window -> SMPL: FLEX, signature, buffer 1, ONE2, RLEN 1 loop, SRC3 off ({info})")
        elif name in ("lp_win", "rl_src"):
            want = (b"LP\x01", smpl_rec) if name == "lp_win" else (
                b"RL\x01", rec[:2] == b"\0\0" and rec[3] == 1 and rec[4] == 9)
            check(clean and mach == 1 and sig == want[0] and slot == 0x80 and want[1],
                  f"{name}: {'machine window -> LOOPER' if name == 'lp_win' else 'SRC SETUP -> RELOOPER'} "
                  f"(row {7 if name == 'lp_win' else 8}): FLEX, signature, buffer 1, the recorder set as "
                  f"{'SAMPLER' if name == 'lp_win' else 'RESAMPLE'} ({info})")
        elif name.startswith(("lp_", "rl_")) and name not in MONS and name != "lp_save":
            ours = [f"{LOCK[k]:#x}" for k in ("sm_pbuf", "sm_s_saving", "sm_s_silent")]
            toasted = [ln for ln in log.splitlines() if f"at {TOAST:#x} " in ln
                       and any(o in ln.split("[sp")[1][:40] for o in ours)]   # stock's ARM ALL etc. aside
            if name == "lp_loop":
                ok = arms == 1 and ends == 1 and limits == [0, 88200]
                what = "a recorder trig takes one loop, 88,200 samples"
            else:
                ok = arms == 1 and ends == 1 and 40000 < take < 48000 and any(
                    w & 0x7000 == (0x1000 if name == "lp_take" else 0x4000) and w & 0x10 for w in words)
                what = f"A/B alone takes {'A/B' if name == 'lp_take' else 'the internal source'} for ~1 s"
            check(clean and ok and len([e for e in editor if e]) == 1 and not wavs and not files.get(AUDIO[:-1])
                  and not any(k.startswith(AUDIO) for k in files) and not toasted,
                  f"{name}: {what}; the editor opens; nothing scanned, normalized or saved (no AUDIO/SMPL, "
                  f"no PROCESSING / SAVING toast: {len(toasted)}) ({info})")
        elif name == "lp_save":
            others = sorted(k for k in files if k.endswith(".wav") and not k.startswith(AUDIO))
            path = (work / "path.bin").read_bytes().split(b"\0")[0].decode(errors="replace")
            check(clean and len(wavs) == 2 and wavs[0].endswith("-2.wav") and wavs[1] == wavs[0][:-6] + ".wav"
                  and not others and path == "../AUDIO/SMPL/" + wavs[0]
                  and all(40000 < frames(w) < 48000 for w in wavs) and 0.0 < peak(wavs[1]) < 0.6,
                  f"lp_save: a LOOPER take, not auto-saved, then FILE > SAVE AND ASSIGN twice, the prefilled name "
                  f"kept: AUDIO/SMPL/<name> then -2 (others={others}), not normalized (peak "
                  f"{peak(wavs[1]) if len(wavs) > 1 else 0:.3f}); the buffer assigned to {path} ({info})")
        elif name == "src_rsmp":
            check(clean and mach == 1 and sig == b"RS\x01" and slot == 0x80 and rec[:2] == b"\0\0"
                  and rec[2] == 0 and rec[3] == 1 and rec[4] == 9,   # SRC3 raw 9 = MAIN (1 = T1)
                  f"src_rsmp: SRC SETUP -> RSMP: inputs off, SRC3 MAIN, ONE2, RLEN 1 loop ({info})")
        elif name == "keep":
            check(clean and mach == 1 and sig == b"SM\x01" and slot == 0x80,
                  f"keep: YES in SMPL's slot list keeps SMPL ({info})")
        elif name == "to_flex":
            check(clean and mach == 1 and sig == b"\0\0\0",
                  f"to_flex: FLEX chosen in the machine column clears SMPL ({info})")
        elif name == "smpl_ab":
            check(clean and arms == 1 and ends == 1 and 40000 < take < 48000
                  and any(w & 0x7000 == 0x1000 and w & 0x10 for w in words),
                  f"smpl_ab: A/B alone starts and stops one A/B take of ~1 s ({info})")
        elif name == "rsmp_ab":
            check(clean and arms == 1 and ends == 1 and 40000 < take < 48000
                  and any(w & 0x7000 == 0x4000 and w & 0x10 for w in words)
                  and not any(w & 0x3000 for w in words),
                  f"rsmp_ab: A/B alone on RSMP takes the internal source only ({info})")
        elif name == "rsmp_smpl":
            w = files.get(AUDIO + wavs[0], b"") if wavs else b""
            d = w[w.find(b"data") + 8:] if b"data" in w else b""
            import struct as _st
            vals = set(_st.unpack(f"<{len(d) // 2}h", d[:len(d) // 2 * 2])) if d else set()
            check(clean and sig == b"SM\x01" and rec[:2] == b"\1\1" and rec[4] == 0 and arms == 1
                  and len(wavs) == 1 and len(vals) > 100,
                  f"rsmp_smpl: RSMP -> SMPL turns INAB / INCD back on; the A/B take holds audio "
                  f"({len(vals)} distinct values) ({info})")
        elif name in SILENTS:
            said = [ln for ln in log.splitlines() if f"at {TOAST:#x} " in ln
                    and f"{LOCK['sm_s_silent']:#x}" in ln.split("[sp")[1][:40]]
            def toasts(sym):
                return [ln for ln in log.splitlines() if f"at {TOAST:#x} " in ln
                        and f"{sym:#x}" in ln.split("[sp")[1][:40]]
            if name == "clear_one":
                cleared = toasts(0x400B373E)   # RECORDING CLEARED! (stock, 0x40021d16)
                check(clean and len(wavs) == 1 and lens and lens[-1] == 0 and cleared,
                      f"clear_one: one YES on a saved take's CLEAR SLOT empties it (length {lens[-1:]}, "
                      f"RECORDING CLEARED! {len(cleared)}) ({info})")
            elif name == "trash_none":
                rows = [int(v, 0) for v in re.findall(rf"\[{FILE_ROWS:#x}\] <- (\S+)", log)]
                check(clean and wavs == [] and rows and rows[-1] == 6,
                      f"trash_none: no take file: the FILE page has its stock six rows (rows {rows}) ({info})")
            elif name in TRASHES:
                rows = [int(v, 0) for v in re.findall(rf"\[{FILE_ROWS:#x}\] <- (\S+)", log)]
                trashed = toasts(LOCK["sm_s_trashed"])
                path = (work / "path.bin").read_bytes().split(b"\0")[0].decode(errors="replace")
                want = (["TRASH/R1-000000-0000-2.wav", "TRASH/R1-000000-0000.wav"] if name == "trash_two"
                        else ["TRASH/R1-000000-0000.wav"])
                n = len(want)
                want_ot = [w[:-4] + ".ot" for w in want]
                check(clean and wavs == want and ots == want_ot and lens and lens[-1] == 0 and path == "" and 7 in rows
                      and len(trashed) == n and all(40000 < frames(w) < 48000 for w in wavs),
                      f"{name}: FILE > TRASH TAKE, YES: the take and its .ot move to AUDIO/SMPL/TRASH "
                      f"(ots {ots}), the buffer "
                      f"is empty and untied (path {path!r}, length {lens[-1:]}), TAKE TRASHED! "
                      f"{len(trashed)}, rows {rows} ({info})")
            elif name == "proc":
                shown = toasts(LOCK["sm_pbuf"])
                last = (work / "pbuf.bin").read_bytes().split(b"\0")[0].decode(errors="replace")
                check(clean and len(wavs) == 1 and len(shown) >= 3 and not said
                      and re.fullmatch(r"SAVING TAKE \d{1,2}%", last) and 0.625 < peak(wavs[0]) < 0.635,
                      f"proc: PROCESSING / SAVING % shown {len(shown)} times on a 6 s take (last {last!r}), "
                      f"saved at peak {peak(wavs[0]) if wavs else 0:.3f} ({info})")
            elif name in ("save24", "long24"):
                def w24(n):
                    w = files.get(AUDIO + n, b"")
                    bits = int.from_bytes(w[34:36], "little") if len(w) > 36 else 0
                    d = w[w.find(b"data") + 8:] if b"data" in w else b""
                    n24 = len(d) // 3
                    p24 = max((abs(int.from_bytes(d[3 * i:3 * i + 3], "little", signed=True)) for i in range(n24)),
                              default=0) / 8388608
                    return bits, round(n24 / 2 / 44100, 2), round(p24, 4)
                got = [w24(n) for n in wavs]
                n_want, s_want = (2, (15.9, 16.1)) if name == "long24" else (1, (0.9, 1.1))
                check(clean and arms == n_want and len(wavs) == n_want and not said
                      and all(b == 24 and s_want[0] < s < s_want[1] and 0.625 < p < 0.635 for b, s, p in got),
                      f"{name}: 24-bit takes of the inputs, saved as (bits, s, peak) {got} "
                      f"(-4 dBFS = 0.631) ({info})")
            else:
                check(clean and arms == 1 and ends == 1 and not wavs and said,
                      f"{name}: a take of nothing (INAB / INCD \"-\"): NO SOUND IN TAKE, not saved "
                      f"(toasts {len(said)}) ({info})")
        elif name == "live_long":
            zooms = [int(z, 0) for z in re.findall(r"\] at 0x40077198 d0=(\S+) .* a2-6 0x400ce724 ", log)]
            steps = [int(m.split()[3], 0) for m in re.findall(r"\] at 0x4008e3d8 .*?\[sp \S+ ([^\]]+)\]", log)]
            top = zooms[-1] if zooms else 0   # zooms[0]: the fit as the take opens the editor, before it has a length
            check(clean and arms == 1 and 30000 < top < 36000 and zooms[1:] == sorted(zooms[1:])
                  and max(steps, default=0) > 20000,
                  f"live_long: a 60 s take fits the editor: zoom to fit reached {top} frames a pixel "
                  f"(stock caps 20,000 = 42.1 s), renderer step up to {max(steps, default=0)} ({info})")
        elif name == "dyn16":
            z = [int(v, 0) for v in re.findall(r"\[0x400ce734\] <- (\S+) \(4\)", log)]
            check(clean and arms == 1 and ends == 1 and z and z[0] > 131072 and len(wavs) == 1
                  and 1.8 < frames(wavs[0]) / 44100 < 2.2,
                  f"dyn16: a 16-bit DYNAMIC take: the editor's first zoom ({z[0] if z else 0}) is past 131,072, "
                  f"its overview bar divides by length >> 14 = 0 -- no EXCEPTION VEC:05 at 0x4006f458, the take "
                  f"runs and saves ({info})")
        elif name == "stock_ab":
            check(clean and arms == 0 and not any(words),
                  f"stock_ab: a stock track, quick mode off: A/B alone records nothing ({info})")
        elif name in ("loop1", "loop2"):
            n = 1 if name == "loop1" else 2
            check(clean and arms == 1 and ends == 1 and limits == [0, 88200 * n] and not wavs
                  and len([e for e in editor if e]) == 1,
                  f"{name}: LOOPER, a recorder trig takes {n} loop(s), 88,200 x {n} samples, as one take, "
                  f"not saved, the editor opened once ({info})")
        elif name == "smpl_trig":
            check(clean and arms == 0 and not wavs and not any(e for e in editor),
                  f"smpl_trig: SAMPLER, a recorder trig on step 1, PLAY: no take, no file (keys only) ({info})")
        elif name == "smpl_tap":
            check(clean and arms == 1 and ends == 1 and len(wavs) == 1 and 120000 < frames(wavs[0]) < 145000,
                  f"smpl_tap: SAMPLER with a recorder trig and a sample trig on step 1, playing: the red key "
                  f"taps in and out, one ~3 s take, saved ({info})")
        elif name in MONS:
            rb, exact = monitor_blocks(work / "blocks")
            fps = 44100 / 16

            def pk(a, b):
                return max((v for fr, v in rb.items() if a * fps <= fr < b * fps), default=-1)
            stock, empty, during, after = pk(6, 8.5), pk(10.2, 10.9), pk(11.3, 12.9), pk(14, 15)
            got = (f"T1 read-back peak: stock FLEX {stock}, empty SMPL {empty}, recording {during}, "
                   f"with its take {after}; exact frames {exact}")
            if name == "monitor":
                check(clean and arms == 1 and len(wavs) == 1 and loud(wavs[0]) and stock == 0
                      and empty > 500 and during > 500 and after < 4 and exact > 1000,
                      f"monitor: an empty SAMPLER and a SAMPLER take are heard through T1, "
                      f"a SAMPLER with a take is not; the take saved ({got}) ({info})")
            elif name == "mon_stop":
                held, rec, took = pk(10.8, 12.4), pk(12.7, 13.2), pk(14, 15)
                check(clean and arms == 1 and len(wavs) == 1 and held > 500 and rec > 500 and took < 4,
                      f"mon_stop: after PLAY, STOP, STOP the empty SAMPLER is still heard (its envelope "
                      f"reopened: T1 read-back peak {held}), and while it records ({rec}); not with its take "
                      f"({took}) ({info})")
            elif name == "lp_mon":
                check(clean and arms == 1 and not wavs and empty > 500 and during > 500 and after < 4,
                      f"lp_mon: an empty LOOPER is heard through T1 and while it records, not with its take; "
                      f"nothing saved ({got}) ({info})")
            elif name == "mon_rsmp":
                check(clean and arms == 1 and empty == 0 and during == 0,
                      f"mon_rsmp: RESAMPLE does not monitor ({got}) ({info})")
            else:
                idle, armed = pk(12.8, 13.9), pk(14.5, 16.5)
                check(clean and arms == 1 and len(wavs) == 1 and idle < 4 and armed > 8,
                      f"mon_armed: with a take, silent until armed; armed (threshold not reached) "
                      f"monitors (T1 read-back peak idle {idle}, armed {armed}) ({info})")
            (work / "blocks").unlink()
        elif name == "save":
            check(clean and len(editor) == 1 and editor[0] != 0 and wavs == ["R1-000000-0000.wav"]
                  and ots == ["R1-000000-0000.ot"] and 40000 < frames(wavs[0]) < 48000 and loud(wavs[0])
                  and 0.625 < peak(wavs[0]) < 0.635,
                  f"save: a take opens the editor (still open), is normalized to -4 dBFS (peak {peak(wavs[0]) if wavs else 0:.3f}) "
                  f"and is saved as R1-000000-0000 ({info})")
        elif name == "save_no":
            check(clean and len(editor) == 2 and editor[0] != 0 and editor[1] == 0
                  and wavs == ["R1-000000-0000.wav"],
                  f"save_no: NO closes the editor; the take is saved ({info})")
        elif name == "save_two":
            check(clean and wavs == ["R1-000000-0000-2.wav", "R1-000000-0000.wav"]
                  and all(40000 < frames(w) < 48000 for w in wavs),
                  f"save_two: two takes, two files, the second -2 ({info})")
        elif name == "edit_save":
            others = sorted(k for k in files if k.endswith(".wav") and not k.startswith(AUDIO))
            path = (work / "path.bin").read_bytes().split(b"\0")[0].decode(errors="replace")
            check(clean and wavs == ["R1-000000-0000-2.wav", "R1-000000-0000-3.wav", "R1-000000-0000.wav"]
                  and not others and path == "../AUDIO/SMPL/R1-000000-0000-3.wav"
                  and all(40000 < frames(w) < 48000 for w in wavs),
                  f"edit_save: an edited take saves next to it as -2, then -3, never over it, in the pool root "
                  f"or the project (others={others}); the buffer is assigned to {path} ({info})")
        elif name == "save_proj":
            others = sorted(k for k in files if k.endswith(".wav") and not k.startswith(AUDIO))
            st = [int(v, 0) for v in re.findall(r"\[0x800000a4\] <- (\S+) \(4\)", log)]
            restored = len(st) >= 2 and st[-2] == 0 and st[-1] != 0   # held at AUD POOL, then the user's back
            check(clean and wavs == ["R1-000000-0000.wav"] and not others and restored,
                  f"save_proj: SAVE SAMPLES TO = PROJ DIR: the take still goes to AUDIO/SMPL "
                  f"(others={others}), SAVE SAMPLES TO held then restored ({[hex(x) for x in st]}) ({info})")
        elif name in ("play_stop", "play_track"):
            tr = [int(v, 0) for v in re.findall(r"\[0x800065b8\] <- (\S+)", log)]
            stopped = 1 in tr and tr[-1] != 1
            check(clean and stopped and arms == 1 and wavs == ["R1-000000-0000.wav"],
                  f"{name}: a key take while playing is saved, "
                  f"{'a TRACK key arms nothing, ' if name == 'play_track' else ''}and STOP then stops "
                  f"the sequencer (transport {tr}) ({info})")
        elif name == "pin":
            # TRACK 2 at 12 s (recording): the editor stays on buffer 1 (0x80); STOP from TRACK 2 at
            # 14 s; TRACK 1 at 22 s. The editor's slot never leaves 0x80 while the take runs.
            slots = [int(v, 0) for v in re.findall(r"\[0x46c8d19c\] <- (\S+)", log)]
            after_open = slots[slots.index(0x80):] if 0x80 in slots else []
            check(clean and arms == 1 and ends == 1 and after_open and all(x == 0x80 for x in after_open)
                  and wavs == ["R1-000000-0000.wav"],
                  f"pin: TRACK 2 mid-take leaves the editor on the take (slots after open {[hex(x) for x in after_open]}), "
                  f"the take is stopped and saved ({info})")
        elif name == "pin_free":
            slots = [int(v, 0) for v in re.findall(r"\[0x46c8d19c\] <- (\S+)", log)]
            check(clean and wavs == ["R1-000000-0000.wav"] and slots and slots[-1] == 1 and 0x80 in slots,
                  f"pin_free: after the take (saved), TRACK 2 moves the editor on as stock "
                  f"(slots {[hex(x) for x in slots[-3:]]}) ({info})")
        elif name == "pin_live":
            def at(pc):
                return [int(m.group(1)) for m in re.finditer(rf"\[\s*(\d+)\] at {pc} ", log)]
            start, end = (at("0x400069d6") or [0])[0], (at("0x40005e8e") or [0])[0]
            drawn = [int(m.group(2), 0) for m in re.finditer(r"\[\s*(\d+)\] at 0x4006f99e d0=(\S+)", log)
                     if start < int(m.group(1)) < end]
            render = [int(m.group(2), 0) for m in re.finditer(r"\[\s*(\d+)\] at 0x4008e(?:43a|524) d0=(\S+)", log)
                      if start < int(m.group(1)) < end]
            check(clean and len(drawn) > 60 and 0 not in drawn and drawn == sorted(drawn)
                  and len(render) > 1000 and 0 not in render,
                  f"pin_live: TRACK 2 mid-take, the editor keeps drawing the take as it grows "
                  f"({len(drawn)} draws, zeros {drawn.count(0)}, {hex(drawn[0]) if drawn else 0} -> "
                  f"{hex(drawn[-1]) if drawn else 0}; renderer {len(render)} reads, zeros {render.count(0)}"
                  f") ({info})")
        elif name in ("reopen", "reopen_free"):
            slots = [int(v, 0) for v in re.findall(rf"\[{ED_SLOT:#x}\] <- (\S+)", log)]
            want = 0x80 if name == "reopen" else 0x1
            closed = 0 in editor[1:]
            check(clean and closed and editor and editor[-1] != 0 and slots and slots[-1] == want,
                  f"{name}: NO, TRACK 2, TRACK 2 + BANK: the editor opens on "
                  f"{'the take still recording' if name == 'reopen' else 'TRACK 2 once the take is done'} "
                  f"(slot {hex(slots[-1]) if slots else None}) ({info} slots={[hex(x) for x in slots]})")
        elif name == "stop_t2":
            check(clean and arms == 1 and ends == 1 and 80000 < take < 96000 and wavs == ["R1-000000-0000.wav"],
                  f"stop_t2: the red key stops a take from another track (2 s, {take}) ({info})")
        elif name in ("thr_quiet", "rsmp_quiet", "rsmp_late"):
            blocks = set(re.findall(rf"at {TS_OUT[0]:#x} .*?a1=(\S+)", log)) if TS_OUT else set()
            want = {"thr_quiet": set(), "rsmp_quiet": {"0x80003210", "0x80003610"}, "rsmp_late": {"0x80005e60"}}[name]
            what = {"thr_quiet": "silence", "rsmp_quiet": "loud inputs, a silent source (T2)",
                    "rsmp_late": "source MAIN (silent under the port)"}[name]
            check(clean and arms == 0 and not wavs and rec[3] == 3 and blocks - {"0"} == want,
                  f"{name}: TRIG THR, the red key arms; {what} starts no take; blocks measured {sorted(blocks)} ({info})")
        elif name == "thr_late":
            check(clean and arms == 1 and ends == 1 and len(wavs) == 1 and rec[3] == 3,
                  f"{name}: TRIG THR, armed in silence: the sine starts one take, the red key ends it, saved ({info})")
        elif name in LOCKS:
            def hits(a):
                return [ln for ln in log.splitlines() if f"at {a:#x} " in ln]
            saving = [ln for ln in hits(TOAST) if f"{LOCK['sm_s_saving']:#x}" in ln.split("[sp")[1][:40]]
            drops, done = hits(LOCK["sm_po_drop"]), hits(NORM_DONE)
            norm_posted = [ln for ln in hits(0x40000C42) if f"{NORM_MSG:#x}" in ln.split("[sp")[1][:60]]
            busy = [int(v, 0) for v in re.findall(r"\[0x460e6bcc\] <- (\S+)", log)]
            dlg = [ln for ln in hits(DIALOG) if "0x40021c76" in ln.split("[sp")[1][:30]]   # CLEAR SLOT's
            facts = (f"drops={len(drops)} posted={len(norm_posted)} done={len(done)} saving={len(saving)} "
                     f"busy={busy[-3:]} dialog={len(dlg)} clear_dlg={len(hits(CLEAR_DLG))}")
            if name == "lock_edit":
                check(clean and drops and not norm_posted and done and saving and busy and busy[-1] == 0,
                      f"lock_edit: NORMALIZE on a saving take is not posted, its callback runs, SAVING TAKE.. ({facts})")
            elif name == "edit_free":
                check(clean and norm_posted and not drops and not saving,
                      f"edit_free: no save in flight: NORMALIZE is posted as stock ({facts})")
            elif name == "lock_take":
                check(clean and arms == 1 and saving and wavs == ["R1-000000-0000.wav"],
                      f"lock_take: the red key on a saving take's track starts no take, SAVING TAKE.. ({facts}) ({info})")
            elif name == "lock_clear":
                check(clean and hits(CLEAR_DLG) and not dlg and saving,
                      f"lock_clear: CLEAR SLOT on a saving take opens no dialog, SAVING TAKE.. ({facts})")
            elif name == "clear_free":
                check(clean and hits(CLEAR_DLG) and dlg and not saving,
                      f"clear_free: no save in flight: CLEAR SLOT's dialog opens as stock ({facts})")
        elif name == "loopmax":
            check(clean and arms == 1 and ends == 1 and not wavs and limits and limits[-1] > 3 * 88200,
                  f"loopmax: LOOPER, RLEN MAX: one take until STOP, not saved ({info})")
        elif name == "again":
            check(clean and arms == 2 and ends == 2 and not wavs and limits[-1:] == [88200],
                  f"again: LOOPER, STOP then PLAY records the loop again ({info})")
    return int(bool(fails))


if __name__ == "__main__":
    sys.exit(main())
