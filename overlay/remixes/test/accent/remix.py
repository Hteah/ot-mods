"""stock effects with ACCENT: TR-style soft / full steps in GRID RECORDING."""

from remix.schema import Proof, Remix

REMIX = Remix(
    name="accent",
    family="mods", proof=Proof.CHECK, proof_note="",
    doc="stock effects with ACCENT: TR-style soft / full steps in GRID RECORDING.",
    modules=("ACCENT",
             "FILTER", "EQUALIZER", "DJ EQ", "PHASER", "FLANGER",
             "CHORUS", "SPATIALIZER", "COMB FILTER", "COMPRESSOR", "LO-FI",
             "DELAY", "PLATE REV", "SPRING REV", "DARK REV"),
    fallback="NONE",
)
