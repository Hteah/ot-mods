# `hteah-thr`

Heath's ColdFire modules on the stock effects: `hteah-mods` plus REC THRESHOLD, MUTE MODES, TAPE ECHO (SPRING REV's slot) MINIVERB (DARK REV's slot) and ATA WRITE GUARD.

## What is in it

- **ACCENT** -- [`modules/accent/README.md`](../../../modules/accent/README.md).
- **PAGE LOOP** -- [`modules/page-loop/README.md`](../../../modules/page-loop/README.md).
- **SMPL** -- [`modules/smpl/README.md`](../../../modules/smpl/README.md).
- **REC THRESHOLD** -- [`modules/rec-threshold/README.md`](../../../modules/rec-threshold/README.md); on an RSMP track it measures the track's SRC3 source.
- **TRACK TRIG MODE**, **TRIG MUTE** -- Heath's modules.
- **MUTE MODES** -- [`modules/mute-modes/README.md`](../../../modules/mute-modes/README.md); PERSONALIZE > MUTE MODE.
- **TAPE ECHO** -- [`modules/tapeecho/README.md`](../../../modules/tapeecho/README.md); replaces SPRING REV (CPU effect: at most six at once).
- **ATA WRITE GUARD** -- [`modules/ata-write-guard/README.md`](../../../modules/ata-write-guard/README.md); closes stock's first-sector card-write race (an ACCLOOP26 REC THRESHOLD gate hung in it under the port).
- **MINIVERB** -- [`modules/miniverb/README.md`](../../../modules/miniverb/README.md); replaces DARK REV.
- the other 12 stock FX2 effects.

## Build

```bash
make check REMIX=hteah-thr
```
