"""stock effects with ACCENT and PAGE LOOP: Heath's two grid-recording mods."""

from remix.schema import Proof, Remix

REMIX = Remix(
    name="accent-page-loop",
    family="mods", proof=Proof.CHECK, proof_note="",
    doc="stock effects with ACCENT and PAGE LOOP: soft/full steps and a looped page.",
    modules=("ACCENT", "PAGE LOOP",
             "FILTER", "EQUALIZER", "DJ EQ", "PHASER", "FLANGER",
             "CHORUS", "SPATIALIZER", "COMB FILTER", "COMPRESSOR", "LO-FI",
             "DELAY", "PLATE REV", "SPRING REV", "DARK REV"),
    fallback="NONE",
)
