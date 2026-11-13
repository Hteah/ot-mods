# OT SAMPLERS

**Four sampler machines for the Octatrack MKI: SAMPLER, RESAMPLE, LOOPER, RELOOPER.**

A firmware mod built on [octabam](https://github.com/sambanks/octabam). Pick
one of these machines for a track and that track becomes its own sampler. You
press the red key and you're recording.

---

## The manifesto

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
- **Is set up when you choose the machine.** TRIG, RLEN and the sources (A B / C D
  for the input machines, SRC3 MAIN for the internal ones) are set for you.
  Choose a stock machine and the track goes back to normal.
- **Records on one key.** The red key alone starts and stops a take, whether
  the sequencer is playing or stopped. You don't need a TRACK key combo or
  RECORD QUICK MODE.
- **Shows you the take.** The audio editor opens when a take starts and draws
  the waveform as it records. It stays on the take while you move to other
  tracks.
- **Keeps every take (SAMPLER / RESAMPLE).** Each take is checked for silence
  and normalized, then written to the card as `AUDIO/SMPL/R1-YYMMDD-HHMM.wav`.
  Nothing is ever overwritten. A silent take shows NO SOUND IN TAKE and isn't
  saved. If you don't want a take, TRASH TAKE moves it to `AUDIO/SMPL/TRASH`.
- **Monitors through the track.** While it's empty or recording, a SAMPLER
  track plays its input through its own AMP and effects, so you hear them as
  you play. The file is recorded dry.
- **Records loops of the track (LOOPER / RELOOPER).** Put a recorder trig and a
  sample trig on step 1. RLEN counts *passes of the track*, not steps, and the
  take stops exactly on the loop point and starts playing. You get one take
  per run. STOP and PLAY to record a new one, or keep a take with FILE > SAVE
  AND ASSIGN (three presses, no typing).

Everything else on the Octatrack, and every track not using one of these
machines, works as stock.

> The full behaviour of every machine, down to the firmware sites, is in
> [overlay/modules/smpl/README.md](overlay/modules/smpl/README.md).

---

## Install

You build the OS on your own Mac or Linux machine from Elektron's own 1.40C
download. **No Elektron firmware is stored in this repository or shared by
it.** The installer downloads the official OS from elektron.se and adds the
sampler machines to it on your computer.

```bash
git clone https://github.com/Hteah/ot-samplers.git
cd ot-samplers
./install.sh                         # -> dist/OCTATRACK_SAMPLERS1.bin
./install.sh --card /Volumes/OCTA    # same, then copies it to your CF card
```

Requirements: macOS with [Homebrew](https://brew.sh) and the Xcode Command
Line Tools (`xcode-select --install`), or Debian/Ubuntu/WSL2. The installer
installs the remaining build tools (an m68k cross compiler, binwalk, radare2,
cmake, uv). The first run takes a while because it builds those tools. After
that a rebuild takes a few minutes.

### Flash it

1. Copy `OCTATRACK_SAMPLERS1.bin` to the root of the CF card and put the card
   in the Octatrack.
2. **PROJECT > SYSTEM > OS UPGRADE**, choose the file, confirm.
3. When it has restarted, **PROJECT > SYSTEM > OS VERSION** should read
   `SAMPLERS1`. If it still says 1.40C, power off and on and run OS UPGRADE
   again (the first try sometimes doesn't take).

Back up your CF card first. This is unofficial firmware: use it at your own
risk.

### Going back

- **Normal way:** copy the stock `OCTATRACK_OS1.40C.bin` (the installer
  downloaded it to `work/octabam/downloads/extracted/`) to the card and run OS
  UPGRADE again.
- **If the unit won't start:** hold **FUNC** while powering on to open the
  Startup Menu, choose **MIDI UPGRADE** (TRIG 3), and send the stock
  `OCTATRACK_OS1.40C.syx` over DIN MIDI with a SysEx tool.

### Using a machine

Double-tap a **TRACK** key, press **LEFT** for the machine list and scroll
down past PICKUP: you'll see SAMPLER, RESAMPLE, LOOPER, RELOOPER. (FUNC + SRC
gets there too.)

---

## What's been tested

- **Hardware:** all four machines were tested on an Octatrack **MKI** in
  November 2026 (Heath's image ACCLOOP32). That image also contained his other
  mods. The image this installer builds has only the samplers, plus REC
  THRESHOLD and ATA WRITE GUARD, with the stock effects. It's built from the
  same module source and passes the same gates in the emulator, but this exact
  image hasn't been flashed to hardware.
- **Emulator:** `make check REMIX=samplers` passes. That's octabam's full build
  and every gate under its ColdFire/DSP port, with the MKI panel, including
  the `verify_smpl` scenarios: key takes, trig takes over RLEN loops, 16- and
  24-bit saves, silent-take refusal, save lock, monitoring, trash, threshold
  takes.
- **MKII:** not tested. The machine-list code comes from modules that have
  run on an MKII, but the sampler machines have only been run on an MKI.

### Known limits and gotchas

- A take can only be as long as recorder memory allows (**CONTROL > MEMORY**;
  16 s by default).
- **RELOOPER / RESAMPLE with SRC3 MAIN** record themselves if their own track
  plays while recording, which causes feedback. Use SRC3 CUE (and cue only the
  tracks you want) or one track as the source.
- **SRC3 CUE records nothing** until you cue some tracks (CUE + TRACK).
- **QREC on SAMPLER:** if the SCALE master length is INF, QREC = PLEN never
  fires, so it looks like the take never starts. Set QREC to a step count (for
  example 16) or OFF.
- LOOPER / RELOOPER takes stay in RAM and are lost at power-off unless you
  save them. After a reload the looper track starts empty. To keep a loop in
  the project, assign the saved file to a Static or Flex slot.
- This build can't be combined with octabam's CX OSC, SYNTH MACHINE, ANALOG BD
  or OCTA303 (they use the same machine-list rows), or with BUFFER SAVER or
  PERSISTENT BUFFERS (they save the same buffers).

---

## How it was built (and building your own)

**[BUILDING.md](BUILDING.md)** covers how these machines were built: the
method, the firmware sites they hook, how they were tested, and what went
wrong on the way. It's written so you can hand it to your own AI coding agent
and have it rebuild these machines or make new ones. [AGENTS.md](AGENTS.md) is
the short brief for the agent.

## What's in this repo

| path | what |
|---|---|
| `install.sh` | the installer: clone octabam at the pinned commit, add the overlay, build |
| `OCTABAM_COMMIT` | the octabam commit everything was built and tested against |
| `overlay/modules/smpl/` | the module: `machine.s` (ColdFire assembly), `manifest.py` (its hooks), README |
| `overlay/modules/rec-threshold/` | REC THRESHOLD with the hook SAMPLER uses for threshold takes |
| `overlay/remixes/samplers/` | the remix: SMPL + REC THRESHOLD + ATA WRITE GUARD + the 14 stock effects |
| `overlay/tools/verify/verify_smpl.py` | the emulator gates |
| `BUILDING.md`, `AGENTS.md` | how it was made |

## Credits and licence

- SAMPLER / RESAMPLE / LOOPER / RELOOPER: **[Hteah](https://github.com/Hteah)**,
  designed on and for his MKI and built with Claude (Anthropic) as the coding
  agent.
- **[octabam](https://github.com/sambanks/octabam)** by Sam Banks and
  contributors (MIT): the remixer, the build, the emulator, and REC THRESHOLD
  (Chupitnik) and ATA WRITE GUARD (sambanks).
- The machine-list code is **Tim Hastie's** v2.15 `machine.s`
  ([octatrick-modules](https://github.com/timhastie/octatrick-modules), MIT), as
  carried by ilia-murzinov's CX OSC. Tim adapted it from Modwerk's FM Synth
  ([repeat98/modwerk](https://github.com/repeat98/modwerk), MIT). See
  `overlay/modules/smpl/NOTICE`.
- MIT licence ([LICENSE](LICENSE)). Octatrack and Elektron are trademarks of
  Elektron Music Machines. This project is not affiliated with or endorsed by
  Elektron.
