"""stock effects with SMPL and RSMP: sampler machines."""

from remix.schema import Proof, Remix

REMIX = Remix(
    name="smpl",
    family="mods", proof=Proof.CHECK, proof_note="",
    doc="stock effects with SMPL and RSMP: two sampler machines on their own buffers.",
    modules=("SMPL",
             "FILTER", "EQUALIZER", "DJ EQ", "PHASER", "FLANGER",
             "CHORUS", "SPATIALIZER", "COMB FILTER", "COMPRESSOR", "LO-FI",
             "DELAY", "PLATE REV", "SPRING REV", "DARK REV"),
    fallback="NONE",
)
