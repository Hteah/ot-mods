"""stock effects with ACCENT, PAGE LOOP and SMPL: Heath's three mods."""

from remix.schema import Proof, Remix

REMIX = Remix(
    name="hteah-mods",
    family="mods", proof=Proof.CHECK, proof_note="",
    doc="stock effects with ACCENT, PAGE LOOP and SMPL: soft/full steps, a looped page, sampler machines.",
    modules=("ACCENT", "PAGE LOOP", "SMPL",
             "FILTER", "EQUALIZER", "DJ EQ", "PHASER", "FLANGER",
             "CHORUS", "SPATIALIZER", "COMB FILTER", "COMPRESSOR", "LO-FI",
             "DELAY", "PLATE REV", "SPRING REV", "DARK REV"),
    fallback="NONE",
)
