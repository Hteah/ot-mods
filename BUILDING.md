# How these machines were built

These notes cover how SAMPLER, RESAMPLE, LOOPER and RELOOPER were made, so you
or your AI coding agent can rebuild them, change them, or use the same method
for a different machine. They were built between 23 Oct and 11 Nov 2026. Hteah
designed them and tested them on his MKI, and Claude (Anthropic's coding agent,
in Claude Code) wrote and verified the code. It took about 30 flashed test
images (ACCLOOP2 … ACCLOOP32).

If you only want to *use* the machines, run `./install.sh` (see README).

---

## 1. The ground rules that made it possible

1. **Build on octabam, not from scratch.** [octabam](https://github.com/sambanks/octabam)
   already handles the hard parts: unpacking Elektron's 1.40C, a linker for
   ColdFire assembly units that run from DRAM, *detours* (patch a stock
   instruction to jump into your code, then return), a conflict checker
   between modules, an image packer, and **a port**: an emulator of the
   Octatrack's ColdFire CPU and DSP that boots the real OS with an MKI or MKII
   panel, presses keys, decodes the LCD and watches memory. Every claim here
   was first checked under that port.
2. **Never ship Elektron bytes.** The repo contains only your code and the
   addresses it hooks. The build reads the user's own 1.40C download. Never
   put a built image, a `.syx` or a dump in git or in an issue.
3. **Measure, don't guess.** A static read of the disassembly tells you what a
   routine *can* do. A write-watch under the port tells you what the running
   firmware *does*. This went wrong once on a sibling project: a static read
   named the wrong RAM word as the sequencer position and a whole design was
   thrown away. Before you build on a RAM word, watch who writes it.
4. **A gate for every behaviour.** `tools/verify/verify_smpl.py` drives the
   port like a person (choose the machine, press keys, run the sequencer) and
   asserts on memory, recorder words and files written to the emulated card.
   `make check REMIX=<name>` runs the build plus every gate. Nothing went to
   hardware without passing it.
5. **Hardware is the final test, and the person using it reports what they
   saw.** The port can't hear sound and doesn't model everything. Each flash
   had a short list of "please check X, Y, Z". The most useful bug reports
   were plain descriptions ("nothing starts while playing", "the waveform
   stops growing at about 42 s"), followed by a cheap controlled comparison
   ("does it happen with the sample trig too?").
6. **One user goal decided the design.** Hteah's brief was: *remove the
   settings I have to remember.* Any feature that added a setting was
   rejected or made automatic.

## 2. Tools

- macOS (Linux/WSL2 also work): Homebrew `m68k-elf-gcc`, `binwalk`, `radare2`,
  `cmake`, `uv`, then octabam's `make setup`, `make os`, `make recon`,
  `make emu-setup`, `make emu-cf`. `install.sh` does the build half of this.
- Work in a **git worktree** of octabam (`git worktree add …`). Several
  sessions can share a checkout. `vendor/` and `.venv/` can be symlinks to the
  main checkout. `out/raw/section_3_MAIN_OS.bin` must exist in the worktree.
  Build the port into the worktree (`make emu-cf`) and don't symlink `out/emu`.
- Read octabam's `AGENTS.md`, `docs/contributing/MODULES.md` and
  `docs/contributing/TRAPS.md` first. TRAPS.md is the list of mistakes that
  have already cost people days.

## 3. Architecture

Everything is one octabam **ColdFire module** (`modules/smpl`, kind
`CF_PATCH`): a GNU-as unit (`machine.s`, ~3,200 lines) linked into DRAM, plus
~40 detours declared in `manifest.py`. It never touches the DSP: playback is
the stock Flex engine.

**The core idea:** an Octatrack track with a Flex machine whose slot points at
its *own* recorder buffer (`0x80 + track`) already *is* a sampler. Stock just
makes you set that up by hand every time. A "machine" here is that setup plus
a marker, and the hooks then change how the record keys and recorder trigs
behave on tracks that carry the marker.

### 3.1 New rows in the machine list

- The stock list was written for five machines. Its row counts, bounds,
  clamps, highlight, name table, SRC SETUP rows and commit paths are detoured
  so it shows more. This code is **Tim Hastie's v2.15 `machine.s`** (MIT), as
  carried by octabam's CX OSC module. Reuse it, don't rewrite it. The
  descriptor table's two spare slots (5, 6) hold the extra rows' pages
  (Flex's page).
- **Choosing a row** makes the track FLEX (machine byte 1), writes a
  signature into the NEIGHBOR PLAYBACK column's first three bytes
  (`Part + 0x8edbc + 30·t`: `SM`,1 / `RS`,1 / looper kinds), points the FLEX
  slot (`Part + 0x8f04b + 5·t`) at recorder buffer `0x80 + t`, and writes the
  recorder setup (`Part + 0x8f382 + 12·t`): TRIG `ONE2`, RLEN 1, and the
  sources (INAB/INCD A B / C D for the input machines; SRC3 = raw 9 = MAIN
  for the internal ones. SRC3's raw order is `-, T1..T8, MAIN, CUE`, and an
  early build wrote raw 1 = T1 by mistake). Write both the Part and its
  battery-RAM shadow.
- **Choosing a stock machine** clears the signature. The track is then stock
  in every respect.

### 3.2 One key to record

The record keys set flags at `0x460d10d0` (A/B), `…10d4` (C/D), `…10d8`
(internal) and call the manual-sampling routine `0x400836d8`, which walks the
tracks:

| site | stock | with these machines |
|---|---|---|
| `0x40083756` | RECORD QUICK MODE: current track counts as held | also when the current track is one of ours |
| `0x40030f2e` / `0x40030d4c` | A/B / C/D press sets its flag | on RESAMPLE/RELOOPER: the internal flag instead |
| `0x40030f08` / `0x40030cfc` | release clears its flag | clears what the press set |

Stop is the stock `ONE2` behaviour (press again). It cost nothing.
SAMPLER/RESAMPLE ignore recorder trigs (red key only). LOOPER/RELOOPER take
both.

### 3.3 Trig takes as N loops (LOOPER / RELOOPER)

Stock re-arms the recorder at *every* recorder trig, recording each pass over
the last, and the engine re-reads RLEN while recording. So:

- The per-frame publish of the recorder setup (the memcpy at `0x4000cae2`)
  gets RLEN = MAX for our tracks (`sm_pub`).
- The recorder dispatcher's arm call (`0x4000d356`, `sm_disp`) sorts recorder
  words. The first trig start is armed. The following ones are counted and
  swallowed. The one ending loop N is sent on as a stop word (`0x80` + its
  sub-frame nibble), so the take ends on the loop point to the sample.
- One take per run, until the transport (`0x800065b8`) stops.

### 3.4 The editor follows the take

- At the recorder's take start (`0x400069e4`, the same site octabam's BUFFER
  SAVER uses), the UI tick opens the audio editor on the buffer with stock's
  own pair `0x4006de34(FLEX, 0x80+t)` + `0x4006e160`.
- `0x4006de34` (editor re-point) and `0x4006e160` (window open) are detoured
  so the editor stays on a take that's still recording, from any track, until
  the user's own track select.
- Stock's "how much of this buffer is recorded" (`0x40005f54`) reads the
  *current* track's recorder, so on another track the live waveform was
  blank. `sm_recpos` (`0x40005f66`) reads the buffer's own recorder.
- Long takes needed the editor's zoom cap raised (20,000 → 600,000 frames per
  pixel on a recording) and a divide-by-zero in the overview bar fixed past
  131,072 frames/pixel.

### 3.5 Processing and saving (SAMPLER / RESAMPLE)

When the recorder goes idle (`0x40004268`), with the keys released:

1. **Scan** the take through the save's own block walk (`0x4009499c`), 8
   blocks per UI tick. If no sample is above -72 dBFS, show NO SOUND IN TAKE
   and stop there (no normalize, no file). This was added after an empty
   take was normalized into a full-scale block of hiss.
2. **Normalize** with a single in-place gain pass to a -4 dBFS peak (our own
   loop. Stock's NORMALIZE is ~2,170 instructions per frame of soft-float,
   which is far too slow for minutes of audio). PROCESSING TAKE.. nn% shows
   while it runs.
3. **Save** through BUFFER SAVER's chain: FLEX object `128+n`, mode 2, the
   naming keyboard's confirm `0x40024288(1)`. The name is stock's
   `R<n>-YYMMDD-HHMM`, with `-2`, `-3` … if it's taken, never an overwrite.
   Files go in the set's `AUDIO/SMPL` (the first take creates the folder).
   PERSONALIZE > SAVE SAMPLES TO is held at AUD POOL from the save call until
   the done callback, because the slot's path is built from it after the
   write.
4. **Save lock** from stop until the file is written: editor operations,
   CLEAR SLOT and a new take on that buffer are refused with SAVING TAKE..
   (via the queue post `0x40000c3c` and CLEAR SLOT `0x40021bc8 / d0a / d66`).
5. **No time-based give-ups.** Early builds abandoned a save after 3,000 UI
   ticks (~50 s). On the hardware, long takes then got "FILE NOT FOUND" on
   reload. The file was fine, but the path had been restored mid-write.
   Wait for the real done callbacks.

LOOPER/RELOOPER skip all of 3.5: the take stays in RAM and plays at once. The
editor's FILE > SAVE AND ASSIGN writes it to `AUDIO/SMPL` with the name filled
in. Stock's three "pool or project" tests (`0x400242d2`, `0x400241a6`,
`0x40023f82`) take the pool path for any name starting `SMPL/`.

### 3.6 Monitoring through the track

An empty, armed or recording SAMPLER plays its input through its own AMP / FX1
/ FX2: the voice loop's renderer is swapped for a THRU-style mix (`sm_mon`).
The track is only heard while its AMP envelope (on the DSP) is open, and on
hardware it stayed shut until a trig. The port's boot state had left it open,
so the first version passed every gate and was silent on the MKI. `sm_envgate`
(`0x4000d0a4`, every frame) now takes a monitoring track out of the stop mask
and trigs it once.

### 3.7 Small extras

- TRASH TAKE: a 7th row on the editor's FILE page moves a take and its `.ot`
  to `AUDIO/SMPL/TRASH` (the browser's MOVE FILE), then clears the buffer.
- One-step clear: on our buffers CLEAR SLOT's disassociate is followed by the
  clear, so a saved take doesn't need two YESes.
- Threshold takes with REC THRESHOLD: RESAMPLE measures its own SRC3 block
  (track read-back, MAIN or CUE), not the inputs. REC THRESHOLD's `src_peak`
  calls `sm_thr_src` via a weak reference, so REC THRESHOLD without SMPL
  behaves as before.
- Choosing SAMPLER turns INAB/INCD back to A B / C D if a previous RESAMPLE
  left them at `-`.

All addresses are **OS 1.40C, MKI**. octabam's build refuses to link if the
stock bytes at a detour site don't match what the manifest pins.

## 4. Testing

- `make check REMIX=samplers`: full build, cycle budgets, every gate, boot.
- `verify_smpl.py` scenarios include: machine chosen from the list and from
  SRC SETUP; key takes A/B, C/D and internal; stock tracks unchanged; trig
  takes at RLEN 1 / 2 / MAX (exact sample counts, e.g. 88,200 = 16 steps at
  120 BPM); one file per take; `-2`/`-3` naming; SAVE SAMPLES TO poked to
  PROJ DIR still lands in AUDIO/SMPL; 16- and 24-bit saves; silent takes;
  save lock; monitoring + envelope; trash; one-step clear; threshold takes.
- Under the port the audio capture is silent and MAIN is silent. Sound,
  reload after power-off, and full-card behaviour are for the hardware.

### What only the hardware found

| symptom on the MKI | cause | fix |
|---|---|---|
| takes "FILE NOT FOUND" after reload | path rebuilt from SAVE SAMPLES TO after it was restored | hold it until the done callback |
| long take saved without -1 dB gain / wrong path | 3,000-tick give-up | no timeouts; wait for callbacks |
| live waveform stops at ~42 s | editor zoom cap | raised cap, overview divide fix |
| SAMPLER silent while monitoring | AMP envelope closed (port booted it open) | `sm_envgate` |
| empty take normalized into hiss | INAB `-` left by RESAMPLE | silence scan + reset INAB/INCD |
| "nothing records while playing" | user's QREC/QPL on with master length INF | not a bug: documented |
| RELOOPER layer-on-layer | SRC3 MAIN + its own trig = feedback | documented: use CUE/one track |
| a 24-bit save off by a few dB in the port | port bug: access straddling two memory regions | port fixed (`Machine::straddles`) + gate |

## 5. Rebuilding this with your own agent

Give your agent this repo, octabam, and something like:

> Clone octabam at the commit in `OCTABAM_COMMIT` into a git worktree. Read its
> AGENTS.md, docs/contributing/MODULES.md and TRAPS.md. Copy `overlay/` on top
> and run `make check REMIX=samplers` until it passes. Then read
> `overlay/modules/smpl/README.md` and `BUILDING.md` and explain the design
> back to me before changing anything. For any change: write a gate in
> `tools/verify/verify_smpl.py` first, prove it fails on the old code, then make
> it pass. Never commit Elektron bytes. Give me a short list of hardware checks
> with every image.

To make a **new** machine in the same style, follow the same order: the
machine-list rows (§3.1, reuse Tim Hastie's code), then a marker in the Part,
then hooks on the stock path you want to change. For each hook: find the site
by static read, confirm it with a write-watch or breakpoint under the port,
detour it, and gate it.

**Flash safely:** bump the version every image (`make image … BUILD=n
VERSION=NAMEn`). Copy the `.bin` to the card root, `shasum` it on the card,
eject, then PROJECT > SYSTEM > OS UPGRADE. If the first try doesn't take,
power-cycle and run it again. Recovery: FUNC at power-on > MIDI UPGRADE with
the stock `.syx` over DIN MIDI.

## 6. Moving to a newer octabam

`OCTABAM_COMMIT` pins the octabam these files were built against. To move
forward: check out a newer octabam in a worktree, copy the overlay, and run
`make check REMIX=samplers`. Then:

- Expect conflicts in `modules/rec-threshold/thresh.s`, because the overlay
  replaces the whole file. Re-apply the `sm_thr_src` weak-reference hook onto
  upstream's version rather than overwriting it.
- `tools/emu/ot_emu/machine.{cpp,h}` carry the straddling-access port fix
  (`Machine::straddles`), which the 24-bit gates need.
- If `tools/remix/selftest.py` complains about DSP words for `smpl` /
  `samplers`, add them to its "ColdFire, no DSP words" list.
