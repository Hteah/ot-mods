# `samplers`

SAMPLER, RESAMPLE, LOOPER and RELOOPER (module SMPL) with REC THRESHOLD
(threshold takes on SAMPLER / RESAMPLE) and ATA WRITE GUARD, on the 14 stock
effects.

## What is in it

- **SMPL** -- [`modules/smpl/README.md`](../../modules/smpl/README.md).
- **REC THRESHOLD** -- [`modules/rec-threshold/README.md`](../../modules/rec-threshold/README.md).
- **ATA WRITE GUARD** -- [`modules/ata-write-guard/README.md`](../../modules/ata-write-guard/README.md).
- the 14 stock FX2 effects.

## Where it has run

The four machines ran on an Octatrack MKI (Nov 2026) inside a larger image
(Hteah's ACCLOOP32: these modules plus ACCENT, PAGE LOOP, TRACK TRIG MODE,
TRIG MUTE, MUTE MODES, TAPE ECHO, MINIVERB). This remix: `make check` under
the port only.

## Build

```bash
make check REMIX=samplers
make image REMIX=samplers BUILD=1 VERSION=SAMPLERS1
```
