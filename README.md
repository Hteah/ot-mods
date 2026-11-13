# OT MODS

**Firmware mods for the Elektron Octatrack MKI, by [Hteah](https://github.com/Hteah).**
Built on [octabam](https://github.com/sambanks/octabam) and installed by
building the OS on your own computer from Elektron's own 1.40C download.

| mod | in one line | mini manual |
|---|---|---|
| **SAMPLER · RESAMPLE · LOOPER · RELOOPER** | four machines that make a track its own sampler: red key in, red key out | [mods/samplers.md](mods/samplers.md) |
| **ACCENT** | TR-909-style soft and full steps on the trig keys | [mods/accent.md](mods/accent.md) |
| **PAGE LOOP** | loop the 16-step page you're editing, stay in time | [mods/page-loop.md](mods/page-loop.md) |
| **TRACK TRIG MODE** | each track remembers CHROMATIC / SLOTS / SLICES | [mods/track-trig-mode.md](mods/track-trig-mode.md) |
| **TRIG MUTE** | mute one trig without deleting it | [mods/trig-mute.md](mods/trig-mute.md) |

There are two builds to choose from:

- **full** (default): all of the above, plus REC THRESHOLD, MUTE MODES, TAPE
  ECHO, MINI VERB and ATA WRITE GUARD by other octabam authors
  ([what those are](mods/also-included.md)). This is the set Hteah runs on his
  own MKI.
- **samplers**: only the four sampler machines (+ REC THRESHOLD, ATA WRITE
  GUARD), with every effect stock.

All the mods share one goal: **remove the settings you have to remember.**
Each one takes something the Octatrack can already do and makes it one key
press, or something you can see.

---

## The sampler manifesto

The Octatrack can sample anything, but on the MKI you have to plan it first.

To sample a synth on a stock MKI you set up a Flex machine, point its slot at
one of the eight recording buffers, open RECORDING SETUP to choose the inputs,
the trig mode and the length, then hold a TRACK key and press a record key. If
you get any of those settings wrong, nothing records, and you can't see why.
When it does record, the take sits in RAM at whatever level it came in at, and
it disappears when you switch off unless you go into the audio editor, type a
name and save it. Resampling the Octatrack itself uses a different source page
and another key combo. Live looping works too, but only once you've set up
recorder trigs, RLEN, QREC and the buffer slot.

So you end up remembering settings when you meant to be making music. Forget
one small setting and the box looks broken.

These machines move that setup into the machine itself. **You choose what the
track is, not how the recorder is configured.**

| | records | you press | then |
|---|---|---|---|
| **SAMPLER** | the inputs (A/B or C/D) | the red key: tap in, tap out | the take is normalized to -4 dBFS and saved as a file, already on the track |
| **RESAMPLE** | the Octatrack's own sound (MAIN, CUE or one track) | the red key: tap in, tap out | normalized and saved, like SAMPLER |
| **LOOPER** | the inputs | a recorder trig (RLEN = number of loops) or the red key | plays straight away from RAM: no processing, no wait |
| **RELOOPER** | the Octatrack's own sound | a recorder trig or the red key | plays straight away, like LOOPER |

Compared with stock, a track using one of these machines:

- **Plays its own recording.** The track's Flex slot already points at its own
  recorder buffer, so there's nothing to load or assign. Put a trig down and
  the take plays. Sequence it, p-lock it, slice it like any Flex sample.
- **Is set up when you choose the machine.** TRIG, RLEN and the sources are
  set for you. Choose a stock machine and the track goes back to normal.
- **Records on one key.** The red key alone starts and stops a take, whether
  the sequencer is playing or stopped. You don't need a TRACK key combo or
  RECORD QUICK MODE.
- **Shows you the take.** The audio editor opens when a take starts and draws
  the waveform as it records. It stays on the take while you move to other
  tracks.
- **Keeps every take (SAMPLER / RESAMPLE).** Each take is checked for silence
  and normalized, then written to the card as `AUDIO/SMPL/R1-YYMMDD-HHMM.wav`.
  Nothing is ever overwritten. TRASH TAKE moves a take you don't want to
  `AUDIO/SMPL/TRASH`.
- **Monitors through the track.** While it's empty or recording, a SAMPLER
  track plays its input through its own AMP and effects. The file is recorded
  dry.
- **Records loops of the track (LOOPER / RELOOPER).** RLEN counts *passes of
  the track*, not steps, and the take stops exactly on the loop point and
  starts playing. STOP and PLAY records a new one. FILE > SAVE AND ASSIGN keeps
  one (three presses, no typing).

Everything else on the Octatrack, and every track not using one of these
machines, works as stock. → **[Mini manual](mods/samplers.md)**

---

## Install

**No Elektron firmware is stored in this repository or shared by it.** The
installer downloads the official OS 1.40C from elektron.se and adds the mods
to it on your computer.

```bash
git clone https://github.com/Hteah/ot-mods.git
cd ot-mods
./install.sh                          # full build -> dist/OCTATRACK_HTEAH1.bin
./install.sh --remix samplers         # samplers only -> dist/OCTATRACK_SAMPLERS1.bin
./install.sh --card /Volumes/OCTA     # also copy it to your CF card (checked)
./install.sh --build 2                # version number shown on the OT
```

Requirements: macOS with [Homebrew](https://brew.sh) and the Xcode Command
Line Tools (`xcode-select --install`), or Debian/Ubuntu/WSL2. The installer
installs the remaining build tools (an m68k cross compiler, binwalk, radare2,
cmake, uv). The first run takes a while because it builds those tools. After
that a rebuild takes a few minutes.

### Flash it

1. **Back up your CF card.** Copy the `.bin` to the root of the card and put
   the card in the Octatrack.
2. **PROJECT > SYSTEM > OS UPGRADE**, choose the file, confirm.
3. When it has restarted, **PROJECT > SYSTEM > OS VERSION** should read
   `HTEAH1` (or `SAMPLERS1`). If it still says 1.40C, power off and on and
   run OS UPGRADE again (the first try sometimes doesn't take).

This is unofficial firmware: use it at your own risk.

### Going back

- **Normal way:** copy the stock `OCTATRACK_OS1.40C.bin` (the installer
  downloaded it to `work/octabam/downloads/extracted/`) to the card and run OS
  UPGRADE again.
- **If the unit won't start:** hold **FUNC** while powering on to open the
  Startup Menu, choose **MIDI UPGRADE** (TRIG 3), and send the stock
  `OCTATRACK_OS1.40C.syx` over DIN MIDI with a SysEx tool.

Projects stay readable on stock: soft steps are ordinary VOL locks, trig modes
are a comment line stock skips, and sampler takes are ordinary WAVs. The only
loss is that muted trigs play again (their condition shows ERR on stock).

---

## What's been tested

- **Hardware (MKI):** every mod has run on Hteah's MKI. ACCENT and PAGE LOOP
  since 25 Oct 2026, TRACK TRIG MODE since 27 Oct, TRIG MUTE since 28 Oct, and
  all four sampler machines in ACCLOOP32 (8–11 Nov 2026).
- **The full build *is* ACCLOOP32.** `./install.sh --build 32 --name
  ACCLOOP32` rebuilds the exact image tested on the MKI, byte for byte
  (compared against the ACCLOOP32 file that was flashed). With the default name only the
  version text differs.
- **The samplers build** uses the same module source but hasn't itself been
  flashed.
- **Emulator:** `make check` passes for both builds. That's octabam's full
  build plus every gate under its ColdFire/DSP port with the MKI panel
  (`verify_smpl`, `verify_accent`, `verify_page_loop`,
  `verify_track_trig_mode`, `verify_trig_mute`).
- **MKII:** not tested.

---

## How it was built (and building your own)

**[BUILDING.md](BUILDING.md)** covers how these mods were built: the method,
the firmware sites they hook, how they were tested, and what went wrong on
the way. It's written so you can hand it to your own AI coding agent and have
it rebuild these mods or make new ones. [AGENTS.md](AGENTS.md) is the short
brief for the agent.

## What's in this repo

| path | what |
|---|---|
| `install.sh` | the installer: clone octabam at the pinned commit, add the overlay, build |
| `OCTABAM_COMMIT` | the octabam commit everything was built and tested against |
| `mods/` | an explanation and mini manual for each mod |
| `overlay/modules/{smpl,accent,page-loop,track-trig-mode,trig-mute}/` | the mods' source (ColdFire assembly + `manifest.py` hooks + a technical README) |
| `overlay/remixes/test/hteah-thr/` | the **full** build |
| `overlay/remixes/samplers/` | the **samplers** build |
| `overlay/tools/verify/verify_*.py` | the emulator gates |
| `overlay/…` (other) | small changes to octabam: the REC THRESHOLD hook, TAPE ECHO / MINI VERB labels, an emulator fix, docs |

## Credits and licence

- SAMPLER / RESAMPLE / LOOPER / RELOOPER, ACCENT, PAGE LOOP, TRACK TRIG MODE,
  TRIG MUTE: **[Hteah](https://github.com/Hteah)**, designed on and for his
  MKI and built with Claude (Anthropic) as the coding agent.
- **[octabam](https://github.com/sambanks/octabam)** by Sam Banks and
  contributors (MIT): the remixer, the build, the emulator, and the modules
  in [also-included](mods/also-included.md): REC THRESHOLD (Chupitnik), MUTE
  MODES (Zac Kyoti), TAPE ECHO and MINIVERB (repeat98), ATA WRITE GUARD (Sam
  Banks).
- The sampler machine-list code is **Tim Hastie's** v2.15 `machine.s`
  ([octatrick-modules](https://github.com/timhastie/octatrick-modules), MIT), as
  carried by ilia-murzinov's CX OSC. Tim adapted it from Modwerk's FM Synth
  ([repeat98/modwerk](https://github.com/repeat98/modwerk), MIT). See
  `overlay/modules/smpl/NOTICE`.
- MIT licence ([LICENSE](LICENSE)). Octatrack and Elektron are trademarks of
  Elektron Music Machines. This project is not affiliated with or endorsed by
  Elektron.
