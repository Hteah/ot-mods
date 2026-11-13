"""stock effects with SAMPLER, RESAMPLE, LOOPER and RELOOPER: four sampler machines."""

from remix.schema import Proof, Remix

REMIX = Remix(
    name="samplers",
    family="mods", proof=Proof.CHECK, proof_note="",
    doc="stock effects with the SMPL module's four sampler machines (SAMPLER, RESAMPLE, LOOPER, RELOOPER) + REC THRESHOLD + ATA WRITE GUARD.",
    modules=("SMPL", "REC THRESHOLD", "ATA WRITE GUARD",
             "FILTER", "EQUALIZER", "DJ EQ", "PHASER", "FLANGER",
             "CHORUS", "SPATIALIZER", "COMB FILTER", "COMPRESSOR", "LO-FI",
             "DELAY", "PLATE REV", "SPRING REV", "DARK REV"),
    fallback="NONE",
)
