# TRIG MUTE

**Mute a single trig without deleting it.**

## What it is

On a stock Octatrack, silencing one hit means removing the trig, along with
its locks, its condition and its micro timing. Newer Elektron boxes let you
mute a trig instead. TRIG MUTE does that on the Octatrack: **a muted trig
stays on the grid with everything on it, it just doesn't play.** Unmute it and
it's back exactly as it was. That makes it handy for trying a pattern with
and without a hit, or for building variations.

## Mini manual

**Mute or unmute**

1. On an audio track, enter **GRID RECORDING** (REC).
2. **Hold a step key and press FUNC.** The message says `TRIG MUTED`.
3. Do it again to unmute (`TRIG UNMUTED`).

- Hold several steps and press FUNC to toggle them all at once.
- Hold an *empty* step and press FUNC to place a trig that starts muted.
- A muted trig's red LED **blinks**.

**Good to know**

- The trig's condition still shows and edits as usual (step + LEVEL).
- Removing a trig removes its mute. A newly placed trig starts unmuted.
- Trigs with the 7:8 or 8:8 condition can't be muted (`CAN'T MUTE 7:8 8:8`).
- Recorder trigs on a muted step still run.
- The mute is stored in the pattern itself, so it saves with the bank, copies
  and pastes with trigs and patterns, and survives a power cycle. On a stock
  OS a muted trig plays and its condition shows ERR.
- A red + green flash on a step is the stock sample-lock flash, not the mute.
- MIDI tracks are not handled (FUNC there is stock).

## Status

- Hardware: MKI, since ACCLOOP16 (28 Oct 2026): mute/unmute, the messages,
  and mutes kept over save and power cycle.
- Emulator gate: `tools/verify/verify_trig_mute.py`.
- Source and firmware details: [`overlay/modules/trig-mute/`](../overlay/modules/trig-mute/).
