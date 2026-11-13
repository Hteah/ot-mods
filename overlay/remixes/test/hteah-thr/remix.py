"""stock effects with ACCENT, PAGE LOOP and SMPL: Heath's three mods + REC THRESHOLD."""

from remix.schema import Proof, Remix

REMIX = Remix(
    name="hteah-thr",
    family="mods", proof=Proof.CHECK, proof_note="",
    doc="hteah-mods plus REC THRESHOLD, MUTE MODES, TAPE ECHO (SPRING REV's slot), MINIVERB (DARK REV's slot), ATA WRITE GUARD.",
    modules=("ACCENT", "PAGE LOOP", "SMPL", "REC THRESHOLD", "TRACK TRIG MODE", "TRIG MUTE", "MUTE_MODES", "ATA WRITE GUARD",
             "FILTER", "EQUALIZER", "DJ EQ", "PHASER", "FLANGER",
             "CHORUS", "SPATIALIZER", "COMB FILTER", "COMPRESSOR", "LO-FI",
             "DELAY", "PLATE REV", "TAPE ECHO", "MINIVERB"),
    fallback="NONE",
)
