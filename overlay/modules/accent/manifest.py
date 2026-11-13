"""ACCENT -- TR-909-style soft / full steps in GRID RECORDING (audio tracks).

A tap on a trig key cycles the step off -> FULL -> SOFT -> off. A soft step
is an ordinary sample trig with an AMP VOL lock at PartVOL/sqrt 2 (-6 dB
under AMP VOL's (v/127)^2 law), so it saves, copies and undoes as any lock
does. Its red trig LED shows at level 5 (dim) instead of 15. Any trig
locked quieter than the track's Part VOL reads as soft.

TRACK + CUE (a TRACK key held, then CUE) toggles ACCENT with a toast,
ACCENT ON / ACCENT OFF; it starts ON at every boot. Stock cueing (CUE held,
then TRACK) is untouched.

Three detours (accent.s):
  0x40034e5e  grid painter (0x40034bd4), between the colour pass and the
              level pass: dim the red level of soft steps.
  0x400601aa  trig-key release (0x4005fb44), audio path that removes a
              trig flagged at press: a full trig becomes soft instead.
  0x4004e978  CUE press: with a track key held (0x460fab40), toggle.

Sites read from the disassembly of 1.40C; behaviour measured under the
port by verify_accent (MKI panel). Run on an Octatrack MKI since ACCLOOP6 (25 Oct 2026), in every image through ACCLOOP32.
"""

from remix.schema import Category, Detour, Gate, Kind, Linked, Module, Proof

H = bytes.fromhex

MODULE = Module(
    name="accent",
    key="ACCENT",
    kind=Kind.CF_PATCH,
    category=Category.MACHINES,
    author="Hteah",
    author_url="https://github.com/Hteah",
    proof=Proof.PORT,
    proof_note="verify_accent: tap cycle, lock bytes (blob + battery mirror), "
               "LED levels, held-edit release, playback lane, under the port (MKI)",
    doc="GRID REC: tap cycles a step off / FULL / SOFT (AMP VOL lock at -6 dB); "
        "soft steps light dim red. TRACK + CUE toggles it.",
    linked=(Linked("acc", "modules/accent/accent.s", dram=True),),
    detours=(
        Detour(0x40034e5e, H("428245f9400135b0"), "acc", "acc_led",
               "grid painter: dim the red LED of soft steps", pad_to=8),
        Detour(0x400601aa, H("207946c82456"), "acc", "acc_tap",
               "trig release: a full trig turns soft instead of off"),
        Detour(0x4004e978, H("700123c0460d168c"), "acc", "acc_cue",
               "CUE press: with a TRACK key held, toggle ACCENT (toast)", pad_to=8),
    ),
    gates=(Gate("tools/verify/verify_accent.py", venv=True, stage="image"),),
)
