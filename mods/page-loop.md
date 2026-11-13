# PAGE LOOP

**Loop one 16-step page of one track while you work on it, and stay in time.**

## What it is

When you're editing page 3 of a 64-step pattern on a stock Octatrack, you hear
page 3 once every four bars. Newer Elektron boxes can loop just the page
you're editing. PAGE LOOP brings that to the Octatrack: **the current track
loops one page while every other track keeps playing the full pattern.** When
you end the loop, the track goes back to exactly where it would have been,
still in time with the rest.

It works on audio and MIDI tracks.

## Mini manual

**Loop a page**

1. Pick the track, enter **GRID RECORDING** (REC) and start the pattern.
2. Hold **PAGE** and tap **trig 1, 2, 3 or 4** for the page to loop. The
   message says `LOOP PAGE n`.
3. Edit the page as much as you like. You hear it every 16 steps.

**End the loop**

- The same combo again (PAGE + that trig key) shows `LOOP OFF`, and the
  track picks up where the full pattern is.
- Changing pattern or bank also ends it.

**Good to know**

- One loop at a time. It stays with its track when you switch tracks, and
  keeps looping after you leave GRID RECORDING until you end it.
- On a short last page (e.g. page 3 of a 40-step pattern) only the steps that
  exist loop. Picking a page the pattern doesn't have shows `NO SUCH PAGE`.
- The loop changes what PAGE + trig does in GRID RECORDING. On stock that
  combo places a trig and flips the page. PAGE + REC / PLAY / STOP (page copy,
  clear, paste) are unchanged.
- **Known limit:** if you press PLAY with a loop already on, the very first
  step plays step 1 of the pattern, and the page loops from the second step
  on. Starting the loop while playing doesn't have this quirk.

## Status

- Hardware: MKI, since ACCLOOP6 (25 Oct 2026) and in every image through
  ACCLOOP32.
- Emulator gate: `tools/verify/verify_page_loop.py`.
- Source and firmware details: [`overlay/modules/page-loop/`](../overlay/modules/page-loop/).
