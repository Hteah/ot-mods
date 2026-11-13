# Also in the full build (by other octabam authors)

The **full** build is the set Hteah runs on his MKI. Alongside his own mods it
includes these octabam modules by other people. They're credited here and
documented upstream; this repo only changes two display labels.

## REC THRESHOLD (Chupitnik)

A recorder TRIG mode that waits for the input, like the Digitakt 2's
threshold recording.

1. RECORDING SETUP 1 (FUNC + REC AB): turn **TRIG** past ONE, ONE2, HOLD to
   **THR**.
2. RECORDING SETUP 2 (FUNC + REC CD): **LEV** (in QREC's place) is the
   threshold, and **IN** (in QPL's place) shows the live input level. Set LEV
   a few dB below what IN reads.
3. Arm with TRACK + REC (or the red key on a SAMPLER). While it waits, the
   track's icon blinks. The take starts when the level reaches LEV.

With the sampler machines, a RESAMPLE track measures its own SRC3 source, not
the inputs.
[Full docs](https://github.com/sambanks/octabam/tree/main/modules/rec-threshold)

## MUTE MODES (Zac Kyoti)

**PERSONALIZE > MUTE MODE** sets what a muted track does:

| mode | muted track |
|---|---|
| OT | stock: instant cut after the FX |
| OTFX | dry sound cuts, FX tails ring out |
| OTFX-T | as OTFX, and new trigs are suppressed |
| DT-T | the sounding note plays out on its envelope, new trigs suppressed |

[Full docs](https://github.com/sambanks/octabam/tree/main/modules/mute-modes)

## TAPE ECHO (repeat98), in place of SPRING REV

A mono single-head tape echo with wow, flutter and tape-age character,
running on the ColdFire CPU. Choose **TAPE ECHO** where SPRING REV was in the
FX list. [Full docs](https://github.com/sambanks/octabam/tree/main/modules/tapeecho)

## MINI VERB (repeat98), in place of DARK REV

A smooth, diffuse stereo reverb. Knobs: **DEC** (decay), DAMP, MIX, MOD,
RATE. Choose **MINI VERB** where DARK REV was.
[Full docs](https://github.com/sambanks/octabam/tree/main/modules/miniverb)

(This build shows the names in capitals, TAPE ECHO / MINI VERB, and
shortens MINIVERB's DECAY to DEC so it fits.)

## ATA WRITE GUARD (Sam Banks)

A fix with nothing to operate. It closes a timing window in card writes that
can hang a project load. [Full docs](https://github.com/sambanks/octabam/tree/main/modules/ata-write-guard)
