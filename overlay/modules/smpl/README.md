# `smpl` — SMPL

Author: [Hteah](https://github.com/Hteah). Machine-list code: Tim Hastie
(MIT), as CX OSC carries it; see [`NOTICE`](NOTICE).

Two sampler machines, **SMPL** and **RSMP**, below PICKUP in the machine
list. Each is a track that records into its own recorder buffer and plays it
back as a normal Flex sample: nothing to load, no key combo.

- **SMPL** records the inputs: the A/B key records inputs A/B, the C/D key
  inputs C/D.
- **RSMP** records the internal sound: the recorder's SRC3 source (MAIN, CUE
  or a track; MAIN when it was `-`, raw 9 -- SRC3's raw order is `-, T1..T8,
  MAIN, CUE`; ACCLOOP2-4 wrote raw 1, which is T1), on RECORDING SETUP 1. Either record key
  records it.
- **One button.** On an SMPL or RSMP track, press the red record key alone
  to start, and again to stop, with or without RECORD QUICK MODE. Other
  tracks are stock.
- **A key take is free length**, whatever RLEN says. With QREC set, it
  starts and stops on QREC's grid (stock ONE2 + QREC).
- **A recorder-trig take is RLEN loops of the track, as one take.** On these
  tracks RLEN counts loops, not steps: RLEN 1 (the default) is one loop of
  the track on its own length and scale, RLEN 2 two loops, up to 64; MAX
  records until STOP. One take, one file: the recorder runs straight through
  the loop points and stops at the trig that ends the last loop, to the
  sample. After it, that track's recorder trigs are ignored while the
  pattern plays on, so nothing records over the take; STOP and PLAY again
  to record another. E.g. 128 steps on a 64-step track: RLEN 2.
- It plays on your own trigs with the stock Flex PLAYBACK page: sequenced,
  p-locked, sliced like any Flex sample. The machine list's slot list on an
  SMPL track shows the recorder buffers, titled `MACHINE:SMPL`.

- **The editor opens when a take starts.** The audio editor opens on the
  track's buffer and draws the take as it records (stock's editor does
  that). It stays open after the take; NO closes it, as stock.
- **The editor stays on the take.** Once SMPL opens the editor on a take,
  a track change (or any other re-point of the editor, `0x4006de34`) leaves
  it there while the take records and after it, until the user's own track
  select (`0x40083ca6`); the save's refresh after a take (`0x40077ad4`)
  does not move it. Editor closed: stock.
- **The editor reopens on the take.** While a take records, opening the
  editor (FUNC + BANK, TRACK + BANK, any path: the window's open
  `0x4006e160`, `sm_edwin`) points it at the take's buffer first and pins it,
  from any track, however often NO closes it. Once the take has stopped:
  stock. (27 Oct 2026: the pin held only while the editor stayed open.)
- **The red key stops a take from any track.** While a take records, the
  red key alone stops it whatever track is current (and starts nothing
  else); before, from another track the take ran to the memory limit.
- **A silent take is not kept.** Before the normalize the take is scanned,
  8 blocks a UI tick through the save's own walk (`0x4009499c`), for any
  sample past 8 of 32768 (-72 dBFS; 24-bit: its top 16 bits). None: NO
  SOUND IN TAKE, no normalize, no save (Heath, 1 Nov 2026: an RSMP track's
  INAB "-" survived into SMPL, the take was empty, normalize made it a
  full-scale block of hiss). Choosing SMPL now also turns INAB / INCD to A B
  / C D when they are "-". Gates `silent`, `silent24`, `save24`, `rsmp_smpl`.
- **PROCESSING TAKE..** shows while a take is scanned, normalized or gained
  (sm_nstate 5, 1, 3, 4), again every 40 UI ticks (Heath, 1 Nov 2026). Gate
  `proc`.
- **One-step clear.** A saved take is tied to its file, so stock's CLEAR
  SLOT first only disassociates it (`0x40021d66` -> `0x40025188`). On an
  SMPL / RSMP track's own buffer the untie is followed by CLEAR RECORDING's
  clear (`0x4002557c`) and its RECORDING CLEARED! tail (`0x40021d12`).
  Gate `clear_one` (fails on the previous code: length unchanged).
- **Monitoring through the track (ACCLOOP28, envelope fix ACCLOOP30).** An
  empty SAMPLER, and one whose recorder is armed (REC THRESHOLD waiting too)
  or recording, plays its inputs through its own AMP / FX1 / FX2
  (`sm_mcall1` / `sm_mcall2` swap the voice loop's renderer for `sm_mon`,
  THRU's mix); the take stays dry. A track is heard only while its AMP
  envelope (on the DSP) is open: a trig opens it (trig byte `0x80004858 +
  8t` bit 1 -> DSP record `+60` bit 7, `0x40004bd4`), a STOP closes it (stop
  mask `0x8000184a`: HOLD 0, REL <= 24, `0x4000d0ba`). ACCLOOP28 relied on
  the port's boot state, which leaves it open; Heath's MKI stayed silent
  until a trig + PLAY (7 Nov 2026). `sm_envgate` (`0x4000d0a4`, every frame
  before the stop mask) takes a monitoring track out of the stop mask,
  holds it (HOLD 127 in its record) and trigs it once when it starts to
  monitor and again after a stop. Gates `monitor`, `mon_rsmp`, `mon_armed`,
  `mon_stop` (silent on ACCLOOP29).
- **TRASH TAKE.** The editor's FILE page on an SMPL / RSMP track's own
  buffer, tied to a file in a SMPL folder, has a seventh row (Heath, 7 Nov
  2026: a bad take goes without giving up the auto-save). YES in its dialog
  moves the take and its `.ot` to `<set>/AUDIO/SMPL/TRASH` (made the first
  time; FS slot `0x46c82446`, the browser's MOVE FILE), `-2` .. `-99` on a
  name already there, then unties and clears the buffer (CLEAR SLOT's two
  confirms) with TAKE TRASHED!. A failed move clears nothing. The page's
  table `0x400b2d92` is read from `sm_ft_table` (draw `0x40076a30`, dispatch
  `0x40076efc`); its list init (`0x40076dfc`) counts 7 only for such a take.
  Gates `trash`, `trash_two` (a retake has the trashed take's name),
  `trash_none` (no file: the stock six rows).
- **Every take is normalized.** When a take ends SMPL scans it for its
  peak, then runs the editor's gain operation (`0x40095560`, unity 2048)
  once over the whole take with gain floor(1292 x full scale / peak):
  every take peaks at -4 dBFS (-1 dBFS to ACCLOOP21; Heath asked for 3 dB
  more headroom, 1 Nov 2026). The save waits for it. Button and trig takes.
- **Every take is saved.** When the recorder goes idle after a take, the
  record keys are up (a save started with one down took its release: STOP
  then never stopped) and the normalize is done, the take is written to the
  card as a new file, stock's name `R<n>-YYMMDD-HHMM` (n = the buffer),
  `-2`, `-3` … when taken, never an overwrite, into the set's `AUDIO/SMPL`
  folder (made by the first take when missing). PERSONALIZE > SAVE SAMPLES
  TO is held at AUD POOL from the save call until the save's done callback,
  which comes after the assignment -- the assignment builds the slot's path
  from it too, and on a real card it runs after the write (restored earlier,
  PROJ DIR stored `PATH=SMPL/...`, FILE NOT FOUND on reload; 25 Oct 2026).
  The buffer is assigned to the file, so a project save points at it
  (`../AUDIO/SMPL/...`). Saves run while the pattern plays.
- **An edited take saves next to it.** The editor's FILE > SAVE SAMPLE COPY
  / SAVE AND ASSIGN SAMPLE on a take (a FLEX slot or buffer whose file is in
  `AUDIO/SMPL`) writes `AUDIO/SMPL/<name>-2` (`-3` … while taken) -- never
  over the original, the pool root or the project; an edit of the `-2` drops
  its ending and becomes the next free one (Heath, 2 Nov 2026). Stock's three
  pool-or-project tests (the confirm 0x400242d2, the save 0x400241a6, the
  assignment 0x40023f82) take the pool's path for any name starting `SMPL/`.

Choosing SMPL or RSMP sets the track's recorder to TRIG `ONE2` (press again to
stop) and RLEN `1` (one loop). SMPL turns SRC3 off; RSMP turns INAB and INCD off. A
recorder trig samples every source the recorder has, so each machine keeps
only its own. Choosing a stock machine leaves these settings as they are.

**Live waveform on any track.** While a take records, the editor stays on it
when you change track and keeps drawing it as it grows. Stock's "how much
of this recording buffer is recorded" (`0x40005f54(buffer)`) reads the
*current* track's recorder, so on another track the waveform renderer and
the editor's zoom were told 0 and the take only appeared when it stopped.
It now reads the buffer's own recorder (`sm_recpos`, `0x40005f66`) -- the
same recorder as stock whenever the current track records its own buffer.

**Save lock.** From the moment a take stops until its file is written, its
buffer is locked: the audio editor's edits on it (crop, delete, reverse,
fades, normalize, gain, silence, paste, mix / invert, slice reverse /
normalize, CROP SAMPLE), CLEAR SLOT's dialog (CLEAR RECORDING / DISASSOCIATE)
and a new take on that track are refused with **SAVING TAKE..**. Looking,
zooming and moving around still work. A refused edit closes as if it had
run (its own done callback), unchanged. Why: a take saved as a full-length
silent file on Heath's MKI (27 Oct 2026), likely the buffer cleared in the
editor during the save -- his account, not reproduced. Opening CLEAR SLOT's
dialog also rewrites the sample-save globals a save in flight was set up
with, a second way a save could be disturbed (read, not measured).

**Threshold takes** (with REC THRESHOLD in the image): set TRIG to `THR` in
RECORDING SETUP 1 and LEV in RECORDING SETUP 2, as on any track. The red key
then arms instead of starting, and the take starts when the level reaches LEV;
it ends as before (the red key, or RLEN loops). SMPL measures inputs A-D. RSMP
measures its own SRC3 source -- the block the recorder reads for it: T1..T8's
read-back, or MAIN / CUE -- so loud inputs don't start an RSMP take. RECORDING
SETUP 2's IN meter shows the same level for the current track
(`sm_thr_src`, called by REC THRESHOLD's `src_peak`; a weak reference, so
REC THRESHOLD without SMPL measures the inputs as before).

**Known limits:** a take is as long as the recorder's memory allows (16 s by
default; CONTROL > MEMORY makes it longer). In the machine column the cursor
starts on FLEX, with SMPL / RSMP marked as the track's machine. It can't share
an image with CX OSC, SYNTH MACHINE, ANALOG BD or OCTA303 (they own the same
rows), nor with BUFFER SAVER or PERSISTENT BUFFERS (they save the same
buffers). A full card shows stock's save error; that take is not retried.

## How

A chosen track is FLEX (machine byte 1) with a signature in the NEIGHBOR
PLAYBACK column's first three bytes (`Part + 0x8edbc + 30·t`): `SM`,1 or
`RS`,1, as CX OSC stores `CX`,1. The list code is CX OSC's (Tim Hastie's
v2.15): the stock list was written for five machines, so its row counts,
bounds, clamps, names, highlight, SRC SETUP rows and commits are detoured,
and the descriptor table's two spare slots (5, 6) hold the rows' pages
(FLEX's). Choosing a row points the FLEX slot (`Part + 0x8f04b + 5·t`) at
recorder buffer `0x80 + t` and writes the recorder setup (`Part + 0x8f382 +
12·t`), Part and battery-RAM shadow.

The machine window opens an SMPL track as FLEX, so its slot list is FLEX's
(the recorder buffers); its title (`0x40077b82`) names the row, and a YES in
the slot list keeps the machine (`sm_main_commit`, `0x460e739a` = 1).

The record keys set `0x460d10d0` (A/B), `10d4` (C/D), `10d8` (internal) and
call the manual-sampling routine `0x400836d8`, which walks the tracks:

| site | stock | SMPL |
|---|---|---|
| `0x40083756` | RECORD QUICK MODE (`0x800000c4`): the current track counts as held | also when the current track is SMPL / RSMP |
| `0x40030f2e` / `0x40030d4c` | A/B / C/D press sets its flag | on an RSMP current track (no other TRACK held): the internal flag |
| `0x40030f08` / `0x40030cfc` | release clears its flag | clears what the press set |

Save lock (`sm_locked`: pending in `sm_save`, or `sm_cur` while `sm_busy`):

| site | stock | SMPL |
|---|---|---|
| `0x40000c3c` | the queue post (queue, msg) | an editor message (`0x460e5f00`..`0x460e70b9`, not cmd 22 = save to file) on a locked buffer is not posted; its callback (+30) runs on the next UI tick |
| `0x40021bc8` | CLEAR SLOT's dialog on a recording; sets `0x460be9e8`/`ec`, clears `0x460bcfc8` | not opened on a locked buffer |
| `0x40021d0a` / `0x40021d66` | the dialog's clear / unlink | refused on a locked buffer (a dialog opened before the lock) |
| `sm_disp` | -- | a take start on a locked buffer is skipped |

Auto-save and the editor: the recorder's take start (`0x400069e4`, the
site BUFFER SAVER uses) marks an SMPL / RSMP track's run and asks for the
editor, once per run. The UI tick (`fm_tick` → `sm_auto`) opens the editor
with stock's pair `0x4006de34(FLEX, 0x80 + t)`, `0x4006e160` when its window
(`0x460e5e4c`) is closed; when the recorder is idle again (`0x40004268`) it
saves the buffer through BUFFER SAVER's chain (FLEX object 128 + n, mode 2,
the done callback, the naming keyboard's confirm `0x40024288(1)`), one
buffer at a time; a save not reported done within 3000 ticks is given up.

The stop is stock TRIG ONE2 (the end post `0x40005e8e`).

Trig takes in loops: stock re-arms the recorder at every recorder trig, each
pass over the last, and the engine reads RLEN while it records, not only at
the arm (port, 24 Oct 2026: RLEN 1 cut a key take at one step). So the
per-frame publish of the recorder setup (`0x80000c94` → `0x80000cf4 + 96 ×
page`, the memcpy at `0x4000cae2`) gets RLEN MAX for each SMPL / RSMP track
(`sm_pub`; the mask from the UI tick), and the recorder dispatcher's arm call
(`0x4000d356`, `sm_disp`) sorts the words: a start is `0x10`, a recorder
trig's start has `0x200` and not `0x8000` (trig `0x7210` / `0x7218`, the A/B
key `0x9010`; the low nibble is the sample in the frame). The first trig
start is armed; the next ones are counted and not passed on; the one that
ends the RLEN'th loop is sent on as the stop word `0x80` with its nibble.
The run is then done until the transport (`0x800065b8`) stops.

## Proof

`tools/verify/verify_smpl.py` under the port (MKI panel, blank project, the
port's tones on the inputs): SMPL from the machine window and RSMP from SRC
SETUP set the machine, signature, slot and recorder bytes; a YES in SMPL's
slot list keeps it and FLEX in the machine column clears it; on SMPL the A/B
key alone starts and stops one 1.0 s A/B take (the recorder's word `0x9010`,
the end post); on RSMP the same press takes the internal source only
(`0xc010`); a stock track with quick mode off records nothing from the same
presses; a recorder trig on step 1 of a 16-step pattern at RLEN 1 records one take
of 88,200 samples (16 steps at 120 BPM) and no more while the pattern plays
on, saved as one file of 88,200 frames with the editor opened once; at RLEN
2 one take of 176,400; at MAX one take until STOP; STOP and PLAY records a
second take into a second file. A 1 s key take opens the editor (still
open at the end) and is saved as `R1-000000-0000.wav` and `.ot` in the set's
AUDIO/SMPL (which that take created), 1 s and not silent (the port's clock is
unset); NO closes the editor; two takes save two files (`-2`); with SAVE
SAMPLES TO poked to PROJ DIR the take still lands in AUDIO/SMPL and nowhere
else; two FILE > SAVE AND ASSIGNs on the take (PROJ DIR, name kept) write
`-2` then `-3` there, the buffer assigned to the `-3`. The save is entered past stock's name check (`sm_confirm`, see
`docs/contributing/TRAPS.md` "The stock save's name check refuses a folder").
Save lock (runtime poked so buffer 1's save looks in flight): NORMALIZE
SELECTION from the EDIT page (LFO) is not posted, its done callback runs and
the busy flag ends 0; the red key starts no take; CLEAR SLOT (FX2 page) opens
no dialog -- each with SAVING TAKE..; without the poke the same keys post the
normalize and open the dialog.
With REC THRESHOLD (remix `hteah-thr`, TRIG poked to THR, LEV -40 dB, a
WAV on the inputs): SMPL armed in silence takes nothing; silence then a
-20 dBFS sine starts one take (`0x9010`), the red key ends it, it is saved;
RSMP with SRC3 T2 and the sine on the inputs takes nothing, measuring T2's
read-back (`0x80003210` / `0x80003610` as the half flips); RSMP on MAIN
measures `0x80005e60`. MAIN is silent under the port (a plain RSMP take of it
is all zeros), so an RSMP threshold take firing is for the hardware.
Seen on the decoded LCD: a fresh RSMP track's RECORDING SETUP 1 shows SRC3 MAIN. Measured by hand
under the port: a take started inside the editor is saved too, and a take
while the pattern plays is saved. Measured by hand under the port, stock
re-arming (before the loop count): a 7-step track's trig passes are 7 steps
(38,587 / 38,588), and the 2-step rest where the master length restarts it;
stock QREC 4 quantises a ONE2 take's start
and stop (66,150 samples = 3 beats for a 1.2 s press gap).

Not measured: the sound on playback (the port's audio capture is silent in
these runs), a saved and reloaded project, a full card during an auto-save
(BUFFER SAVER's own full-card runs are the reference), an auto-save while a
naming keyboard is open, the hardware. Run on an Octatrack MKI, Oct-Nov 2026 (ACCLOOP2-32; all four machines hardware-checked on ACCLOOP32).
