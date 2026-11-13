"""SMPL / RSMP -- two sampler machines: a track that records into its own
recorder buffer and plays it as a Flex sample.

SMPL records the inputs (A/B or C/D), RSMP the internal source (the stock
SRC3 setting: MAIN, CUE or a track). Choosing either from the machine list
(double-tap TRACK, or FUNC + SRC / SRC SETUP) makes the track FLEX with a
signature in the Part, points its FLEX slot at the track's own recorder
buffer and sets the recorder's TRIG to ONE2 (press again to stop) and RLEN 1. SMPL / RSMP take on the red key only (tap in, tap out); recorder trigs
on them start nothing. The
stock FLEX page and engine play it. A take opens the audio editor on its
buffer and is saved to the card as a new file (R<n>-YYMMDD-HHMM, BUFFER
SAVER's chain) in the set's AUDIO/SMPL folder, made by the first take, once
the recorder is idle again.

LOOPER / RELOOPER are SMPL / RSMP without the auto-save: the take is not
scanned, normalized or saved; it stays in the buffer for live looping. The
editor's SAVE SAMPLE COPY / SAVE AND ASSIGN on one writes it to AUDIO/SMPL
under the keyboard's name (-2 .. while taken). They also take on a recorder
trig: RLEN counts loops, one take per run until the sequencer stops.

The machine-list code is Tim Hastie's v2.15 machine.s (MIT) as CX OSC
carries it (modules/smpl/NOTICE): the stock list was written for five
machines, so its counts, bounds, names and commits are detoured; the
descriptor table's two spare slots hold the two rows. It owns the same
list sites as CX OSC, SYNTH MACHINE, ANALOG BD and OCTA303.

Sites read from the disassembly of 1.40C and from CX OSC's manifest
(MKII-tested there); behaviour measured under the port by verify_smpl (MKI
panel). Run on an Octatrack MKI, Oct-Nov 2026 (ACCLOOP2-32; all four machines hardware-checked on ACCLOOP32).
"""

from remix.schema import Category, Detour, Gate, Kind, Linked, Module, Proof, SymbolRef

H = bytes.fromhex
CLAMPS = (0x40078c22, 0x40078cb0, 0x40078d2e, 0x40078dee, 0x40078e7c)

MODULE = Module(
    name="smpl",
    key="SMPL",
    kind=Kind.CF_PATCH,
    category=Category.MACHINES,
    author="Hteah",
    author_url="https://github.com/Hteah",
    proof=Proof.PORT,
    proof_note="verify_smpl: both rows chosen from the machine list, one-button takes (A/B on "
               "SMPL, internal on RSMP), recorder trigs ignored on SMPL / RSMP and taking RLEN loops as one take on LOOPER, each SMPL take saved with the editor open, stock tracks untouched, "
               "under the port (MKI)",
    doc="SAMPLER / RESAMPLE machines: a track that samples into its own buffer and plays it as Flex; a red-key take opens the editor and is saved to the card (recorder trigs ignored). LOOPER / RELOOPER: the same without the auto-save and normalize, plus recorder-trig takes of RLEN loops (a take stays in the buffer; the editor's SAVE goes to AUDIO/SMPL).",
    linked=(Linked("smpl", "modules/smpl/machine.s", dram=True),),
    detours=(
        Detour(0x40079816, H("d1fc0008eda27710"), "smpl", "sm_main_commit",
               "machine window commit: SMPL / RSMP rows -> FLEX + signature", pad_to=8),
        Detour(0x4005a616, H("2239460d5c30"), "smpl", "fm_src_commit", "SRC SETUP commit"),
        Detour(0x4005a850, H("2239460d5c30"), "smpl", "fm_src_commit2", "SRC SETUP commit, path 2"),
        Detour(0x400334d8, H("2f02222f0008"), "smpl", "fm_machine_name", "machine-name formatter"),
        Detour(0x4006de34, H("2f02242f0008"), "smpl", "sm_edopen",
               "audio editor (re)point: stays on a take that is still recording"),
        Detour(0x4006e160, H("4feffff048d71c04"), "smpl", "sm_edwin",
               "audio editor window open: on the take while one is recording", pad_to=8),
        Detour(0x4003c928, H("4bf9400a78c8"), "smpl", "fm_src_names",
               "SRC SETUP name table (lea -> our table)", kind="lea"),
        Detour(0x4003d718, H("41f9400a78c8"), "smpl", "fm_name_a", "track machine name"),
        Detour(0x4003c980, H("71104fef0018"), "smpl", "fm_setup_row", "SRC SETUP row highlight"),
        Detour(0x400786c8, H("7110b480662e"), "smpl", "fm_chooser_row", "chooser row highlight", pad_to=6),
        Detour(0x400585dc, H("161079034879400bb704"), "smpl", "fm_setup_open", "SRC SETUP open", pad_to=10),
        Detour(0x4003c8ca, H("41f9400d5f3841f06c00"), "smpl", "sm_pbd1",
               "SRC SETUP drawer's PLAYBACK descriptor by row: FLEX's for our rows (no spare slot past 6)",
               pad_to=10),
        Detour(0x4003d134, H("41f9400d5f382f301c00"), "smpl", "sm_pbd2",
               "SRC SETUP's PLAYBACK descriptor push by row: FLEX's for our rows", pad_to=10),
        Detour(0x40077b82, H("2f39460e738e"), "smpl", "sm_title",
               "machine window title over the slot list: SMPL / RSMP"),
        Detour(0x4003a52e, H("2002e788d4829082"), "smpl", "fm_setup_edit6", "SRC SETUP editor row*6", pad_to=8),
        Detour(0x4003cd98, H("2e06e78fdc869e86"), "smpl", "fm_setup_draw6", "SRC SETUP drawer row*6", pad_to=8),
        Detour(0x4005221e, H("4ebaff1c4eb94007e940"), "smpl", "fm_tick",
               "UI tick: name table and descriptor slots 5, 6", pad_to=10),
        Detour(0x40079248, H("4878000548780006"), "smpl", "ml_win_count", "machine window row count", pad_to=8),
        Detour(0x400585fa, H("4878000548780005"), "smpl", "ml_src_count", "SRC SETUP row count", pad_to=8),
        Detour(0x4003c950, H("7204b2826504"), "smpl", "ml_name_bound", "SRC SETUP name bound"),
        Detour(0x40078678, H("7004b0826d242f0220434e90"), "smpl", "ml_draw_bound",
               "chooser draw bound", pad_to=12),
        Detour(0x400786ce, H("7004b0826d28"), "smpl", "ml_hi_bound", "chooser highlight bound"),
        Detour(0x40079904, H("7604b6846c00fec2"), "smpl", "ml_cur_bound", "chooser cursor bound", pad_to=8),
        *[Detour(a, H("7205b2806c027005"), "smpl", f"ml_clamp{i + 1}", "chooser row clamp", pad_to=8)
          for i, a in enumerate(CLAMPS)],
        Detour(0x40030f2e, H("23c0460d10d0"), "smpl", "sm_ab_on",
               "A/B press: on an RSMP track the internal flag"),
        Detour(0x40030f08, H("42b9460d10d0"), "smpl", "sm_ab_off", "A/B release: what the press set"),
        Detour(0x40030d4c, H("23c0460d10d4"), "smpl", "sm_cd_on",
               "C/D press: on an RSMP track the internal flag"),
        Detour(0x40030cfc, H("42b9460d10d4"), "smpl", "sm_cd_off", "C/D release: what the press set"),
        Detour(0x40083756, H("4ab9800000c46710"), "smpl", "sm_quick",
               "manual sampling's quick-mode test: an SMPL / RSMP current track is one button", pad_to=8),
        Detour(0x400069E4, H("7e0215470002"), "smpl", "sm_arm",
               "recorder take start: an SMPL / RSMP run opens the editor and is saved when it ends"),
        Detour(0x4000CAE2, H("4eb9400208d4"), "smpl", "sm_pub",
               "per-frame recorder setup publish: RLEN MAX for our tracks", kind="jsr"),
        Detour(0x4000D356, H("2f012f034e94508f"), "smpl", "sm_disp",
               "recorder dispatcher's arm call: recorder trigs ignored on SMPL / RSMP; LOOPER / RELOOPER trig takes record RLEN loops as one take", pad_to=8),
        Detour(0x40000C3C, H("2f0a226f0008"), "smpl", "sm_post",
               "queue post: an audio-editor edit on a take's buffer that is still saving is not posted"),
        Detour(0x40021D0A, H("2f014eb94002557c"), "smpl", "sm_clear",
               "CLEAR RECORDING's clear: refused on a take's buffer that is still saving", pad_to=8),
        Detour(0x40021D66, H("2f014eb940025188"), "smpl", "sm_unlink",
               "DISASSOCIATE's unlink: refused on a take's buffer that is still saving", pad_to=8),
        Detour(0x40005F66, H("73b9100b14cc"), "smpl", "sm_recpos",
               "a recording buffer's recorded length: that buffer's recorder, not the current track's"),
        Detour(0x4007717A, H("0c8000004e206306203c00004e20"), "smpl", "sm_zfit",
               "audio editor zoom to fit: a recording may be zoomed out past 20,000 frames a pixel (42 s)"),
        Detour(0x400770D6, H("0c8100004e206f06223c00004e20"), "smpl", "sm_zenc",
               "audio editor zoom encoder: the same cap on a recording"),
        Detour(0x4006F456, H("e8a34c430800"), "smpl", "sm_ovd1",
               "editor overview bar: past 131,072 frames a pixel stock divides by length >> 14; never by 0"),
        Detour(0x40071244, H("e8a34c430800"), "smpl", "sm_ovd2",
               "the same overview divide in the second editor view"),
        Detour(0x40073E22, H("e8ab4c430000"), "smpl", "sm_ovd3",
               "the same overview divide in the third editor view (unsigned)"),
        Detour(0x40021060, H("4df9400166b8"), "smpl", "sm_wfast",
               "WAV writer's audio blocks: a file write that copies a block at a time, not a byte"),
        Detour(0x40021070, H("4eb94009499c"), "smpl", "sm_wtap",
               "WAV writer's page walk: the frame a take's save is on, for SAVING TAKE %", kind="jsr"),
        Detour(0x400242D2, H("4ab9800000a4670a4eb940024eec4a806622"), "smpl", "sm_cfm",
               "naming keyboard confirm, pool or project: an edited take goes to AUDIO/SMPL as <name>-2 ..", pad_to=18),
        Detour(0x400241A6, H("4ab9800000a4670a4eb940024eec4a806620"), "smpl", "sm_svp",
               "sample save, pool or project: a SMPL/ name is always the pool's", pad_to=18),
        Detour(0x40023F82, H("4ab9800000a4670a4eb940024eec4a80660a"), "smpl", "sm_asp",
               "sample assignment, pool or project: a SMPL/ name is always the pool's", pad_to=18),
        Detour(0x40076DFC, H("4878000648780006"), "smpl", "sm_ft_count",
               "audio editor FILE page, list init on a recording: 7 rows (TRASH TAKE) on a SAMPLER take", pad_to=8),
        Detour(0x40076EFC, H("41f9400b2d92"), "smpl", "sm_ft_table",
               "audio editor FILE page dispatch on a recording (lea -> stock six + TRASH TAKE)", kind="lea"),
        Detour(0x4000D0A4, H("202f00847209"), "smpl", "sm_envgate",
               "frame, before the stop mask: a SAMPLER that monitors keeps its AMP envelope open (trig once, HOLD 127, out of the stop mask)"),
        Detour(0x4000D43A, H("2f0320534e90"), "smpl", "sm_mcall1",
               "voice loop, a track's first render call: a SAMPLER take plays its inputs through the track"),
        Detour(0x4000D52C, H("4e901012780f"), "smpl", "sm_mcall2",
               "voice loop, a track's second render call: the same"),
        Detour(0x40021BC8, H("4e56fff82f02"), "smpl", "sm_cldlg",
               "CLEAR SLOT's dialog on a recording: not opened on a take's buffer that is still saving"),
    ),
    conflicts=(
        ("CX OSC", "both own the machine list rows after PICKUP"),
        ("SYNTH MACHINE", "both own the machine list rows after PICKUP"),
        ("ANALOG BD", "both own the machine list rows after PICKUP"),
        ("OCTA303", "both own the machine list rows after PICKUP"),
        ("BUFFER SAVER", "both hook the recorder's take start and save the recorder buffers"),
        ("PERSISTENT BUFFERS", "both save the recorder buffers to the card"),
    ),
    symbol_refs=(SymbolRef(0x40076A30, 0x400B2D92, "smpl", "sm_ft_table",
                           "audio editor FILE page draw on a recording: `movel #table,%d3`'s operand"),),
    gates=(Gate("tools/verify/verify_smpl.py", venv=True, stage="image"),),
)
