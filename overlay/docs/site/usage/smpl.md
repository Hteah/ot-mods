Two sampler machines: a track that records into its own recorder buffer
and plays it back as a Flex sample, with one button.

## Access

Choose **SMPL** (inputs) or **RSMP** (internal sound) in the machine list:
double-tap the track key and press LEFT, or FUNC + SRC. Not in an official
remix; build the test remix `smpl`.

## Operation

- SMPL: the A/B key records inputs A/B, the C/D key inputs C/D. RSMP: either
  key records the recorder's SRC3 source (MAIN unless you chose another).
- Press the record key alone to start, and again to stop. No TRACK key and no
  RECORD QUICK MODE needed; other tracks work as stock.
- A key take is as long as you record. With QREC set (FUNC + C/D, knob D) it
  starts and stops on that grid.
- A recorder trig records RLEN loops of the track as one take: here RLEN
  counts loops (1 by default, up to 64; MAX until STOP), on the track's own
  length and scale. Then the trig rests while the pattern plays on; STOP and
  PLAY to record again. 128 steps on a 64-step track: RLEN 2.
- The take plays on your trigs like any Flex sample, with the Flex PLAYBACK
  page.
- The audio editor opens on the track's buffer when a take starts, so you
  watch it record. It stays open afterwards; NO goes back.
- Every take is saved to the card when it ends, as a new file
  `R<n>-YYMMDD-HHMM` (`-2`, `-3` … if taken), in the set's `AUDIO/SMPL`
  folder (the first take makes it), and the buffer points at it. PERSONALIZE >
  SAVE SAMPLES TO doesn't move SMPL takes. Saving works while the pattern
  plays.
- Choosing SMPL / RSMP sets the recorder to TRIG ONE2 and RLEN 1, and keeps
  each machine to its own sources (SMPL turns INAB / INCD to A B / C D when
  they are off).
- After a take, PROCESSING TAKE.. shows until the save starts (the check for
  sound, the normalize and the -1 dB gain; long takes take a while).
- CLEAR SLOT in the editor empties a saved take with one YES (stock first
  only disassociates it from its file); the file stays on the card.
- A take with no sound in it (nothing past -72 dBFS) shows NO SOUND IN TAKE
  and is neither normalized nor saved: check the source, its INAB / INCD, the
  cables. To hear the inputs without a THRU track, turn up DIR AB / DIR CD on
  the MIXER page.
- A take is limited by recorder memory (16 s by default; CONTROL > MEMORY).
