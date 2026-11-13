# Brief for an AI coding agent

You're working on Octatrack MKI firmware mods built with
[octabam](https://github.com/sambanks/octabam). This repo holds five modules
(`overlay/modules/{smpl,accent,page-loop,track-trig-mode,trig-mute}`), two
remixes (`overlay/remixes/test/hteah-thr` = full, `overlay/remixes/samplers`)
and an installer.

Before you change anything:

1. Read `BUILDING.md` here, then octabam's `AGENTS.md`,
   `docs/contributing/MODULES.md` and `docs/contributing/TRAPS.md`.
2. Clone octabam at `OCTABAM_COMMIT` **in a git worktree**, copy `overlay/` on
   top, and get `make check REMIX=hteah-thr` (and `REMIX=samplers`) passing. (`install.sh` does the
   clone, setup, OS download and image build. Read it first.)
3. Explain the design back to the user before you edit it.

Rules:

- **Never commit or share an Elektron byte**: no built image, `.syx`, dump or
  slice. The build reads the user's own 1.40C.
- A detour or claim isn't true until it's measured under the port. Static
  reads mislead, so write-watch the RAM word before you design on it.
- Every behaviour change gets a gate in that mod's `overlay/tools/verify/verify_<mod>.py`.
  Show it fails on the old code, then make it pass.
- Never call something working because it assembled, linked or passed the
  port. Hardware is the last word: give the user a short checklist with each
  image, bump `BUILD`/`VERSION` every flash, and record what they report.
- Keep `overlay/` in sync with the octabam tree you tested, and keep the
  user-facing page in `mods/` in step with any behaviour change.
