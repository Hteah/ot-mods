# SAMPLER · RESAMPLE · LOOPER · RELOOPER

**Four machines that make a track its own sampler.** The why, compared with
stock sampling, is in the [manifesto on the front page](../README.md#the-sampler-manifesto).
This page is the mini manual.

## Choosing a machine

Double-tap a **TRACK** key, press **LEFT** for the machine list and scroll down
past PICKUP. (FUNC + SRC gets there too.)

Choosing one points the track's Flex slot at its own recorder buffer (track 1
→ RECORDING 1 …). It also sets TRIG to ONE2 (press again to stop), RLEN to 1,
and the sources: inputs A B / C D for SAMPLER and LOOPER, SRC3 MAIN for
RESAMPLE and RELOOPER. Choosing a stock machine puts the track back to normal.

| | records | starts with | after the take |
|---|---|---|---|
| **SAMPLER** | inputs A/B or C/D | the red key: tap in, tap out | normalized to -4 dBFS, saved to `AUDIO/SMPL` |
| **RESAMPLE** | SRC3: MAIN, CUE or one track | the red key | normalized and saved |
| **LOOPER** | inputs | a rec trig (RLEN loops) or the red key | plays at once from RAM |
| **RELOOPER** | SRC3 | a rec trig or the red key | plays at once from RAM |

Use **SAMPLER** to capture a sound you want to keep (a synth line, a vocal,
a field recording) and **LOOPER** to build loops live while the pattern runs.
**RESAMPLE** and **RELOOPER** do the same with the Octatrack's own sound.

---

## SAMPLER: tap in, tap out, keep it

1. Set a track to SAMPLER. While it's empty you hear the input through the
   track's own effects.
2. Tap **A/B** (inputs A and B) or **C/D**. The take starts at once, and the
   audio editor opens and draws the waveform as you play. You can switch to
   other tracks while it records.
3. Tap the same key again. The take stops, `PROCESSING TAKE.. nn%` shows
   while it's normalized, then it's saved as
   `AUDIO/SMPL/R1-YYMMDD-HHMM.wav` (`-2`, `-3` … if that name is taken).
4. Put a trig on the track and it plays the take. Trim or slice it in the
   editor, which stays open until NO.

- Works with the sequencer stopped or playing.
- **Quantised start/stop:** set QREC in RECORDING SETUP 2 (FUNC + C/D) to a
  step count, e.g. 16. Leave QPL off. If your SCALE master length is INF,
  don't use QREC = PLEN, because it never fires.
- Recorder trigs do nothing on a SAMPLER track. Quantised loops are
  LOOPER's job.
- A silent take shows `NO SOUND IN TAKE` and isn't saved.
- **Don't want a take?** In the editor go to FILE > **TRASH TAKE**. It moves
  the take to `AUDIO/SMPL/TRASH`.
- **Clear the track:** CLEAR SLOT clears a saved take in one YES.
- **Threshold start:** set TRIG to THR (RECORDING SETUP 1) and LEV (SETUP 2).
  The red key then arms, and the take starts when the input reaches LEV.
- The file is recorded dry. The effects you hear while recording are not in
  it.

## RESAMPLE: record the Octatrack itself, keep it

1. Set a track to RESAMPLE. Its inputs are off and SRC3 is MAIN.
2. Play your pattern and tap a red key to start, then tap it again to stop.
   The take is normalized and saved, like SAMPLER.
3. Mute the original tracks and play the new one. Your beat is now one
   sample, ready to slice, reverse or pitch.

| SRC3 | records |
|---|---|
| MAIN | everything you hear (the default) |
| CUE | only the tracks you've cued (CUE + TRACK first, or it records silence) |
| T1–T8 | one track |

- **Watch for feedback:** with SRC3 MAIN, if the RESAMPLE track itself plays
  (has trigs) while it records, it records itself. Use CUE or one track, or
  keep trigs off it while recording.

## LOOPER: live loops on a trig

1. Set a track to LOOPER.
2. Open RECORDING SETUP 1 (FUNC + A/B) and set **RLEN** = number of loops
   (1 = one pass of the track, 4 = four, MAX = until STOP). With the page
   still open, tap **step 1** for a recorder trig.
3. Close the page and tap **step 1** again for a sample trig, so the take
   plays.
4. Press **PLAY** and play along. After RLEN passes the take stops exactly on
   the loop point and starts playing, and the input goes quiet.

- One take per run. **STOP, PLAY** records a new loop over the last one.
- RLEN counts passes of the track, not steps (on 16 steps: 1 = one bar).
- The red key also works: tapping it while nothing records starts a
  free-length take. With QREC set, the stop is quantised too.
- **Keep a loop:** LOOPER takes live in RAM and are lost at power-off. In the
  editor, **FILE > SAVE AND ASSIGN**, then YES, YES. The name is already
  filled in, and the file goes to `AUDIO/SMPL`. After a reload the LOOPER track
  starts empty, so to keep a loop in the project assign the file to a Static
  or Flex slot.
- LOOPER takes are never normalized or scanned for silence.

**Layering:** track 1 LOOPER, RLEN 2, PLAY, record. If you like it, remove
track 1's rec trig (keep its sample trig) and set up track 2 the same way.
STOP, PLAY: track 1 plays its loop while track 2 records the next part.

## RELOOPER: capture the mix as a loop

1. Set a track to RELOOPER (SRC3 MAIN by default, or CUE, or one track).
2. Put a recorder trig and a sample trig on step 1 and set RLEN, as for
   LOOPER.
3. Press **PLAY**. After RLEN loops the mix is captured and RELOOPER plays it
   back on its own track.
4. Now mute, change or mangle the source tracks (RATE, STRT, RTRG, effects)
   while the captured groove keeps going.

- **Watch SRC3:** with MAIN, RELOOPER's own sample trig plays the loop into
  MAIN while it records, so it records itself layer on layer. For a clean
  loop use **CUE** (and don't cue the RELOOPER track) or one track.

---

## Limits

- A take can only be as long as recorder memory allows (CONTROL > MEMORY).
- While one of these tracks is recording, the red key only stops that take.
- Can't be built together with octabam's CX OSC, SYNTH MACHINE, ANALOG BD,
  OCTA303, BUFFER SAVER or PERSISTENT BUFFERS.

## Status

- Hardware: all four machines tested on an MKI with ACCLOOP32 (8–11 Nov 2026).
  SAMPLER/RESAMPLE have been in use since ACCLOOP6 (25 Oct 2026).
- Emulator gate: `tools/verify/verify_smpl.py` (58 checks).
- Source and every firmware site: [`overlay/modules/smpl/`](../overlay/modules/smpl/).
- How it was built: [BUILDING.md](../BUILDING.md).
