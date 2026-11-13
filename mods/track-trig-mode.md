# TRACK TRIG MODE

**Each audio track remembers its own trig mode: CHROMATIC, SLOTS or SLICES.**

## What it is

On a stock Octatrack the trig mode (FUNC + UP/DOWN) is global. If track 1
plays slices and track 2 plays chromatically, you have to switch the mode
every time you change track. With TRACK TRIG MODE **each track keeps the mode
you last picked on it**, so changing track changes what the trig keys do. The
modes are saved with the project and survive a power cycle.

## Mini manual

**Set a track's mode**

1. Select the track.
2. Hold **FUNC** and press **UP / DOWN** to choose **CHROMATIC**, **SLOTS** or
   **SLICES**, as usual. That track now remembers it.
3. Select another track and its own mode comes up on the trig keys.

**The global modes**

- **TRACKS**, **QUICK MUTE** and **DELAY CONTROL** are still global. They
  stay put when you change track and are never stored on a track.
- Stepping out of one of them with FUNC + UP/DOWN lands on the current
  track's own mode and doesn't overwrite it.

**Good to know**

- A track you've never set takes whatever mode is showing.
- Modes are saved with **SAVE PROJECT** (and the working copy) and kept over
  a power cycle. When a project loads, the current track's mode shows.
- In the project file they're one comment line, `#TRIG_MODES=12300000` (T1–T8:
  0 none, 1 CHROMATIC, 2 SLOTS, 3 SLICES). Stock OS ignores comment lines, so
  the project still opens on a stock Octatrack.
- MIDI tracks are not handled (MIDI trig mode is stock).

## Status

- Hardware: MKI, since ACCLOOP15 (27 Oct 2026): switching, save, reload and
  power cycle. The exit from TRACKS/QUICK MUTE was fixed in ACCLOOP17 and
  confirmed on the MKI.
- Emulator gate: `tools/verify/verify_track_trig_mode.py`.
- Source and firmware details: [`overlay/modules/track-trig-mode/`](../overlay/modules/track-trig-mode/).
