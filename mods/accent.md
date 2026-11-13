# ACCENT

**TR-909-style soft and full steps for the Octatrack's grid.**

## What it is

On a TR-909 a step can be normal or accented, and you enter both from the
step keys. On a stock Octatrack a quieter hit means holding the trig, turning
to the AMP page and locking VOL, step by step. ACCENT puts two levels on the
trig keys themselves: **one tap gives a full step, a second tap a soft one,
and a third tap clears the step.** Soft steps light dimmer than full ones, so
you can see the dynamics of a pattern on the grid.

A soft step is an ordinary trig with an AMP VOL lock at about -6 dB under the
track's AMP VOL. ACCENT doesn't store anything new, so soft steps save, copy,
paste and undo like any lock, show in the stock lock view, and still play on
a stock OS.

## Mini manual

**Program soft and full steps**

1. Pick an audio track and enter **GRID RECORDING** (REC).
2. Tap a step key:

   | the step is | a tap makes it |
   |---|---|
   | empty | **FULL**: bright red, a normal trig |
   | FULL | **SOFT**: dim red, VOL locked about 6 dB lower |
   | SOFT | **empty** again |

3. Play. Soft steps sit back in the groove and full steps punch through.

**Turn it on or off**

- Hold a **TRACK** key, then tap **CUE**. A message shows `ACCENT ON` or
  `ACCENT OFF`. When it's off, the trig keys are stock.
- ACCENT is **ON** every time the Octatrack starts.
- Stock cueing (CUE held, *then* TRACK) works as before. Only the
  TRACK-then-CUE order toggles ACCENT.

**Good to know**

- The soft level is an absolute VOL lock (half the AMP VOL in amplitude, e.g.
  VOL 127 gives 90, VOL 64 gives 45). If you later turn the track's AMP VOL up,
  existing soft steps keep their old level. Tap them through FULL → SOFT again
  to refresh them.
- Any trig you lock quieter than the track's VOL by hand also lights dim.
- Holding a trig and turning a knob is a normal lock edit and doesn't change
  the step's level.
- MIDI tracks, trigless trigs and one-shot trigs are stock.

## Status

- Hardware: MKI, since ACCLOOP6 (25 Oct 2026) and in every image through
  ACCLOOP32.
- Emulator gate: `tools/verify/verify_accent.py`.
- Source and firmware details: [`overlay/modules/accent/`](../overlay/modules/accent/).
