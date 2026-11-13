# `accent` — ACCENT

Author: [Hteah](https://github.com/Hteah).

TR-909-style two-level steps for audio tracks in **GRID RECORDING**. A tap on
a trig key cycles the step **off → FULL → SOFT → off**, and a soft step's red
trig LED is dim (level 5, stock's dim level) where a full one is bright (15).

A soft step is an ordinary sample trig with an **AMP VOL lock** at the Part's
AMP VOL / √2: −6 dB under AMP VOL's (v/127)² law, `(v·181 + 128) >> 8`,
kept one below the Part value (64 → 45, 127 → 90). Nothing new is stored, so a
soft step saves, copies, pastes and undoes like any lock, and the stock lock
view shows it. Any trig locked quieter than its Part VOL lights dim.

**On / off:** hold a **TRACK** key, then tap **CUE**: a toast reads
`ACCENT ON` or `ACCENT OFF`. Off, trig keys are stock. ACCENT starts ON at
every boot (the switch is not battery-backed). Stock cueing is the other
order (CUE held, then TRACK) and is untouched. TRACK then CUE does nothing on
stock: measured under the port, no LCD, LED or RAM change against holding
the TRACK key alone (FUNC + CUE is stock's RELOAD PART, so it was not used).

Known limit: the lock is an absolute value. Turn the Part's AMP VOL up later
and existing soft steps keep their old level (re-tap them to refresh).

## Behaviour

| tap on a step that is | becomes |
|---|---|
| empty | FULL (stock: a new trig, no locks) |
| FULL (no VOL lock, or one at or above Part VOL) | SOFT (VOL lock written) |
| SOFT | off (stock removal: the trig and all 32 lock bytes go) |

Holding a trig and turning a knob (a stock lock edit) never reaches ACCENT:
stock clears the key's remove flag on the edit, so the release leaves the
trig as it was. MIDI tracks, trigless trigs and one-shots are stock.

## How

Three detours, all in one DRAM unit (`accent.s`):

- `0x40034e5e`, in the grid painter `0x40034bd4` between its colour pass and
  its level pass: the red level of each soft step on the shown page goes in
  the painter's own level array as 5, so the painter sends it once (no
  15/5 flicker). Outside grid recording the other painters send 15 again.
- `0x400601aa`, the audio branch of the trig-key release `0x4005fb44` that
  removes a trig flagged at press (`0x460d1a9e`): a full trig gets the soft
  VOL lock instead (bank blob + battery mirror `0x1001614e`, the step's bit in
  `0x46c7d48c`, the edited flags and `0x40027e00`, as stock's own lock
  store), then rejoins stock's handled exit `0x4006066c`.
- `0x4004e978`, the CUE press: with a track key held (`0x460fab40`, as REC
  TRIG MUTE reads it) it flips `acc_on` and toasts (`0x4005a2b8`, legal
  from a key handler) instead of setting the cue-held flag.

## Proof

`tools/verify/verify_accent.py` under the port (MKI panel, one load, forked
scenarios): the tap cycle, the lock in the blob and its mirror, the LED
levels decoded from the panel link, a held-trig PTCH edit leaving the trig
full, ACCENT disabled = stock, TRACK + CUE off and on again with the cue
mask untouched, CUE + TRACK still cueing, and playback: when step 1 fires, the live
lane's AMP VOL is 45 for a soft step and 64 for a full one (Part VOL 64).
Run on an Octatrack MKI since ACCLOOP6 (25 Oct 2026), in every image through ACCLOOP32.
