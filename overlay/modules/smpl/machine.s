| SMPL / RSMP / LOOPER / RELOOPER -- four machine-list rows (the sixth to ninth, after the
| stock five). LOOPER / RELOOPER (Heath, 7 Nov 2026) are SMPL / RSMP whose takes stay in the
| buffer: no scan, normalize or auto-save (sm_isloop, the row's F_LOOP flag).
| GNU as, -mcpu=5475; DRAM unit (modules/smpl/manifest.py, Linked "smpl").
| The list code is Tim Hastie's v2.15 machine.s (timhastie/octatrick-modules
| 17ba281, MIT), itself adapted from Modwerk's FM Synth (repeat98/modwerk @
| 1c1d938, MIT), as CX OSC carries it (modules/cxosc/machine.s); see
| modules/smpl/NOTICE. Kept: the names, the row counts and bounds, the
| highlight, the window opens and commits, SRC SETUP's rows and the tick that
| fills the tables. Left out: the synth engine, its page, the selection
| guard, the paste guards and the machine-change init.
|
| THE ROWS. A row descriptor (20 bytes): +0 signature (3 B), +3 kind (1 SMPL,
| 2 RSMP), +4 name, +8 unused, +12 its PLAYBACK descriptor routine, +16 flags.
| Both rows are FLEX tracks: the stock FLEX PLAYBACK page and engine play them.
|
| THE STORAGE. A chosen track = FLEX (machine byte 1) with the signature in the
| NEIGHBOR PLAYBACK column's first three bytes (Part + 0x8edbc + 30 * track, and the
| battery-RAM shadow): "SM", 1 or "RS", 1 (the third byte as CX OSC's "CX", 1, which
| survives the load validator on hardware). Choosing either row also points the FLEX
| slot at the track's own recorder buffer (0x80 + track) and sets the recorder's TRIG
| to ONE2 (press again to stop) and RLEN to 1: on LOOPER / RELOOPER RLEN counts a trig
| take's loops (Part 3); SAMPLER / RESAMPLE ignore recorder trigs; a key take is free. SMPL turns SRC3 off and INAB / INCD to A B / C D
| when they are "-"; RSMP turns INAB and
| INCD off and SRC3 to MAIN when it is "-": a recorder trig samples every source the
| recorder has, so each machine keeps only its own. Choosing a stock row clears the
| signature; the recorder settings stay as they are.

        .text
        .global fm_machine_name, fm_name_a, fm_src_names
        .global fm_setup_row, fm_chooser_row, fm_setup_open, sm_title
        .global fm_setup_edit6, fm_setup_draw6
        .global sm_main_commit, fm_src_commit, fm_src_commit2, fm_tick
        .global ml_win_count, ml_src_count, ml_name_bound, ml_draw_bound, ml_hi_bound, ml_cur_bound
        .global ml_clamp1, ml_clamp2, ml_clamp3, ml_clamp4, ml_clamp5
        .global sm_kind, ml_rows

        .set    FM_ROW, 5                | the sixth row, the first after the stock five: SMPL
        .set    ML_COUNT, 4              | SAMPLER, RESAMPLE, LOOPER, RELOOPER
        .set    PB_SPARE, 2              | the PLAYBACK descriptor table's spare slots (5, 6) we fill;
                                         | slot 7 is 0 and slot 8 is FX1's id table (0x400d5f58), so
                                         | rows 7, 8 have none: every reader indexed by a row reads
                                         | FLEX's for a row from 5 (fm_setup_edit6, fm_setup_open,
                                         | sm_pbd1, sm_pbd2)
        .set    ML_LAST, 4 + ML_COUNT    | the last row's index
        .set    RD_KIND, 3
        .set    RD_NAME, 4
        .set    RD_DESC, 12
        .set    RD_FLAGS, 16
        .set    F_LOOP, 1                | LOOPER / RELOOPER: no auto-save, no normalize
        .set    FLEX, 1
        .set    K_SMPL, 1
        .set    K_RSMP, 2
        .set    PART_PTR, 0x46c82456     | the bank blob; the Part = blob + part index * 6322
        .set    PART_IDX, 0x100b14cf     | the current Part's index
        .set    PART_SHADOW, 0x1001614e  | the bank's mirror in battery RAM
        .set    MACH_OFF, 0x8eda2        | + track: the machine byte
        .set    SIG_OFF, 0x8edbc         | + 30 * track: the signature's place
        .set    SLOT_FLEX, 0x8f04b       | + 5 * track: the FLEX column's slot byte (0x80 + n: recorder buffer n + 1)
        .set    REC_OFF, 0x8f382         | + 12 * track: the recorder's setup (INAB INCD RLEN TRIG SRC3 LOOP ...)
        .set    R_INAB, 0                | - 0, A B 1, A 2, B 3, A+B 4
        .set    R_INCD, 1
        .set    R_RLEN, 2                | raw: steps - 1, 64 = MAX
        .set    R_TRIG, 3                | ONE 0, ONE2 1, HOLD 2
        .set    RLEN_MAX, 64
        .set    R_SRC3, 4                | - 0, T1..T8 1..8, MAIN 9, CUE 10 (PARAM_PAGES.md, hw-confirmed)
        .set    ONE2, 1
        .set    MAIN, 9                  | was 1 = T1 (ACCLOOP2-4): the decoded LCD showed SRC3 T1
        .set    SRC_CURSOR, 0x460d5c30   | SRC SETUP's machine row
        .set    NAMES, 0x400a78c8        | the stock machine-name table, five pointers (STATIC .. PICKUP)
        .set    PB_TABLE, 0x400d5f38     | the machine -> PLAYBACK descriptor table (slots 5, 6: spares)
        .set    NAME_RET, 0x400334de
        .set    NAME_A_RET, 0x4003d722
        .set    SETUP_ROW_RET, 0x4003c986
        .set    CHOOSER_HIT, 0x400786ce
        .set    CHOOSER_MISS, 0x400786fc
        .set    SETUP_OPEN_RET, 0x400585e6
        .set    EDIT6_RET, 0x4003a536
        .set    DRAW6_RET, 0x4003cda0
        .set    SRC_COMMIT_RET, 0x4005a61c
        .set    SRC_COMMIT2_RET, 0x4005a856
        .set    MACHWIN_RET, 0x4007981e
        .set    TICK_A, 0x4005213c
        .set    TICK_B, 0x4007e940
        .set    TICK_RET, 0x40052228
        .set    WIN_COUNT_RET, 0x40079250
        .set    SRC_COUNT_RET, 0x40058602
        .set    NAME_BOUND_IN, 0x4003c956
        .set    NAME_BOUND_OUT, 0x4003c95a
        .set    DRAW_BOUND_IN, 0x40078684
        .set    DRAW_BOUND_OUT, 0x400786a2
        .set    WIN_LIST, 0x460e7386     | SELECT MACHINE TYPE's list: +0 top row
        .set    WIN_ROW, 0x460e738e      | ... +8 its row (the machine the window is on)
        .set    WIN_FOCUS, 0x460e739a    | the window's column: 1 the slot list, 0 the machines
        .set    TITLE_RET, 0x40077b88
        .set    CUR_TRACK, 0x100b14cc    | the current track
        .set    HI_BOUND_IN, 0x400786d4
        .set    CUR_BOUND_IN, 0x400797cc
        .set    CUR_BOUND_OUT, 0x4007990c

| ---- sm_choose: d1 = the chosen row, d2 = the track (the current Part) -> d1 = the
| machine byte to store. One of ours -> FLEX, its signature written into the Part and
| its shadow, and its init (sm_init); a stock row: unchanged, our signature cleared.
| Preserves every other register.
sm_choose:
        lea     -20(%sp),%sp
        movem.l %d0/%a0-%a3,(%sp)
        bsr     ml_part                  | a0 = the Part
        move.l  %a0,%d0
        sub.l   PART_PTR,%d0
        lea     PART_SHADOW,%a1
        adda.l  %d0,%a1                  | a1 = its shadow
        move.l  %d2,%d0
        mulu.w  #30,%d0
        adda.l  %d0,%a0
        adda.l  %d0,%a1
        movea.l %a0,%a2
        adda.l  #SIG_OFF,%a2             | a2 = the signature in the Part
        movea.l %a1,%a3
        adda.l  #SIG_OFF,%a3             | a3 = ... in the shadow
        move.l  %d1,%d0
        subq.l  #FM_ROW,%d0
        cmpi.l  #ML_COUNT,%d0
        bcc     sm_ch_stock              | (unsigned) a stock row
        lea     ml_rows(%pc),%a0
        movea.l (%a0,%d0.l*4),%a0        | a0 = the row's descriptor
        move.b  (%a0),(%a2)
        move.b  1(%a0),1(%a2)
        move.b  2(%a0),2(%a2)
        move.b  (%a0),(%a3)
        move.b  1(%a0),1(%a3)
        move.b  2(%a0),2(%a3)
        mvz.b   RD_KIND(%a0),%d0
        bsr     sm_init
        moveq   #FLEX,%d1                | stored as FLEX
        bra     sm_ch_out
sm_ch_stock:
        movea.l %a2,%a0
        bsr     fm_unsign
        movea.l %a3,%a0
        bsr     fm_unsign
sm_ch_out:
        movem.l (%sp),%d0/%a0-%a3
        lea     20(%sp),%sp
        rts

| sm_init: d0 = the kind (K_SMPL / K_RSMP), d2 = the track of the current Part. The
| FLEX slot := the track's own recorder buffer, TRIG := ONE2; SMPL: INAB / INCD := A B /
| C D when "-"; RSMP: SRC3 := MAIN when it is "-". Part and shadow. Preserves every register.
sm_init:
        lea     -20(%sp),%sp
        movem.l %d0-%d1/%a0-%a2,(%sp)
        move.l  %d0,%d1                  | the kind
        bsr     ml_part
        move.l  %a0,%d0
        sub.l   PART_PTR,%d0
        lea     PART_SHADOW,%a1
        adda.l  %d0,%a1                  | the shadow
        move.l  %d2,%d0
        mulu.w  #5,%d0
        addi.l  #SLOT_FLEX,%d0
        move.l  %d2,-(%sp)
        addi.l  #0x80,%d2                | recorder buffer track + 1
        move.b  %d2,(%a0,%d0.l)
        move.b  %d2,(%a1,%d0.l)
        move.l  (%sp)+,%d2
        move.l  %d2,%d0
        mulu.w  #12,%d0
        addi.l  #REC_OFF,%d0
        lea     (%a0,%d0.l),%a2          | the recorder setup in the Part
        adda.l  %d0,%a1                  | ... in the shadow
        move.b  #ONE2,R_TRIG(%a2)
        move.b  #ONE2,R_TRIG(%a1)
        clr.b   R_RLEN(%a2)              | RLEN counts a trig take's loops here: 1 loop
        clr.b   R_RLEN(%a1)              | (a key take is free whatever RLEN says; sm_disp)
        cmpi.l  #K_RSMP,%d1
        beq     sm_in_rsmp
        clr.b   R_SRC3(%a2)              | SMPL: the inputs only (a recorder trig samples
        clr.b   R_SRC3(%a1)              | every source the recorder has: SRC3 "-")
        tst.b   R_INAB(%a2)              | INAB "-" (an RSMP track before): A B, or the
        bne     sm_in_cd                 | A/B key records nothing (ACCLOOP18, 31 Oct)
        move.b  #1,R_INAB(%a2)
        move.b  #1,R_INAB(%a1)
sm_in_cd:
        tst.b   R_INCD(%a2)              | INCD "-": C D
        bne     sm_in_out
        move.b  #1,R_INCD(%a2)
        move.b  #1,R_INCD(%a1)
        bra     sm_in_out
sm_in_rsmp:
        clr.b   R_INAB(%a2)              | RSMP: the internal source only (INAB, INCD "-")
        clr.b   R_INAB(%a1)
        clr.b   R_INCD(%a2)
        clr.b   R_INCD(%a1)
        tst.b   R_SRC3(%a2)
        bne     sm_in_out                | a source already: the user's
        move.b  #MAIN,R_SRC3(%a2)
        move.b  #MAIN,R_SRC3(%a1)
sm_in_out:
        movem.l (%sp),%d0-%d1/%a0-%a2
        lea     20(%sp),%sp
        rts

| ml_part: a0 := the current Part (the bank blob + part * 6322). Preserves every other register.
ml_part:
        move.l  %d0,-(%sp)
        mvz.b   PART_IDX,%d0
        mulu.w  #6322,%d0
        movea.l PART_PTR,%a0
        adda.l  %d0,%a0
        move.l  (%sp)+,%d0
        rts

| ml_sigrow: a0 = a signature's place -> d0 = the index in ml_rows of the row whose
| signature it holds, else -1; tst.l done (bmi: none). Preserves every other register.
ml_sigrow:
        lea     -8(%sp),%sp
        movem.l %d1/%a1,(%sp)
        moveq   #0,%d0
ml_sr_row:
        lea     ml_rows(%pc),%a1
        movea.l (%a1,%d0.l*4),%a1
        mvz.b   (%a0),%d1
        cmp.b   (%a1),%d1
        bne     ml_sr_next
        mvz.b   1(%a0),%d1
        cmp.b   1(%a1),%d1
        bne     ml_sr_next
        mvz.b   2(%a0),%d1
        cmp.b   2(%a1),%d1
        beq     ml_sr_out
ml_sr_next:
        addq.l  #1,%d0
        cmpi.l  #ML_COUNT,%d0
        bne     ml_sr_row
        moveq   #-1,%d0
ml_sr_out:
        movem.l (%sp),%d1/%a1
        lea     8(%sp),%sp
        tst.l   %d0
        rts
| fm_unsign: a0 = a signature's place -> cleared when it holds one of our signatures (d0 clobbered)
fm_unsign:
        bsr     ml_sigrow
        bmi     fm_us_out
        clr.b   (%a0)
        clr.b   1(%a0)
        clr.b   2(%a0)
fm_us_out:
        rts

| sm_kind: d2 = a track of the current Part -> d0 = K_SMPL / K_RSMP when it is FLEX
| with one of our signatures, else 0; tst.l done. LOOPER is K_SMPL and RELOOPER K_RSMP
| (their source, monitoring and keys are SAMPLER's / RESAMPLE's); sm_isloop tells them
| apart. Preserves every other register (the record hooks, record.s).
sm_kind:
        bsr     sm_rowidx
        bmi     sm_k_none
        move.l  %a0,-(%sp)
        lea     ml_rows(%pc),%a0
        movea.l (%a0,%d0.l*4),%a0
        mvz.b   RD_KIND(%a0),%d0
        movea.l (%sp)+,%a0
        tst.l   %d0
        rts
sm_k_none:
        moveq   #0,%d0
        rts

| sm_isloop: d2 = a track of the current Part -> d0 = 1 (Z clear) when it is LOOPER or
| RELOOPER, else 0. Preserves every other register.
sm_isloop:
        bsr     sm_rowidx
        bmi     sm_k_none
        move.l  %a0,-(%sp)
        lea     ml_rows(%pc),%a0
        movea.l (%a0,%d0.l*4),%a0
        mvz.b   RD_FLAGS(%a0),%d0
        movea.l (%sp)+,%a0
        andi.l  #F_LOOP,%d0
        rts

| sm_rowidx: d2 = a track of the current Part -> d0 = its row's index in ml_rows when it
| is FLEX with one of our signatures, else -1; tst.l done. Preserves every other register.
sm_rowidx:
        move.l  %a0,-(%sp)
        bsr     ml_part
        move.l  %d2,%d0
        addi.l  #MACH_OFF,%d0
        mvz.b   (%a0,%d0.l),%d0
        cmpi.l  #FLEX,%d0
        bne     sm_ri_none
        move.l  %d2,%d0
        mulu.w  #30,%d0
        adda.l  %d0,%a0
        adda.l  #SIG_OFF,%a0
        bsr     ml_sigrow
        bra     sm_ri_out
sm_ri_none:
        moveq   #-1,%d0
sm_ri_out:
        movea.l (%sp)+,%a0
        tst.l   %d0
        rts

| ---- 0x40079816 (jmp, 8 B): the machine window's machine-byte write (FUNC + SRC, YES).
| d1 = the track, d4 = the chosen row, a0 = blob + part * 6322 + track. The row becomes
| the machine byte to store (sm_choose); the displaced `addal #0x8eda2,%a0; mvsb
| %a0@,%d3` is replayed and stock stores d4 into the Part and its shadow.
| An SMPL / RSMP track opens this window as FLEX (its slot list: the recorder buffers),
| so a YES in the slot list (WIN_FOCUS 1) with the FLEX row keeps the track's machine;
| only a choice in the machine column changes it.
sm_main_commit:
        move.l  %d2,-(%sp)
        move.l  %d1,-(%sp)
        move.l  %d1,%d2                  | the track
        cmpi.l  #FLEX,%d4
        bne     sm_mc_choose
        moveq   #1,%d1
        cmp.l   WIN_FOCUS,%d1
        bne     sm_mc_choose             | the machine column: a choice
        move.l  %d0,-(%sp)
        bsr     sm_kind
        move.l  %d0,%d1                  | (d1 is reloaded below)
        move.l  (%sp)+,%d0
        tst.l   %d1
        bne     sm_mc_keep               | ours, from its slot list: it stays ours
sm_mc_choose:
        move.l  %d4,%d1                  | the row
        bsr     sm_choose
        move.l  %d1,%d4                  | the machine to store
sm_mc_keep:
        move.l  (%sp)+,%d1
        move.l  (%sp)+,%d2
        adda.l  #MACH_OFF,%a0            | displaced
        mvs.b   (%a0),%d3                | displaced: the old machine
        jmp     MACHWIN_RET

| ---- 0x4005a616 / 0x4005a850 (jmp, 6 B each): SRC SETUP's two machine-byte writes:
| displaced `movel 0x460d5c30,%d1` (the chosen row), then stock stores d1. d2 = the track.
fm_src_commit:
        move.l  SRC_CURSOR,%d1           | displaced
        bsr     sm_choose
        jmp     SRC_COMMIT_RET
fm_src_commit2:
        move.l  SRC_CURSOR,%d1           | displaced
        bsr     sm_choose
        jmp     SRC_COMMIT2_RET

| ---- fm_type: d0 = a machine read through a0 = a pointer to it -> d0 = 5 + the row's
| index when a0 is the current Part's machine byte of a track whose row is chosen (FLEX,
| signed), else d0 unchanged. Preserves every other register.
fm_type:
        cmpi.l  #FLEX,%d0
        bne     fm_ty_rts
        lea     -16(%sp),%sp
        movem.l %d1-%d2/%a0-%a1,(%sp)
        movea.l PART_PTR,%a1
        mvz.b   PART_IDX,%d1
        move.l  #6322,%d2
        muls.l  %d2,%d1
        adda.l  %d1,%a1                  | the Part
        move.l  %a0,%d2
        sub.l   %a1,%d2
        subi.l  #MACH_OFF,%d2            | the track, if a0 is one of its machine bytes
        moveq   #8,%d1
        cmp.l   %d1,%d2
        bhs     fm_ty_out                | (unsigned) another byte: unchanged
        mulu.w  #30,%d2
        movea.l %a1,%a0
        adda.l  %d2,%a0
        adda.l  #SIG_OFF,%a0
        bsr     ml_sigrow
        bmi     fm_ty_flex
        addq.l  #FM_ROW,%d0
        bra     fm_ty_out
fm_ty_flex:
        moveq   #FLEX,%d0
fm_ty_out:
        movem.l (%sp),%d1-%d2/%a0-%a1
        lea     16(%sp),%sp
fm_ty_rts:
        rts

| ---- 0x400334d8 (jmp, 6 B): the machine-name formatter name(row): rows 5.. -> their
| names; any other row replays the displaced `movel %d2,%sp@-; movel %sp@(8),%d1`.
fm_machine_name:
        move.l  4(%sp),%d0
        subq.l  #FM_ROW,%d0
        cmpi.l  #ML_COUNT,%d0
        bcs     fm_mn_row
        move.l  %d2,-(%sp)               | displaced
        move.l  8(%sp),%d1               | displaced
        jmp     NAME_RET
fm_mn_row:
        lea     ml_rows(%pc),%a0
        movea.l (%a0,%d0.l*4),%a0
        move.l  RD_NAME(%a0),%d0
        rts

| ---- 0x4003d718 (jmp, 6 B): a track's machine name, d0 = its machine, a0 = its machine
| byte; displaced `lea 0x400a78c8,%a0`, then d1 := the name (rejoins after the load).
fm_name_a:
        bsr     fm_type
        lea     NAMES,%a0                | displaced
        cmpi.l  #FM_ROW,%d0
        bge     fm_na_row
        move.l  (%a0,%d0.l*4),%d1
        jmp     NAME_A_RET
fm_na_row:
        lea     ml_rows-4*FM_ROW(%pc),%a0
        movea.l (%a0,%d0.l*4),%a0
        move.l  RD_NAME(%a0),%d1
        lea     NAMES,%a0
        jmp     NAME_A_RET

| ---- 0x4003c980 (jmp, 6 B): SRC SETUP's row highlight: displaced `mvsb %a0@,%d0; lea
| %sp@(24),%sp`; a signed track's row is its row.
fm_setup_row:
        mvs.b   (%a0),%d0
        lea     24(%sp),%sp
        bsr     fm_type
        jmp     SETUP_ROW_RET

| ---- 0x400786c8 (jmp, 6 B): the machine window's row highlight: displaced `mvsb
| %a0@,%d0; cmpl %d0,%d2; bnes 0x400786fc` (d2 = the visible row; the list row is d2 +
| its top).
fm_chooser_row:
        mvs.b   (%a0),%d0
        bsr     fm_type
        move.l  WIN_LIST,%d1
        add.l   %d2,%d1
        cmp.l   %d0,%d1
        bne     fm_cr_miss
        jmp     CHOOSER_HIT
fm_cr_miss:
        jmp     CHOOSER_MISS

| ---- 0x400585dc (jmp, 10 B): SRC SETUP opens on the track's row: displaced `moveb
| %a0@,%d3; mvsb %d3,%d4; pea 0x400bb704`.
fm_setup_open:
        move.b  (%a0),%d3
        move.l  %d0,-(%sp)
        mvs.b   %d3,%d0
        bsr     fm_type
        move.l  %d0,%d3
        move.l  (%sp)+,%d0
        mvs.b   %d3,%d4
        pea     (0x400bb704).l           | displaced
| then stock's `pea -1; lea 0x400d5f38,%a0; movel %a0@(0,%d4:l:4),%sp@-` (the row's PLAYBACK
| descriptor), FLEX's for a row from 5 (PB_SPARE), and on to its jsr
        pea     (-1).w
        lea     PB_TABLE,%a0
        cmpi.l  #FM_ROW,%d4
        bge     fm_so_ours
        move.l  (%a0,%d4.l*4),-(%sp)
        jmp     SETUP_OPEN_RET+14
fm_so_ours:
        move.l  4*FLEX(%a0),-(%sp)
        jmp     SETUP_OPEN_RET+14

| ---- 0x40077b82 (jmp, 6 B): the machine window's title over the slot list, displaced
| `movel 0x460e738e,%sp@-` (the window's row, for name(row)). The window opens on an
| SMPL / RSMP track as FLEX (no chooser-open detour: its slot list is FLEX's), so the
| FLEX row on one of ours is titled with its own name.
sm_title:
        move.l  WIN_ROW,%d0
        cmpi.l  #FLEX,%d0
        bne     sm_tt_push
        move.l  %d2,-(%sp)
        mvz.b   CUR_TRACK,%d2
        bsr     sm_rowidx
        move.l  (%sp)+,%d2
        tst.l   %d0
        bmi     sm_tt_flex
        addq.l  #FM_ROW,%d0              | its row: 5 + its index
        bra     sm_tt_push
sm_tt_flex:
        moveq   #FLEX,%d0
sm_tt_push:
        move.l  %d0,-(%sp)               | (the displaced push)
        jmp     TITLE_RET

| ---- 0x4003a52e / 0x4003cd98 (jmp, 8 B each): SRC SETUP's editor and drawer address
| the row's Part bytes at row * 6. Rows 5.. address FLEX's.
fm_setup_edit6:
        cmpi.l  #FM_ROW,%d2
        blt     fm_e6
        moveq   #FLEX,%d2
        movea.l PB_TABLE+4*FLEX,%a5      | the descriptor stock just read by row: FLEX's
fm_e6:
        move.l  %d2,%d0
        lsl.l   #3,%d0
        add.l   %d2,%d2
        sub.l   %d2,%d0
        jmp     EDIT6_RET
fm_setup_draw6:
        cmpi.l  #FM_ROW,%d6
        blt     fm_d6
        moveq   #FLEX,%d6
fm_d6:
        move.l  %d6,%d7
        lsl.l   #3,%d7
        add.l   %d6,%d6
        sub.l   %d6,%d7
        jmp     DRAW6_RET

| ---- 0x4005221e (jmp, 10 B): the UI tick: displaced `jsr 0x4005213c; jsr 0x4007e940`,
| replayed; then SRC SETUP's name table is filled from the stock one and the rows'
| names, and the PLAYBACK descriptor table's spare slots 5, 6 get the rows' pages.
fm_tick:
        jsr     TICK_A                   | displaced
        jsr     TICK_B                   | displaced
        lea     NAMES,%a0
        lea     fm_src_names(%pc),%a1
        moveq   #5,%d0
fm_tk_copy:
        move.l  (%a0)+,(%a1)+
        subq.l  #1,%d0
        bne     fm_tk_copy
        move.l  %a2,-(%sp)
        move.l  %d2,-(%sp)
        moveq   #0,%d2
fm_tk_row:
        lea     ml_rows(%pc),%a2
        movea.l (%a2,%d2.l*4),%a2
        move.l  RD_NAME(%a2),%d0
        lea     fm_src_names+4*FM_ROW(%pc),%a0
        move.l  %d0,(%a0,%d2.l*4)
        moveq   #PB_SPARE,%d0
        cmp.l   %d0,%d2
        bge     fm_tk_nopb               | no spare slot past 6 (PB_SPARE)
        movea.l RD_DESC(%a2),%a0
        jsr     (%a0)                    | d0 = its page
        lea     PB_TABLE+4*FM_ROW,%a0
        move.l  %d0,(%a0,%d2.l*4)
fm_tk_nopb:
        addq.l  #1,%d2
        cmpi.l  #ML_COUNT,%d2
        bne     fm_tk_row
        move.l  (%sp)+,%d2
        movea.l (%sp)+,%a2
        bsr     sm_auto
        jmp     TICK_RET
| ---- the SRC SETUP readers of the PLAYBACK descriptor table by its cursor row (0x460d5c30):
| a row from 5 reads FLEX's (PB_SPARE). 0x4003c8ca (jmp, 10 B): displaced `lea 0x400d5f38,%a0;
| lea %a0@(0,%d6:l:4),%a0`. 0x4003d134 (jmp, 10 B): displaced `lea 0x400d5f38,%a0; movel
| %a0@(0,%d1:l:4),%sp@-`.
        .global sm_pbd1, sm_pbd2
sm_pbd1:
        lea     PB_TABLE,%a0
        cmpi.l  #FM_ROW,%d6
        bge     sm_pd1_ours
        lea     (%a0,%d6.l*4),%a0
        jmp     0x4003c8d4
sm_pd1_ours:
        lea     4*FLEX(%a0),%a0
        jmp     0x4003c8d4
sm_pbd2:
        lea     PB_TABLE,%a0
        cmpi.l  #FM_ROW,%d1
        bge     sm_pd2_ours
        move.l  (%a0,%d1.l*4),-(%sp)
        jmp     0x4003d13e
sm_pd2_ours:
        move.l  4*FLEX(%a0),-(%sp)
        jmp     0x4003d13e

| sm_page: d0 := the stock FLEX PLAYBACK descriptor (every row plays as FLEX).
sm_page:
        move.l  PB_TABLE+4*FLEX,%d0
        rts

| ---- the row-count and row-bound sites: each does what the stock instruction did with
| 5 + ML_COUNT rows (the last row ML_LAST), and rejoins.
ml_win_count:
        pea     (5+ML_COUNT).w           | the rows
        pea     6.w                      | the rows visible (stock's)
        jmp     WIN_COUNT_RET
ml_src_count:
        pea     (5+ML_COUNT).w
        pea     6.w
        jmp     SRC_COUNT_RET
ml_name_bound:
        moveq   #ML_LAST,%d1
        cmp.l   %d2,%d1
        bcs     ml_nb_out
        jmp     NAME_BOUND_IN
ml_nb_out:
        jmp     NAME_BOUND_OUT
ml_draw_bound:
        move.l  WIN_LIST,%d0             | the top row
        add.l   %d2,%d0
        cmpi.l  #ML_LAST,%d0
        bgt     ml_db_out
        move.l  %d0,-(%sp)
        movea.l %d3,%a0
        jsr     (%a0)
        jmp     DRAW_BOUND_IN
ml_db_out:
        jmp     DRAW_BOUND_OUT
ml_hi_bound:
        moveq   #ML_LAST,%d0
        cmp.l   %d2,%d0
        blt     ml_hb_out
        jmp     HI_BOUND_IN
ml_hb_out:
        jmp     CHOOSER_MISS
        .macro  ML_CLAMP n, back
ml_clamp\n:
        moveq   #ML_LAST,%d1
        cmp.l   %d0,%d1
        bge     1f
        moveq   #ML_LAST,%d0
1:      jmp     \back
        .endm
        ML_CLAMP 1, 0x40078c2a
        ML_CLAMP 2, 0x40078cb8
        ML_CLAMP 3, 0x40078d36
        ML_CLAMP 4, 0x40078df6
        ML_CLAMP 5, 0x40078e84
ml_cur_bound:
        moveq   #ML_LAST,%d3
        cmp.l   %d4,%d3
        blt     ml_cb_out
        jmp     CUR_BOUND_IN
ml_cb_out:
        jmp     CUR_BOUND_OUT

| ==== THE RECORD KEYS (Phase 2) =====================================================
| The A/B, C/D and internal record keys each set a flag on press and clear it on release
| (0x460d10d0 / 10d4 / 10d8), then the manual-sampling routine 0x400836d8 turns the
| flags into a source mask and walks the eight tracks. Two changes, for SMPL / RSMP
| tracks only:
|   * ONE BUTTON: the routine's quick-mode test (0x40083756) counts the current track
|     as held when it is an SMPL / RSMP track, as RECORD QUICK MODE does for every
|     track: the red key alone records it. Any other track: stock.
|   * RSMP RECORDS INTERNAL: an A/B or C/D press with the current track RSMP (and no
|     other TRACK key held) sets the internal flag instead of its own, so the take is
|     the SRC3 source; its release clears what the press set.
        .set    FLAG_AB, 0x460d10d0
        .set    FLAG_CD, 0x460d10d4
        .set    FLAG_INT, 0x460d10d8
        .set    TRK_HELD, 0x460fab40     | the TRACK keys held, a bit per track
        .set    QUICK, 0x800000c4        | RECORD QUICK MODE (PERSONALIZE)
        .set    AB_ON_RET, 0x40030f34
        .set    AB_OFF_RET, 0x40030f0e
        .set    CD_ON_RET, 0x40030d52
        .set    CD_OFF_RET, 0x40030d02
        .set    QUICK_RET, 0x4008376e
        .global sm_ab_on, sm_ab_off, sm_cd_on, sm_cd_off, sm_quick

| sm_rsmp_here -> Z clear when the current track is RSMP and no other TRACK key is held.
| Preserves every register.
sm_rsmp_here:
        lea     -12(%sp),%sp
        movem.l %d0-%d2,(%sp)
        clr.b   sm_here
        move.l  sm_live,%d1              | a take recording: its machine decides (sm_quick)
        beq     sm_rh_cur
        tst.l   TRK_HELD
        bne     sm_rh_out                | a TRACK key held: stock
        moveq   #0,%d2
sm_rh_live:
        btst    %d2,%d1
        beq     sm_rh_lnext
        bsr     sm_kind
        cmpi.l  #K_RSMP,%d0
        beq     sm_rh_yes
sm_rh_lnext:
        addq.l  #1,%d2
        moveq   #8,%d0
        cmp.l   %d0,%d2
        blt     sm_rh_live
        bra     sm_rh_out
sm_rh_cur:
        mvz.b   CUR_TRACK,%d2
        move.l  TRK_HELD,%d1
        beq     sm_rh_kind               | none held: the current track
        moveq   #0,%d0
        bset    %d2,%d0
        cmp.l   %d0,%d1
        bne     sm_rh_out                | another track held: stock
sm_rh_kind:
        bsr     sm_kind
        cmpi.l  #K_RSMP,%d0
        bne     sm_rh_out
sm_rh_yes:
        moveq   #1,%d1
        move.b  %d1,sm_here
sm_rh_out:
        movem.l (%sp),%d0-%d2
        lea     12(%sp),%sp
        tst.b   sm_here                  | Z clear: RSMP here
        rts

| 0x40030f2e / 0x40030d4c (jmp, 6 B each): the press's `movel %d0,0x460d10d0 / 10d4`.
sm_ab_on:
        bsr     sm_rsmp_here
        beq     sm_abn_own
        move.l  %d0,FLAG_INT
        move.l  %a0,-(%sp)
        lea     sm_remap(%pc),%a0
        bset    #0,3(%a0)
        movea.l (%sp)+,%a0               | (movea keeps the flags)
        jmp     AB_ON_RET
sm_abn_own:
        move.l  %d0,FLAG_AB              | displaced
        jmp     AB_ON_RET
sm_cd_on:
        bsr     sm_rsmp_here
        beq     sm_cdn_own
        move.l  %d0,FLAG_INT
        move.l  %a0,-(%sp)
        lea     sm_remap(%pc),%a0
        bset    #1,3(%a0)
        movea.l (%sp)+,%a0               | (movea keeps the flags)
        jmp     CD_ON_RET
sm_cdn_own:
        move.l  %d0,FLAG_CD              | displaced
        jmp     CD_ON_RET
| 0x40030f08 / 0x40030cfc (jmp, 6 B each): the release's `clrl 0x460d10d0 / 10d4`.
sm_ab_off:
        clr.l   FLAG_AB                  | displaced
        move.l  %a0,-(%sp)
        lea     sm_remap(%pc),%a0
        bclr    #0,3(%a0)
        movea.l (%sp)+,%a0               | (movea keeps the flags)
        beq     sm_abf_out
        clr.l   FLAG_INT                 | the press set the internal flag
sm_abf_out:
        jmp     AB_OFF_RET
sm_cd_off:
        clr.l   FLAG_CD                  | displaced
        move.l  %a0,-(%sp)
        lea     sm_remap(%pc),%a0
        bclr    #1,3(%a0)
        movea.l (%sp)+,%a0               | (movea keeps the flags)
        beq     sm_cdf_out
        clr.l   FLAG_INT
sm_cdf_out:
        jmp     CD_OFF_RET

| 0x40083756 (jmp, 8 B): `tstl 0x800000c4; beqs 0x4008376e`, then stock: the current
| track (d4 the track walked, d1 the TRACK keys held) counts as held when no TRACK key
| is (d2 := 1). Here the test passes for RECORD QUICK MODE as stock, or for the current
| track being SMPL / RSMP. d0 is free (stock reloads it).
sm_quick:
| While a take records (sm_live), the red key alone stops it, whatever track is current
| (the editor stays on it -- sm_edopen -- so you can play another track meanwhile), and
| starts nothing else. Measured before this: from TRACK 2 the press did nothing and the
| take ran to the memory limit (16 s; Heath's MKI 25 Oct 2026, and the port).
        move.l  sm_live,%d0
        beq     sm_q_cur
        tst.l   %d1
        bne     sm_q_out                 | a TRACK key held: those tracks, stock
        btst    %d4,%d0
        beq     sm_q_out
        moveq   #1,%d2                   | the recording track counts as held: ONE2 stops it
        bra     sm_q_out
sm_q_cur:
        mvz.b   CUR_TRACK,%d0
        cmp.l   %d4,%d0
        bne     sm_q_out                 | not the current track
        tst.l   QUICK
        bne     sm_q_held                | quick mode: stock
        move.l  %d2,-(%sp)
        move.l  %d4,%d2
        bsr     sm_kind
        move.l  (%sp)+,%d2
        tst.l   %d0
        beq     sm_q_out
sm_q_held:
        tst.l   %d1
        bne     sm_q_out                 | a TRACK key held: those tracks
        moveq   #1,%d2
sm_q_out:
        jmp     QUICK_RET


| ==== AUTO-SAVE AND THE EDITOR (Part 2) =============================================
| A take on an SMPL / RSMP track:
|   * opens the audio editor on the track's buffer when it starts (unless the editor
|     is open already), so the take is drawn as it records. It stays open; stock's NO
|     closes it. A repeating recorder trig re-arms the recorder every pass without it
|     going idle, so it opens the editor once per run, not once per pass.
|   * is saved to the card once the recorder is idle again (0x40004268), the way
|     BUFFER SAVER saves (modules/buffer-saver/bufsave.s): FLEX object 128 + n,
|     mode 2 (save, then assign to itself), stock's name R<n>-YYMMDD-HHMM with -2, -3 ..
|     when taken, written to the set's AUDIO/SMPL folder (made on the first take if
|     missing; SAVE SAMPLES TO is held at AUD POOL for this save only). One buffer at a
|     time. A repeating trig overwrites each pass with the next, so only the last
|     pass of a run is there to save.
| sm_arm (0x400069e4, the recorder's take start; d3 = track) marks the run; the UI
| tick (fm_tick -> sm_auto) opens the editor and starts the saves.
        .set    ARM_RET, 0x400069ea
        .set    EDITOR, 0x460e5e4c       | the audio editor's window; 0 = closed
        .set    S_KIND, 0x460be9e8       | the sample save's object kind (1 = FLEX)
        .set    S_OBJ, 0x460be9ec        | ... and object id (recorder buffer n = 128 + n)
        .set    S_NAME, 0x460be9f0       | ... and file name, no extension
        .set    S_MODE, 0x460bcfc8       | 2 = save, then assign to self with no menu
        .set    S_DONE_A, 0x46c8d194
        .set    S_DONE_B, 0x46c8d198
        .set    POOL_READY, 0x46105408
        .set    SLOTSTATE, 0x46c922c4    | slot state records, 44 B; +16 = length in frames
        .set    SET_DIR, 0x100f8480
        .set    SAVE_TO, 0x800000a4      | SAVE SAMPLES TO: non-zero = the project
        .set    FILE_EXISTS, 0x46c823fa  | path -> non-zero if it exists (file or folder)
        .set    FS_MKDIR, 0x46c8240a     | path -> 0 made; parent must exist (STEM_REC.md 6.11)
        .set    STALL_TICKS, 3000        | a save, or the gain, that makes no progress for 50 s
                                         | (60 UI ticks a second) is given up. ACCLOOP19 gave up
                                         | after 50 s whatever the progress: a 154 s / 241 s
                                         | 24-bit take's save was abandoned mid-write and its slot
                                         | said FILE NOT FOUND (Heath's MKI card LOG, 1 Nov 2026)
        .set    ED_BUSY, 0x460e6bcc      | the editor's "an operation runs" flag (its handlers set it)
        .set    ED_QUEUE, 0x460d17ce     | the audio engine's queue the editor posts its operations to
        .set    NORM_GAIN, 1292          | -4 dB of full scale (unity 2048; -4.0013 dB). Was 1825 = -1 dB
                                         | to ACCLOOP21; Heath asked for 3 dB less, 1 Nov 2026
        .set    FS16, 32767              | full scale, 16-bit
        .set    FS24, 8388607            | full scale, 24-bit
        .set    PAGE_WALK, 0x4009499c    | (slot, frame, 1) -> d0 = its audio, d1 = frames on from it
                                         | in that block (the save's walk, SAMPLE_SAVE.md 4)
        .set    SILENT_PEAK, 8           | a take whose |sample| never passes 8 of 32768 (-72 dBFS,
                                         | 24-bit: its top 16 bits) is silent
        .set    SCAN_FRAMES, 65536       | frames scanned a UI tick (at most; a block's end stops it)
        .set    GAIN_FRAMES, 32768       | frames gained a UI tick (at most; a block's end stops it)
        .set    PROC_TICKS, 40           | PROCESSING TAKE.. shown again after this many UI ticks
        .global sm_recpos, sm_mcall1, sm_mcall2
        .weak   thr_armed                | REC THRESHOLD's per-track armed words, when present
        .global sm_arm, sm_edopen, sm_edwin, sm_post, sm_clear, sm_unlink, sm_cldlg, sm_po_drop, sm_s_saving
        .global sm_s_silent, sm_pbuf, sm_wtap, sm_wfast, sm_zfit, sm_zenc, sm_ovd1, sm_ovd2, sm_ovd3

| 0x400069e4 (jmp, 6 B): displaced `moveq #2,%d7; move.b %d7,2(%a2)` (recording).
sm_arm:
        moveq   #2,%d7
        move.b  %d7,2(%a2)
        lea     -12(%sp),%sp
        movem.l %d0-%d2,(%sp)
        move.l  %d3,%d2
        bsr     sm_kind
        beq     sm_ar_out                | not ours
        mvz.b   sm_live+3,%d0
        btst    %d3,%d0
        bne     sm_ar_out                | the run goes on (a repeating trig)
        bset    %d3,%d0
        move.b  %d0,sm_live+3
        mvz.b   sm_open+3,%d0
        bset    %d3,%d0
        move.b  %d0,sm_open+3
sm_ar_out:
        movem.l (%sp),%d0-%d2
        lea     12(%sp),%sp
        jmp     ARM_RET

| sm_auto, from the UI tick. Keeps d2-d7/a2-a6.
sm_auto:
        lea     -16(%sp),%sp
        movem.l %d2-%d4/%a2,(%sp)
        bsr     sm_trig_tick
| SAVE LOCK (Heath, 27 Oct 2026): what sm_post / sm_clear / sm_disp refused, shown here
| in the UI task. A dropped edit's own done callback first (busy flag, popup, redraw, as
| if it had run), then the message.
        move.l  sm_dropcb,%d0
        beq     sm_au_notcb
        clr.l   sm_dropcb
        movea.l %d0,%a0
        jsr     (%a0)
sm_au_notcb:
        tst.l   sm_toast
        beq     sm_au_notoast
        clr.l   sm_toast
        pea     0x30                     | as stock's RECORDING CLEARED! (0x40021d12)
        pea     sm_s_saving
        jsr     0x4005a2b8
        addq.l  #8,%sp
sm_au_notoast:
        tst.l   sm_stoast
        beq     sm_au_nostoast
        clr.l   sm_stoast
        pea     0x30
        pea     sm_s_silent
        jsr     0x4005a2b8
        addq.l  #8,%sp
sm_au_nostoast:
| PROCESSING n% / SAVING n% (Heath, 1 Nov 2026), again every PROC_TICKS ticks: while a take
| is scanned (sm_nstate 5: 0..10%) or gained (3: 10..99%, sm_gpos), then while its file is written (sm_busy: the writer's frame from sm_wtap).
        move.l  sm_nstate,%d0
        beq     sm_au_psave
        moveq   #2,%d1
        cmp.l   %d1,%d0
        beq     sm_au_noproc
        subq.l  #1,sm_ptick
        bgt     sm_au_noproc
        bsr     sm_procpct
        lea     sm_f_proc,%a0
        bra     sm_au_pshow
sm_au_psave:
        tst.l   sm_busy
        beq     sm_au_noproc
        subq.l  #1,sm_ptick
        bgt     sm_au_noproc
        move.l  sm_wtot,%d1
        moveq   #0,%d0
        tst.l   %d1
        beq     sm_au_spct               | not writing yet: 0%
        move.l  sm_wpos,%d0
        bsr     sm_pct
sm_au_spct:
        lea     sm_f_save,%a0
sm_au_pshow:
        moveq   #PROC_TICKS,%d1
        move.l  %d1,sm_ptick
        pea     sm_s_pct
        move.l  %d0,-(%sp)
        move.l  %a0,-(%sp)
        pea     sm_pbuf
        jsr     0x40013a08               | sprintf
        lea     16(%sp),%sp
        pea     0x30
        pea     sm_pbuf
        jsr     0x4005a2b8
        addq.l  #8,%sp
sm_au_noproc:
        tst.l   POOL_READY
        beq     sm_au_out
| the editor: the lowest buffer asking for it
        move.l  sm_open,%d0
        beq     sm_au_ends
        clr.l   sm_open
        moveq   #0,%d2
sm_au_find:
        btst    %d2,%d0
        bne     sm_au_open
        addq.l  #1,%d2
        bra     sm_au_find
sm_au_open:
        move.l  %d2,%d0
        addi.l  #128,%d0
        tst.l   EDITOR
        beq     sm_au_doopen
        cmp.l   0x46c8d19c,%d0
        bne     sm_au_ends               | open on something else: leave it
        move.l  %d0,sm_pin               | open on this buffer already: pin it
        bra     sm_au_ends
sm_au_doopen:
        move.l  %d0,-(%sp)               | the slot: recorder buffer d2 + 1
        pea     1                        | FLEX
        jsr     0x4006de34
        addq.l  #8,%sp
        jsr     0x4006e160
        move.l  %d2,%d0                  | pinned only now: the open itself passes sm_edopen
        addi.l  #128,%d0                 | with the editor still closed, which clears the pin
        move.l  %d0,sm_pin
| runs that have ended: the recorder idle again
sm_au_ends:
        moveq   #0,%d2
sm_au_idle:
        move.l  sm_live,%d0
        btst    %d2,%d0
        beq     sm_au_inext
        move.l  %d2,-(%sp)
        jsr     0x40004268               | non-zero = armed or recording
        addq.l  #4,%sp
        tst.b   %d0
        bne     sm_au_inext
        move.l  sm_live,%d0
        bclr    %d2,%d0
        move.l  %d0,sm_live
        bsr     sm_isloop                | LOOPER / RELOOPER: the take stays in the buffer,
        bne     sm_au_inext              | not scanned, gained or saved (Heath, 7 Nov 2026)
        move.l  sm_save,%d0
        bset    %d2,%d0
        move.l  %d0,sm_save
sm_au_inext:
        addq.l  #1,%d2
        moveq   #8,%d0
        cmp.l   %d0,%d2
        blt     sm_au_idle
| the saves, one at a time. A save in flight is waited for while its file grows (the
| writer's frame, sm_wtap); after STALL_TICKS without a new frame it is given up: the lock
| ends, but SAVE SAMPLES TO stays held until its done callback comes (put back mid-write,
| the assignment built a project-relative path: FILE NOT FOUND, ACCLOOP8's bug again).
        move.l  sm_busy,%d0
        beq     sm_au_save
        move.l  sm_wpos,%d1
        cmp.l   sm_wlast,%d1
        beq     sm_au_bstall
        move.l  %d1,sm_wlast             | progress: wait again in full
        move.l  #STALL_TICKS,%d0
        move.l  %d0,sm_busy
        bra     sm_au_out
sm_au_bstall:
        subq.l  #1,%d0
        move.l  %d0,sm_busy
        bra     sm_au_out
sm_au_save:
        move.l  sm_save,%d3
        beq     sm_au_out
| Not while a record key is down: the save's window would take that key's release, so
| the panel keeps it held -- STOP then reads as a recorder combo and never stops the
| sequencer, and a TRACK key arms a take (25 Oct 2026, hardware + port). The press
| flags clear on the release (stock, 0x40030f08 / 0x40030cfc); wait for that.
        tst.l   FLAG_AB
        bne     sm_au_out
        tst.l   FLAG_CD
        bne     sm_au_out
        tst.l   FLAG_INT
        bne     sm_au_out
| 5: scanning. 3: gaining (sm_au_gain, GAIN_FRAMES a tick). 2: save sm_cur.
        move.l  sm_nstate,%d0
        beq     sm_au_first
        moveq   #2,%d1
        cmp.l   %d1,%d0
        beq     sm_au_go
        moveq   #3,%d1
        cmp.l   %d1,%d0
        beq     sm_au_gain
        moveq   #5,%d1
        cmp.l   %d1,%d0
        beq     sm_au_scan
        bra     sm_au_out
sm_au_first:
        moveq   #0,%d2
sm_au_pick:
        btst    %d2,%d3
        bne     sm_au_pk
        addq.l  #1,%d2
        bra     sm_au_pick
sm_au_pk:
        move.l  %d2,%d0
        addi.l  #128,%d0
        moveq   #44,%d1
        muls.l  %d1,%d0
        addi.l  #SLOTSTATE,%d0
        movea.l %d0,%a0
        move.l  16(%a0),%d1              | the take's length in frames
        bgt     sm_au_scan0
        bclr    %d2,%d3                  | empty: nothing to save
        move.l  %d3,sm_save
        bra     sm_au_out
| SILENT TAKE (Heath, 1 Nov 2026) and NORMALIZE TO -1 dBFS (Heath, 25 / 26 Oct; -4 dBFS from ACCLOOP22, 1 Nov). The whole
| take is scanned for its peak, SCAN_FRAMES frames a tick at most, through the save's own
| walk. No sample past SILENT_PEAK: NO SOUND IN TAKE, neither gained nor saved (an RSMP
| track's INAB "-" survived into SMPL on ACCLOOP18: the A/B key recorded nothing, normalize
| made it a full-scale block of hiss and the save kept it). Else ONE pass of stock's gain
| (0x40095560) by NORM_GAIN * full scale / peak, in place of stock's NORMALIZE SELECTION
| (0x40095774) and the -1 dB gain after it: NORMALIZE is two per-frame soft-float passes,
| ~2,170 instructions a frame under the port to the gain's ~640, and a 42 s take took ~50 s
| to process on Heath's MKI (1 Nov 2026). The control record's word 0 (SLOTSTATE): bit 0
| stereo, bit 1 16-bit (else 24-bit, 3 B a sample, big-endian), as the save picks its
| converter (0x40021042).
sm_au_scan0:
        move.l  %d2,sm_cur
        move.l  %d1,sm_tlen
        clr.l   sm_spos
        clr.l   sm_peak
        moveq   #-1,%d0
        move.l  %d0,sm_gpos              | no gain yet
        clr.l   sm_ptick                 | PROCESSING 0% on the next tick
        moveq   #5,%d0
        move.l  %d0,sm_nstate
sm_au_scan:
        lea     -16(%sp),%sp
        movem.l %d5-%d7/%a3,(%sp)
        move.l  sm_cur,%d2
        addi.l  #128,%d2                 | the slot
        move.l  %d2,%d0
        moveq   #44,%d1
        muls.l  %d1,%d0
        addi.l  #SLOTSTATE,%d0
        movea.l %d0,%a3                  | its control record
        move.l  #SCAN_FRAMES,%d7         | this tick's frames
sm_as_run:
        move.l  sm_spos,%d0
        move.l  16(%a3),%d5              | the length
        sub.l   %d0,%d5                  | frames left
        ble     sm_as_end
        pea     1
        move.l  %d0,-(%sp)
        move.l  %d2,-(%sp)
        jsr     PAGE_WALK
        lea     12(%sp),%sp
        tst.l   %d1
        ble     sm_as_nowalk
        cmp.l   %d1,%d5
        ble     sm_as_n
        move.l  %d1,%d5                  | this block's frames
sm_as_n:
        cmp.l   %d7,%d5
        ble     sm_as_n2
        move.l  %d7,%d5                  | the rest of this tick's
sm_as_n2:
        sub.l   %d5,%d7
        add.l   %d5,sm_spos
        movea.l %d0,%a0
        moveq   #1,%d0
        and.l   (%a3),%d0
        lsl.l   %d0,%d5                  | samples
        move.l  sm_peak,%d6
        moveq   #2,%d0
        and.l   (%a3),%d0
        bne     sm_as_16
sm_as_24:
        move.w  (%a0),%d0
        ext.l   %d0
        lsl.l   #8,%d0
        mvz.b   2(%a0),%d1
        or.l    %d1,%d0
        tst.l   %d0
        bge     sm_as_24p
        neg.l   %d0
sm_as_24p:
        cmp.l   %d6,%d0
        ble     sm_as_24n
        move.l  %d0,%d6
sm_as_24n:
        addq.l  #3,%a0
        subq.l  #1,%d5
        bne     sm_as_24
        bra     sm_as_blk
sm_as_16:
        move.w  (%a0)+,%d0
        ext.l   %d0
        bge     sm_as_16p
        neg.l   %d0
sm_as_16p:
        cmp.l   %d6,%d0
        ble     sm_as_16n
        move.l  %d0,%d6
sm_as_16n:
        subq.l  #1,%d5
        bne     sm_as_16
sm_as_blk:
        move.l  %d6,sm_peak
        tst.l   %d7
        bgt     sm_as_run
        movem.l (%sp),%d5-%d7/%a3        | more next tick
        lea     16(%sp),%sp
        bra     sm_au_out
| The walk gives nothing: decide on what was seen; nothing loud seen -- save it as it is
| (before ACCLOOP20 a walk that gave nothing meant normalize and save).
sm_as_nowalk:
        bsr     sm_loud
        bne     sm_as_gain
        moveq   #2,%d0
        move.l  %d0,sm_nstate
        bra     sm_as_ret
sm_as_end:
        bsr     sm_loud
        beq     sm_as_silent
| g = floor(NORM_GAIN * full scale / peak), the gain's unity being 2048: the peak lands
| on -4 dBFS or a hair under, never over (the gain truncates toward zero).
sm_as_gain:
        move.l  sm_peak,%d0
        moveq   #2,%d1
        and.l   (%a3),%d1
        beq     sm_as_g24
        move.l  #NORM_GAIN * FS16,%d1    | fits 32 bits
        divu.l  %d0,%d1
        bra     sm_as_gset
sm_as_g24:
        moveq   #2,%d6                   | NORM_GAIN * FS24 = 1292 * 8388607 = 0x2_85fffaf4,
        move.l  #0x85fffaf4,%d1          | d6:d1; restoring division (quotient < 2^32)
        moveq   #32,%d5
sm_as_div:
        add.l   %d1,%d1
        addx.l  %d6,%d6
        cmp.l   %d0,%d6
        bcs     sm_as_dnext
        sub.l   %d0,%d6
        addq.l  #1,%d1
sm_as_dnext:
        subq.l  #1,%d5
        bne     sm_as_div
sm_as_gset:
        move.l  %d1,sm_gain
| The gain as m / 2^s: 16-bit m = g, s = 11 (|x| * g < 2^26). 24-bit: g halved (s down) to
| under 512, so |x| (< 2^23) * m fits 32 bits unsigned; m stays >= 256 (g >= 1292: the peak
| is at most full scale), the gain truncated by at most 1/256 (0.034 dB): never over.
        moveq   #11,%d0
        moveq   #2,%d6
        and.l   (%a3),%d6
        bne     sm_as_mset
sm_as_norm:
        cmpi.l  #512,%d1
        bcs     sm_as_mset
        tst.l   %d0
        beq     sm_as_mset               | s = 0: |x| * m <= the target, fits
        lsr.l   #1,%d1
        subq.l  #1,%d0
        bra     sm_as_norm
sm_as_mset:
        move.l  %d1,sm_gm
        move.l  %d0,sm_gs
        clr.l   sm_gpos
        moveq   #1,%d0
        move.l  %d0,ED_BUSY              | the editor's own operations wait, as for stock's gain
        moveq   #3,%d0                   | next: the gain
        move.l  %d0,sm_nstate
sm_as_ret:
        movem.l (%sp),%d5-%d7/%a3
        lea     16(%sp),%sp
        bra     sm_au_out
sm_as_silent:
        clr.l   sm_nstate
        move.l  sm_cur,%d2
        move.l  sm_save,%d3
        bclr    %d2,%d3
        move.l  %d3,sm_save              | not saved
        moveq   #1,%d0
        move.l  %d0,sm_stoast
        movem.l (%sp),%d5-%d7/%a3
        lea     16(%sp),%sp
        bra     sm_au_out

| sm_loud: a3 = the take's control record -> Z clear when sm_peak passes SILENT_PEAK
| (24-bit: SILENT_PEAK in its top 16 bits). Uses d0/d1.
sm_loud:
        move.l  #SILENT_PEAK * 256 + 255,%d1
        moveq   #2,%d0
        and.l   (%a3),%d0
        beq     sm_ld_cmp
        moveq   #SILENT_PEAK,%d1
sm_ld_cmp:
        cmp.l   sm_peak,%d1
        bcs     sm_ld_yes                | peak > the bound
        moveq   #0,%d0
        rts
sm_ld_yes:
        moveq   #1,%d0
        rts

| The gain, ours (ACCLOOP22, Heath: faster processing): every sample x of the take becomes
| sign(x) * ((|x| * sm_gm) >> sm_gs), in place, GAIN_FRAMES frames a UI tick through the
| save's walk as the scan. ~12 instructions a sample; stock's gain operation (0x40095560,
| the editor worker, 64-bit multiply) ~640: a 3 min take took 1:12 to process on ACCLOOP21.
sm_au_gain:
        lea     -24(%sp),%sp
        movem.l %d4-%d7/%a2-%a3,(%sp)
        move.l  sm_cur,%d2
        addi.l  #128,%d2                 | the slot
        move.l  %d2,%d0
        moveq   #44,%d1
        muls.l  %d1,%d0
        addi.l  #SLOTSTATE,%d0
        movea.l %d0,%a3                  | its control record
        move.l  #GAIN_FRAMES,%d7         | this tick's frames
        move.l  sm_gm,%d6
        move.l  sm_gs,%d4
sm_ag_run:
        move.l  sm_gpos,%d0
        move.l  16(%a3),%d5              | the length
        sub.l   %d0,%d5                  | frames left
        ble     sm_ag_done
        pea     1
        move.l  %d0,-(%sp)
        move.l  %d2,-(%sp)
        jsr     PAGE_WALK
        lea     12(%sp),%sp
        tst.l   %d1
        ble     sm_ag_done               | the walk gives nothing: save what there is
        cmp.l   %d1,%d5
        ble     sm_ag_n
        move.l  %d1,%d5                  | this block's frames
sm_ag_n:
        cmp.l   %d7,%d5
        ble     sm_ag_n2
        move.l  %d7,%d5                  | the rest of this tick's
sm_ag_n2:
        sub.l   %d5,%d7
        add.l   %d5,sm_gpos
        movea.l %d0,%a0
        moveq   #1,%d0
        and.l   (%a3),%d0
        lsl.l   %d0,%d5                  | samples
        moveq   #2,%d0
        and.l   (%a3),%d0
        bne     sm_ag_16
sm_ag_24:
        move.w  (%a0),%d0
        ext.l   %d0
        lsl.l   #8,%d0
        mvz.b   2(%a0),%d1
        or.l    %d1,%d0                  | x, 24-bit signed
        bge     sm_ag_24p
        neg.l   %d0
        mulu.l  %d6,%d0
        lsr.l   %d4,%d0
        neg.l   %d0
        bra     sm_ag_24w
sm_ag_24p:
        mulu.l  %d6,%d0
        lsr.l   %d4,%d0
sm_ag_24w:
        move.b  %d0,2(%a0)
        asr.l   #8,%d0
        move.w  %d0,(%a0)
        addq.l  #3,%a0
        subq.l  #1,%d5
        bne     sm_ag_24
        bra     sm_ag_blk
sm_ag_16:
        move.w  (%a0),%d0
        ext.l   %d0
        bge     sm_ag_16p
        neg.l   %d0
        mulu.l  %d6,%d0
        lsr.l   %d4,%d0
        neg.l   %d0
        bra     sm_ag_16w
sm_ag_16p:
        mulu.l  %d6,%d0
        lsr.l   %d4,%d0
sm_ag_16w:
        move.w  %d0,(%a0)+
        subq.l  #1,%d5
        bne     sm_ag_16
sm_ag_blk:
        tst.l   %d7
        bgt     sm_ag_run
        bra     sm_ag_ret                | more next tick
sm_ag_done:
        bsr     sm_gained                | the take is ready to save; the editor redrawn
sm_ag_ret:
        movem.l (%sp),%d4-%d7/%a2-%a3
        lea     24(%sp),%sp
        bra     sm_au_out
| gained (or given up): save sm_cur
sm_au_go:
        clr.l   sm_nstate
        move.l  sm_cur,%d2
        move.l  sm_save,%d3
        bclr    %d2,%d3
        move.l  %d3,sm_save
        bsr     sm_mkdir                 | <set>/AUDIO/SMPL, once
        bsr     sm_mkname
        moveq   #FLEX,%d0
        move.l  %d0,S_KIND
        move.l  sm_cur,%d0
        addi.l  #128,%d0
        move.l  %d0,S_OBJ
        moveq   #2,%d0
        move.l  %d0,S_MODE
        clr.l   S_DONE_A
        lea     sm_saved(%pc),%a0
        move.l  %a0,S_DONE_B
        move.l  #STALL_TICKS,%d0
        move.l  %d0,sm_busy
        moveq   #-1,%d0
        move.l  %d0,sm_wpos              | sm_wtap: the writer's first frame is news
        move.l  %d0,sm_wlast
        clr.l   sm_wtot
        clr.l   sm_ptick                 | SAVING TAKE 0% on the next tick
| The takes go to the pool whatever SAVE SAMPLES TO says: hold it at AUD POOL until the
| save's done callback (sm_saved), which comes after the assignment. The assignment
| builds the slot's path from it too ("../AUDIO/%s.wav" or the project's "%s.wav"), and
| on a real card it runs after the write -- restoring right after the call stored
| PATH=SMPL/R5-....wav, project-relative, and every reload said FILE NOT FOUND (Heath's
| MKI, PROJ DIR, 25 Oct 2026; the port's write finishes inside the call, so it never saw it).
        tst.l   sm_held
        bne     sm_au_held               | a given-up save still holds it: sm_saveto is the user's
        move.l  SAVE_TO,%d0
        move.l  %d0,sm_saveto
sm_au_held:
        moveq   #1,%d0
        move.l  %d0,sm_held
        clr.l   SAVE_TO
        pea     1
        bsr     sm_confirm               | the naming keyboard's confirm, past its name check
        addq.l  #4,%sp
sm_au_out:
        movem.l (%sp),%d2-%d4/%a2
        lea     16(%sp),%sp
        rts

| sm_confirm(1): stock's naming-keyboard confirm 0x40024288 (save, then assign) entered
| after its name check. That check (0x400141c4) allows only the keyboard's characters,
| so it refuses the '/' in "SMPL/R1-..." and the save never starts; everything after
| it only puts the name into "%s/AUDIO/%s.wav" (and the slot's "../AUDIO/%s.wav") and
| opens it, which a sub-folder path suits. Same frame as its own prologue
| (link #-520, d2-d5/a2 saved), then the instruction after the check; its epilogue
| unwinds it as usual. The name is always ours, never typed.
sm_confirm:
        link.w  %fp,#-520
        movem.l %d2-%d5/%a2,(%sp)
        jmp     0x400242d2

| the gain is done: the take is ready to save (and the editor redrawn).
sm_gained:
        clr.l   ED_BUSY
        moveq   #2,%d0
        move.l  %d0,sm_nstate
sm_nd_draw:
        tst.l   EDITOR
        beq     sm_nd_out
        jmp     0x4006dbdc
sm_nd_out:
        rts

| EDITOR STAYS ON THE TAKE (Heath, 26 Oct 2026). 0x4006de34(type, slot) points the audio
| editor at a slot; a track change calls it for the new track's sample (0x40083ca6, and
| 0x40077ad4 after it -- measured under the port: the editor's slot 0x46c8d19c went
| 0x80 -> 0x1 on TRACK 2 mid-take). While the editor is open on a recorder buffer whose
| run is live (sm_live), a request for any other slot is ignored, so the editor keeps
| drawing the take while you play other tracks. Once the take has stopped it stays on
| it too (to trim / slice) until YOU change track (the track-select call 0x40083ca6,
| by return address) -- the save's own refresh after the take (0x40077ad4, a general
| show-the-current-sample) re-pointed it to the current track (measured). sm_pin is set when SMPL opens the editor on the take.
| Editor closed: stock (the call also sets the current sample for other screens).
| 0x4006de34 (jmp, 6 B): displaced `movel %d2,%sp@-; movel %sp@(8),%d2`. On entry
| 4(sp) = type, 8(sp) = slot. d0/d1 are scratch here (cdecl).
sm_edopen:
        tst.l   EDITOR
        bne     sm_eo_open
        clr.l   sm_pin                   | editor closed: nothing pinned, stock
        bra     sm_eo_stock
sm_eo_open:
        move.l  sm_pin,%d0
        beq     sm_eo_stock
        move.l  8(%sp),%d1
        cmp.l   %d0,%d1
        beq     sm_eo_stock              | the pinned take itself (a refresh)
        subi.l  #128,%d0
        move.l  sm_live,%d1
        btst    %d0,%d1
        bne     sm_eo_stay               | still recording: stay
        move.l  (%sp),%d0                | stopped: only the user's track change moves it --
        cmpi.l  #0x40083cac,%d0          | the track-select call (0x40083ca6); it frees the pin,
        beq     sm_eo_free               | so the refresh after it (0x40077ad4) passes too
sm_eo_stay:                              | 0x40077ad4 alone is a general "show the current
        rts                              | track's sample" refresh: the save's after the take
                                         | came that way (measured) and must not move it
sm_eo_free:
        clr.l   sm_pin
sm_eo_stock:
        move.l  %d2,-(%sp)               | displaced
        move.l  8(%sp),%d2
        jmp     0x4006de3a

| EDITOR OPENS ON THE TAKE (Heath, 27 Oct 2026). The pin above holds only while the
| editor stays open: NO closes it, and opening it again (AED, or a path that points it
| at the current track's sample first) showed the current track's sample, not the take.
| While a take records (sm_live), opening the editor points it at the take's buffer
| first (the lowest live one) and pins it there, from any track, however often it is
| closed and opened. Once the take has stopped: stock (the pin then lasts as above).
| 0x4006e160 (jmp, 8 B): the editor window's open (it returns at once if already open);
| displaced `lea %sp@(-16),%sp; moveml %d2/%a2-%a4,%sp@`. d0/d1 are scratch (cdecl).
sm_edwin:
        tst.l   EDITOR
        bne     sm_ew_stock              | already open: stock returns
        move.l  sm_live,%d0
        beq     sm_ew_stock              | nothing recording: stock
        moveq   #0,%d1
sm_ew_find:
        btst    %d1,%d0
        bne     sm_ew_got
        addq.l  #1,%d1
        bra     sm_ew_find
sm_ew_got:
        addi.l  #128,%d1                 | recorder buffer n + 1
        cmp.l   0x46c8d19c,%d1
        beq     sm_ew_pin                | already pointed at it
        move.l  %d1,-(%sp)
        pea     1                        | FLEX
        jsr     0x4006de34               | editor closed: sm_edopen passes it, stock
        move.l  4(%sp),%d1
        addq.l  #8,%sp
sm_ew_pin:
        move.l  %d1,sm_pin
sm_ew_stock:
        lea     -16(%sp),%sp             | displaced
        movem.l %d2/%a2-%a4,(%sp)
        jmp     0x4006e168

| ==== SAVE LOCK (Heath, 27 Oct 2026) ================================================
| A take's buffer is locked from the take's end until its file is written: pending in
| sm_save, or normalizing / saving as sm_cur (sm_busy). Edits on it then would change
| what is written -- a 7.56 MB take saved silent on Heath's MKI, likely the buffer cleared
| in the editor during the save (his account, not reproduced). Refused while locked, with
| SAVING TAKE..: the editor's operations, CLEAR RECORDING, and a new take on that track.
| sm_locked: d0 = buffer 0..7 -> d0 = 1 locked, else 0 (Z set). Uses d1.
sm_locked:
        move.l  sm_save,%d1
        btst    %d0,%d1
        bne     sm_lk_yes
        tst.l   sm_busy
        beq     sm_lk_no
        cmp.l   sm_cur,%d0
        beq     sm_lk_yes
sm_lk_no:
        moveq   #0,%d0
        rts
sm_lk_yes:
        moveq   #1,%d0
        rts

| 0x40000c3c (jmp, 6 B), the queue post (queue, msg): displaced `movel %a2,%sp@-;
| moveal %sp@(8),%a1`. The audio editor's operations post to ED_QUEUE from their own
| message blocks, 0x460e5f00..0x460e70b9 (crop, delete, reverse, fades, normalize, gain,
| silence, paste, mix / invert, slice reverse / normalize, CROP SAMPLE; 0x460e70ba, cmd
| 16, is not an edit), command byte +0, slot +2, done callback +30. One for a locked
| buffer is not posted; its callback runs on the next UI tick (sm_auto). Command 22 is a
| save to a file (SAVE SELECTION AS SAMPLE here; the take's own save posts it from
| 0x460be796) and passes. Called from every task: d0/d1/a0/a1 only.
sm_post:
        move.l  4(%sp),%d0
        cmpi.l  #ED_QUEUE,%d0
        bne     sm_po_stock
        movea.l 8(%sp),%a0
        cmpa.l  #0x460e5f00,%a0
        bcs     sm_po_stock
        cmpa.l  #0x460e70ba,%a0
        bcc     sm_po_stock
        mvz.b   (%a0),%d0
        moveq   #22,%d1
        cmp.l   %d1,%d0
        beq     sm_po_stock              | a save to a file
        move.l  2(%a0),%d0
        subi.l  #128,%d0
        moveq   #8,%d1
        cmp.l   %d1,%d0
        bcc     sm_po_stock              | not a recorder buffer
        bsr     sm_locked
        beq     sm_po_stock
sm_po_drop:
        move.l  30(%a0),%d0
        move.l  %d0,sm_dropcb
        moveq   #1,%d0
        move.l  %d0,sm_toast
        rts
sm_po_stock:
        move.l  %a2,-(%sp)               | displaced
        movea.l 8(%sp),%a1
        jmp     0x40000c42

| 0x40021d0a (jmp, 8 B), CLEAR RECORDING's confirm (d1 = the slot): displaced `movel
| %d1,%sp@-; jsr 0x4002557c` (the clear). On a locked buffer: no clear, none of its
| RECORDING CLEARED! (0x40021d34 returns from the confirm), SAVING TAKE.. instead.
sm_clear:
        move.l  %d1,%d0
        subi.l  #128,%d0
        moveq   #8,%d2
        cmp.l   %d2,%d0
        bcc     sm_cl_stock
        movea.l %d1,%a0                  | the slot, past sm_locked (d2 is free here:
        bsr     sm_locked                | 0x40021d12 on reloads nothing from it)
        move.l  %a0,%d1
        tst.l   %d0
        beq     sm_cl_stock
        moveq   #1,%d0
        move.l  %d0,sm_toast
        jmp     0x40021d34
sm_cl_stock:
        move.l  %d1,-(%sp)               | displaced
        jsr     0x4002557c
        jmp     0x40021d12

| 0x40021d66 (jmp, 8 B), the same dialog's other confirm, on a recording tied to its file
| (DISASSOCIATE ...; every saved take is): displaced `movel %d1,%sp@-; jsr 0x40025188`
| (unties it). Locked: none of its ASSOCIATION REMOVED! (0x40021d90 returns).
sm_unlink:
        move.l  %d1,%d0
        subi.l  #128,%d0
        moveq   #8,%d2
        cmp.l   %d2,%d0
        bcc     sm_ul_stock
        movea.l %d1,%a0
        bsr     sm_locked
        move.l  %a0,%d1
        tst.l   %d0
        beq     sm_ul_stock
        moveq   #1,%d0
        move.l  %d0,sm_toast
        jmp     0x40021d90
sm_ul_stock:
        move.l  %d1,-(%sp)               | displaced
        jsr     0x40025188
| ONE-STEP CLEAR (Heath, 1 Nov 2026): every saved take is tied to its file, so stock's
| first CLEAR on it only unties it (DISASSOCIATE ...) and a second one clears it. On an
| SMPL / RSMP track's own buffer the untie is followed by CLEAR RECORDING's own clear
| (0x4002557c, same argument) and its tail (RECORDING CLEARED!, 0x40021d12): the take
| is on the card already. Both confirms share the frame (d2 saved, the slot pushed).
        move.l  (%sp),%d2
        subi.l  #128,%d2                 | buffer n = track n's own
        bsr     sm_kind
        beq     sm_ul_tail               | not ours: stock
        jsr     0x4002557c
        jmp     0x40021d12
sm_ul_tail:
        jmp     0x40021d6e

| 0x40021bc8 (jmp, 6 B), CLEAR SLOT's dialog on a recording (kind, slot): displaced `linkw
| %fp,#-8; movel %d2,%sp@-`. Opening it stores kind and slot in the sample-save globals
| (0x460be9e8 / ec, as S_KIND / S_OBJ) and clears S_MODE -- the ones a take's save in
| flight was set up with. On a locked buffer it does not open: SAVING TAKE.. instead.
sm_cldlg:
        move.l  4(%sp),%d0               | the kind: a recording is FLEX (1) or 4, as stock tests
        moveq   #1,%d1
        cmp.l   %d1,%d0
        beq     sm_cd_rec
        moveq   #4,%d1
        cmp.l   %d1,%d0
        bne     sm_cd_stock
sm_cd_rec:
        move.l  8(%sp),%d0
        subi.l  #128,%d0
        moveq   #8,%d1
        cmp.l   %d1,%d0
        bcc     sm_cd_stock
        bsr     sm_locked
        beq     sm_cd_stock
        moveq   #1,%d0
        move.l  %d0,sm_toast
        rts
sm_cd_stock:
        link.w  %fp,#-8                  | displaced
        move.l  %d2,-(%sp)
        jmp     0x40021bce

| LIVE WAVEFORM ON ANOTHER TRACK (Heath, 27 Oct 2026). 0x40005f54(buffer) is how much of a
| recording buffer is recorded so far; every caller first asks 0x40004268(buffer) whether
| THAT buffer's recorder is recording. But it read the recorder's live state for the
| CURRENT track (0x100b14cc; 84 B a track from 0x80004f1c), not the buffer's. With the
| editor pinned to a take on another track the waveform renderer (0x4008e434 /
| 0x4008e51e, via 0x4009499c / 0x40095984) and the editor's zoom (0x4006e3f2) were told
| 0 and drew nothing until the take stopped (Heath's MKI: then the whole take appeared;
| port: 0 on 4,580 of 5,521 renderer reads on TRACK 2, none on TRACK 1). Recorder buffer
| n is track n's, so it now reads the buffer's own recorder, for every caller; with the
| current track recording its own buffer (stock's only case) that is the same recorder.
| 0x40005f66 (jmp, 6 B, interrupts masked): displaced `mvzb 0x100b14cc,%d1`. a1 = the
| buffer 0..7.
sm_recpos:
        move.l  %a1,%d1
        jmp     0x40005f6c

| MONITOR THROUGH THE TRACK (Heath, 7 Nov 2026): a SAMPLER track plays the inputs it
| records, as a THRU track does, so they go through its own FX, while it has no take (an
| empty or cleared slot) and while its recorder is armed or recording; the take stays dry
| (the recorder reads the inputs, not the track). A track's audio is made
| on the ColdFire, a frame at a time: the voice loop (0x4000d3fc) calls its renderer
| twice (0..split, split..16), renderer(track, frame, start, end), which writes a header
| {count, 0, 1.0 (Q26), 0} and count stereo longs at *0x80001c80 (the idle 0x400047f0,
| FLEX 0x40004008, THRU 0x40004424 all alike). sm_mon is THRU's renderer with its two
| selectors taken from the recorder's INAB / INCD (what the take records: - / A B / A /
| B / A+B, the same five as THRU's) and unity gain (0.25 x 4 MACs), not the PLAYBACK
| page (a SAMPLER track's is FLEX's). The voice, its state and the trig path are left alone.
| 0x4000d43a (jmp, 6 B): the first call, displaced `move.l %d3,-(%sp); movea.l (%a3),%a0;
| jsr (%a0)`. d3 = the track.
sm_mcall1:
        move.l  %d3,-(%sp)
        movea.l (%a3),%a0
        bsr     sm_monq
        beq     sm_mc1_go
        lea     sm_mon,%a0
sm_mc1_go:
        jsr     (%a0)
        jmp     0x4000d440
| 0x4000d52c (jmp, 6 B): the second, displaced `jsr (%a0); move.b (%a2),%d0; moveq #15,%d4`.
sm_mcall2:
        bsr     sm_monq
        beq     sm_mc2_go
        lea     sm_mon,%a0
sm_mc2_go:
        jsr     (%a0)
        move.b  (%a2),%d0
        moveq   #15,%d4
        jmp     0x4000d532

| sm_monq: d3 = a track -> d0 != 0 (Z clear) when it is a SAMPLER track that monitors now:
| its recorder is armed or recording (state != 0), or its FLEX slot is empty (no take yet,
| or cleared: an empty SAMPLER is a THRU track; Heath, 7 Nov 2026). Preserves every other
| register.
sm_monq:
        lea     -16(%sp),%sp
        movem.l %d1-%d2/%a0-%a1,(%sp)
        move.l  %d3,%d2
        bsr     sm_kind
        cmpi.l  #K_SMPL,%d0
        bne     sm_mq_no
        move.l  %d3,-(%sp)
        jsr     0x40004268               | the track's recorder state (it sets a0)
        addq.l  #4,%sp
        tst.b   %d0
        bne     sm_mq_yes                | armed or recording
        move.l  #thr_armed,%d0           | REC THRESHOLD's armed table (weak: 0 without it); a
        beq     sm_mq_slot               | THR take waits there with the recorder still idle
        movea.l %d0,%a0
        tst.l   (%a0,%d3.l*4)
        bne     sm_mq_yes                | armed, waiting for the threshold
sm_mq_slot:
        bsr     ml_part
        move.l  %d3,%d0
        mulu.w  #5,%d0
        adda.l  %d0,%a0
        adda.l  #SLOT_FLEX,%a0
        mvz.b   (%a0),%d0                | its FLEX slot (0x80 + n: recorder buffer n + 1)
        moveq   #44,%d1
        muls.l  %d1,%d0
        addi.l  #SLOTSTATE,%d0
        movea.l %d0,%a0
        tst.l   16(%a0)                  | its length in frames
        bgt     sm_mq_no                 | a take: the track plays it
sm_mq_yes:
        moveq   #1,%d0
        bra     sm_mq_out
sm_mq_no:
        moveq   #0,%d0
sm_mq_out:
        movem.l (%sp),%d1-%d2/%a0-%a1
        lea     16(%sp),%sp
        tst.l   %d0
        rts

| ---- THE AMP ENVELOPE OF A TRACK THAT MONITORS (Heath's MKI, 7 Nov 2026) --------------
| A track is heard only while its AMP envelope is open. The envelope runs on the DSP; a
| trig opens it (the flags halfword, DSP record +60, bit 7, from the track's trig byte
| 0x80004858 + 8t bit 1, which 0x40004bd4 turns into it and clears), and a STOP closes it:
| the tracks in the stop mask 0x8000184a get HOLD 0 and REL <= 24 (0x4000d0ba, every
| frame). ACCLOOP28 monitored with no trig: the port opened the envelope from its boot
| state and so passed, the unit's stayed shut (silent until a trig + PLAY, Heath). Per
| track, each frame, before the stop mask is applied: a track that monitors leaves the
| stop mask, holds (HOLD 127 in its record), and is trigged once when it starts to
| monitor and again after a stop. Its ATK and VOL still apply; HOLD and REL apply again
| when it plays its take.
        .set    STOP_MASK, 0x8000184a    | bit t: track t's envelope is released (STOP)
        .set    ENV_TRIG, 0x80004858     | + 8t: track t's trig byte (bit 1: trig)
        .set    DSP_REC, 0x80000110      | + 512 * half + 64t: track t's DSP record
        .global sm_envgate

| 0x4000d0a4 (jmp, 6 B): displaced `movel %sp@(132),%d0; moveq #9,%d1` (the half the
| records are written for, then the stop mask's loop). d0-d2/a0 are set by the code after.
sm_envgate:
        move.l  132(%sp),%d0
        lea     -20(%sp),%sp
        movem.l %d3-%d5/%a1-%a2,(%sp)
        moveq   #9,%d1
        lsl.l   %d1,%d0
        addi.l  #DSP_REC,%d0
        movea.l %d0,%a1                  | track 0's record, this half
        lea     ENV_TRIG,%a2
        moveq   #0,%d3
        moveq   #0,%d5                   | the tracks that monitor this frame
sm_eg_loop:
        bsr     sm_monq
        beq     sm_eg_next
        bset    %d3,%d5
        move.w  #0x7f00,2(%a1)           | HOLD 127
        mvz.b   STOP_MASK,%d0
        btst    %d3,%d0
        beq     sm_eg_new
        bclr    %d3,%d0
        move.b  %d0,STOP_MASK
        bra     sm_eg_trig               | stopped: open it again
sm_eg_new:
        move.l  sm_envmon,%d0
        btst    %d3,%d0
        bne     sm_eg_next               | open since it started to monitor
sm_eg_trig:
        move.l  %d3,%d0
        lsl.l   #3,%d0
        mvz.b   (%a2,%d0.l),%d1
        moveq   #2,%d4
        or.l    %d4,%d1
        move.b  %d1,(%a2,%d0.l)
sm_eg_next:
        lea     64(%a1),%a1
        addq.l  #1,%d3
        moveq   #8,%d0
        cmp.l   %d0,%d3
        bne     sm_eg_loop
        move.l  %d5,sm_envmon
        movem.l (%sp),%d3-%d5/%a1-%a2
        lea     20(%sp),%sp
        move.l  132(%sp),%d0             | displaced
        moveq   #9,%d1
        jmp     0x4000d0aa
sm_envmon:
        .long   0                        | bit t: track t monitored last frame

| sm_mon(track, frame, start, end): 0x40004424's body (the inputs, a page a frame at
| 0x80005660 + [0x46104d00] * 0x100: C D at +0, A B at +0x80, a long a sample each).
        .set    MON_G, 0x20000000        | 0.25: four MACs a sample = unity
sm_mon:
        lea     -44(%sp),%sp
        movem.l %d2-%d7/%a2-%fp,(%sp)
        move.l  48(%sp),%d2              | the track
        movea.l 56(%sp),%a2              | start
        move.l  60(%sp),%d3
        sub.l   %a2,%d3                  | count
        movea.l 0x80001c80,%a0
        move.l  %d3,(%a0)+
        clr.l   (%a0)+
        move.l  #0x04000000,(%a0)+
        clr.l   (%a0)+
        move.l  %a0,0x80001c80
        tst.l   %d3
        ble     sm_mn_out
        move.l  %d3,%d0
        lsl.l   #3,%d0
        add.l   %a0,%d0
        move.l  %d0,0x80001c80           | past this call's samples
        movea.l %a0,%a4                  | the output
| the selectors: the Part's recorder setup for this track
        bsr     ml_part
        move.l  %d2,%d0
        mulu.w  #12,%d0
        adda.l  %d0,%a0
        adda.l  #REC_OFF,%a0
        mvz.b   R_INAB(%a0),%d6          | AB's selector
        mvz.b   R_INCD(%a0),%d7          | CD's
| the input pointers
        move.l  0x46104d00,%d4
        lsl.l   #5,%d4
        move.l  %a2,%d0
        add.l   %d4,%d0
        lsl.l   #3,%d0
        addi.l  #0x80005660,%d0
        movea.l %d0,%fp                  | C D
        addi.l  #0x80,%d0
        movea.l %d0,%a3                  | A B
| AB's four gains: d4 A->L, a0 A->R, d5 B->L, a1 B->R
        move.l  %d6,%d0
        bsr     sm_mn_gains
        move.l  %d0,%d4
        movea.l %d1,%a0
        move.l  %d2,%d5
        movea.l %d3,%a1
        move.l  %a1,-(%sp)               | (kept: sm_mn_gains clobbers d0-d3)
| CD's: d6 C->L, a2 C->R, d7 D->L, a5 D->R
        move.l  %d7,%d0
        bsr     sm_mn_gains
        move.l  %d0,%d6
        movea.l %d1,%a2
        move.l  %d2,%d7
        movea.l %d3,%a5
        movea.l (%sp)+,%a1
        move.l  56(%sp),%d3
        neg.l   %d3
        add.l   60(%sp),%d3              | count again
        move.l  #0xa0,%macsr
        movclr.l %acc0,%d0
        movclr.l %acc1,%d1
| (no MAC-with-load: the port shims only stock's sites, TRAPS.md trap-unicorn-macload)
sm_mn_loop:
        move.l  (%a3)+,%d0
        mac.l   %d4,%d0,%acc0
        mac.l   %d4,%d0,%acc0
        mac.l   %d4,%d0,%acc0
        mac.l   %d4,%d0,%acc0
        mac.l   %a0,%d0,%acc1
        mac.l   %a0,%d0,%acc1
        mac.l   %a0,%d0,%acc1
        mac.l   %a0,%d0,%acc1
        move.l  (%a3)+,%d0
        mac.l   %d5,%d0,%acc0
        mac.l   %d5,%d0,%acc0
        mac.l   %d5,%d0,%acc0
        mac.l   %d5,%d0,%acc0
        mac.l   %a1,%d0,%acc1
        mac.l   %a1,%d0,%acc1
        mac.l   %a1,%d0,%acc1
        mac.l   %a1,%d0,%acc1
        move.l  (%fp)+,%d0
        mac.l   %d6,%d0,%acc0
        mac.l   %d6,%d0,%acc0
        mac.l   %d6,%d0,%acc0
        mac.l   %d6,%d0,%acc0
        mac.l   %a2,%d0,%acc1
        mac.l   %a2,%d0,%acc1
        mac.l   %a2,%d0,%acc1
        mac.l   %a2,%d0,%acc1
        move.l  (%fp)+,%d0
        mac.l   %d7,%d0,%acc0
        mac.l   %d7,%d0,%acc0
        mac.l   %d7,%d0,%acc0
        mac.l   %d7,%d0,%acc0
        mac.l   %a5,%d0,%acc1
        mac.l   %a5,%d0,%acc1
        mac.l   %a5,%d0,%acc1
        mac.l   %a5,%d0,%acc1
        movclr.l %acc0,%d1
        move.l  %d1,(%a4)+
        movclr.l %acc1,%d1
        move.l  %d1,(%a4)+
        subq.l  #1,%d3
        bne     sm_mn_loop
        moveq   #32,%d0
        move.l  %d0,%macsr
sm_mn_out:
        movem.l (%sp),%d2-%d7/%a2-%fp
        lea     44(%sp),%sp
        rts
| d0 = a selector (- A B, A, B, A+B: 0..4; above 4 as 4, as stock) -> d0 first->L,
| d1 first->R, d2 second->L, d3 second->R
sm_mn_gains:
        moveq   #0,%d1
        moveq   #0,%d2
        moveq   #0,%d3
        cmpi.l  #1,%d0
        beq     sm_mg_ab
        cmpi.l  #2,%d0
        beq     sm_mg_a
        cmpi.l  #3,%d0
        beq     sm_mg_b
        tst.l   %d0
        beq     sm_mg_out                | "-": d0 = 0
        move.l  #MON_G/2,%d0             | A+B: half of each to both sides
        move.l  %d0,%d1
        move.l  %d0,%d2
        move.l  %d0,%d3
        rts
sm_mg_ab:
        move.l  #MON_G,%d0
        move.l  %d0,%d3
        rts
sm_mg_a:
        move.l  #MON_G,%d0
        move.l  %d0,%d1
        rts
sm_mg_b:
        moveq   #0,%d0
        move.l  #MON_G,%d2
        move.l  %d2,%d3
sm_mg_out:
        rts

| PROGRESS (Heath, 1 Nov 2026: a long take's processing looked hung). The scan and the gain
| keep their own frame (sm_spos, sm_gpos); a tap records how far stock's WAV writer is.
| 0x40021070 (jsr), the WAV writer's page walk (0x40020f04; a4 = the slot, d7 = the frame,
| d3 = frames left): the take's own save records its frame. d0/d1 are the walk's results.
sm_wtap:
        tst.l   sm_busy
        beq     sm_wt_walk
        move.l  sm_cur,%d0
        addi.l  #128,%d0
        cmp.l   %a4,%d0
        bne     sm_wt_walk
        move.l  %d7,sm_wpos
        move.l  %d7,%d0
        add.l   %d3,%d0
        move.l  %d0,sm_wtot
sm_wt_walk:
        jmp     PAGE_WALK

| FAST SAVE (ACCLOOP23, Heath, 2 Nov 2026). The WAV writer (0x40020f04) hands each 3 KB
| block to the file write 0x400166b8(file, src, n), which copies it into the file's buffer
| ONE BYTE at a time, loading and storing the buffer's fill (+12) and the file's count (+16)
| on every byte (~13 instructions a byte; ~60% of a take's processing after ACCLOOP22's gain).
| sm_fwrite is that function with the copy done a block at a time, 4 bytes a move when all
| is long-aligned: the same buffer, the same flush (0x400208d4 to 0x4ecd3000, then the
| card's sector write through 0x46c82402, fill cleared even on an error), the same results
| (1, -2 for no / a bad file, the sector write's negative error).
| 0x40021060 (jmp, 6 B): displaced `lea 0x400166b8,%fp` -- the writer's audio blocks only
| (its header and its pad byte still call stock).
sm_wfast:
        lea     sm_fwrite,%fp
        jmp     0x40021066
sm_fwrite:
        lea     -24(%sp),%sp
        movem.l %d2-%d4/%a2-%a4,(%sp)
        movea.l 28(%sp),%a2              | the file
        movea.l 32(%sp),%a4              | the bytes
        move.l  36(%sp),%d2              | how many
        move.l  %a2,%d0
        beq     sm_fw_bad
        move.l  (%a2),%d0
        subq.l  #1,%d0
        cmpi.l  #510,%d0
        bhi     sm_fw_bad
sm_fw_loop:
        tst.l   %d2
        beq     sm_fw_ok
        move.l  12(%a2),%d0              | the buffer's fill
        move.l  8(%a2),%d3
        sub.l   %d0,%d3                  | its room
        cmp.l   %d2,%d3
        bls     sm_fw_k
        move.l  %d2,%d3                  | k = min(room, left)
sm_fw_k:
        sub.l   %d3,%d2
        add.l   %d3,16(%a2)              | the file's count
        movea.l 4(%a2),%a0
        adda.l  %d0,%a0                  | to
        add.l   %d3,%d0
        move.l  %d0,12(%a2)              | the new fill
        move.l  %a0,%d1
        move.l  %a4,%d4
        or.l    %d4,%d1
        or.l    %d3,%d1
        moveq   #3,%d4
        and.l   %d4,%d1
        bne     sm_fw_b
        lsr.l   #2,%d3
sm_fw_l:
        move.l  (%a4)+,(%a0)+
        subq.l  #1,%d3
        bne     sm_fw_l
        bra     sm_fw_full
sm_fw_b:
        move.b  (%a4)+,(%a0)+
        subq.l  #1,%d3
        bne     sm_fw_b
sm_fw_full:
        move.l  12(%a2),%d0
        cmp.l   8(%a2),%d0
        blt     sm_fw_loop               | room left (stock: size > fill)
        move.l  8(%a2),-(%sp)
        move.l  4(%a2),-(%sp)
        pea     0x4ecd3000
        jsr     0x400208d4
        move.l  8(%a2),%d0
        moveq   #9,%d1
        asr.l   %d1,%d0
        move.l  %d0,-(%sp)               | sectors
        pea     0x4ecd3000
        move.l  (%a2),-(%sp)
        movea.l 0x46c82402,%a0
        jsr     (%a0)
        lea     24(%sp),%sp
        clr.l   12(%a2)
        tst.l   %d0
        bge     sm_fw_loop
        bra     sm_fw_out                | the sector write's error
sm_fw_ok:
        moveq   #1,%d0
        bra     sm_fw_out
sm_fw_bad:
        moveq   #-2,%d0
sm_fw_out:
        movem.l (%sp),%d2-%d4/%a2-%a4
        lea     24(%sp),%sp
        rts

| sm_pct: d0 = a frame, d1 = the frames in all -> d0 = 0 .. 99. Uses d1.
sm_pct:
        move.l  %d2,-(%sp)
        moveq   #100,%d2
        divu.l  %d2,%d1
        addq.l  #1,%d1
        tst.l   %d0
        bge     sm_pc_pos
        moveq   #0,%d0
sm_pc_pos:
        divu.l  %d1,%d0
        moveq   #99,%d2
        cmp.l   %d2,%d0
        ble     sm_pc_out
        move.l  %d2,%d0
sm_pc_out:
        move.l  (%sp)+,%d2
        rts

| sm_procpct: -> d0 = PROCESSING's %: the scan 0 .. 9, the gain 10 .. 99. Uses d1.
sm_procpct:
        move.l  %d2,-(%sp)
        move.l  sm_tlen,%d1
        moveq   #5,%d0
        cmp.l   sm_nstate,%d0
        bne     sm_pp_gain
        move.l  sm_spos,%d0
        bsr     sm_pct
        moveq   #10,%d2
        divu.l  %d2,%d0
        bra     sm_pp_out
sm_pp_gain:
        move.l  sm_gpos,%d0
        bsr     sm_pct
        move.l  %d0,%d1
        moveq   #10,%d2
        divu.l  %d2,%d1
        sub.l   %d1,%d0
        addi.l  #10,%d0                  | 10 + 90% of it
        moveq   #99,%d2
        cmp.l   %d2,%d0
        ble     sm_pp_out
        move.l  %d2,%d0
sm_pp_out:
        move.l  (%sp)+,%d2
        rts

| A LONG TAKE FITS THE EDITOR (Heath, 1 Nov 2026: the live waveform stopped growing at ~42 s;
| the take went on and saved whole). The editor's zoom is frames per pixel, the view's +16,
| and stock caps it at 20,000: zoom to fit (0x40077138) sets (end - start) / (width - 24)
| + 20 -- port, the editor's view 0x400ce724, a 60 s take: 32,168 at its end, ~82 px; stock
| sat at 20,000 from ~37 s, the rest of the take off the right edge. The zoom encoder
| (0x400770a0) caps the same. On a recorder buffer (the slot the editor shows is 128 .. 135)
| the cap is ZOOM_MAX: the whole pool fits (85.56 MiB = 44.9 M frames of 16-bit mono, 82 px
| = 547,000). The zoom's users stay in 32 bits at that: the encoder's step (delta x zoom
| >> 4), the start (-10 x zoom), the renderer's 102 columns.
        .set    ZOOM_MAX, 600000
        .set    ED_SHOWN, 0x46c8d19c     | the slot the editor shows
| 0x4007717a (jmp, 14 B), zoom to fit: displaced `cmpil #20000,%d0; bls 0x40077188; movel
| #20000,%d0`. d0 = the zoom; d1 is free (reloaded after).
sm_zfit:
        bsr     sm_zcap
        cmp.l   %d1,%d0
        bls     sm_zf_out
        move.l  %d1,%d0
sm_zf_out:
        jmp     0x40077188
| 0x400770d6 (jmp, 14 B), the zoom encoder: displaced `cmpil #20000,%d1; ble 0x400770e4;
| movel #20000,%d1`. d1 = the zoom (signed); d0 is free (reloaded after).
sm_zenc:
        move.l  %d1,-(%sp)
        bsr     sm_zcap
        move.l  %d1,%d0                  | the cap
        move.l  (%sp)+,%d1
        cmp.l   %d0,%d1
        ble     sm_ze_out
        move.l  %d0,%d1
sm_ze_out:
        jmp     0x400770e4
| The editor's overview bar (3 views): past 131,072 frames a pixel stock divides by
| (length >> 14), which is 0 for a take under 16,384 frames. Stock never got there (zoom
| <= 20,000); with DYNAMIC RECORDERS a take's first zoom to fit is to the memory cap
| (213,130 on a 16-bit port take): EXCEPTION VEC:05 ADDR:4006F458 on Heath's MKI,
| 1 Nov 2026. A 0 divisor becomes 1: the bar's end is clamped to the view after.
| 0x4006f456 / 0x40071244 (jmp, 6 B): displaced `asrl %d4,%d3; divsl %d3,%d0`.
sm_ovd1:
        asr.l   %d4,%d3
        bne     sm_ov1
        moveq   #1,%d3
sm_ov1: divs.l  %d3,%d0
        jmp     0x4006f45c
sm_ovd2:
        asr.l   %d4,%d3
        bne     sm_ov2
        moveq   #1,%d3
sm_ov2: divs.l  %d3,%d0
        jmp     0x4007124a
| 0x40073e22 (jmp, 6 B): displaced `lsrl %d4,%d3; divul %d3,%d0`.
sm_ovd3:
        lsr.l   %d4,%d3
        bne     sm_ov3
        moveq   #1,%d3
sm_ov3: divu.l  %d3,%d0
        jmp     0x40073e28
| sm_zcap: -> d1 = the zoom's cap for the slot the editor shows. Keeps the rest.
sm_zcap:
        move.l  ED_SHOWN,%d1
        subi.l  #128,%d1
        cmpi.l  #8,%d1
        bcs     sm_zc_rec
        move.l  #20000,%d1               | stock
        rts
sm_zc_rec:
        move.l  #ZOOM_MAX,%d1
        rts

| stock's done callback after the save and the assignment, (result).
sm_saved:
        clr.l   sm_busy
        bsr     sm_restore               | the assignment is done: SAVE SAMPLES TO back
        rts

| ==== AN EDITED TAKE SAVES NEXT TO IT (Heath, 2 Nov 2026) ===========================
| The editor's SAVE SAMPLE COPY / SAVE AND ASSIGN on a take (a FLEX slot or recorder
| buffer whose file is in AUDIO/SMPL) writes AUDIO/SMPL/<name>-2 (-3 .. while taken) --
| never over the original, never the pool root or the project. A name ending -2 .. -99
| (an edit of an edit) drops that ending first, so it becomes the next free one.
| Any save or assignment whose name starts "SMPL/" (ours, and these) uses the pool's
| path whatever SAVE SAMPLES TO says, at all three of stock's pool-or-project tests:
|   0x400242d2  the naming keyboard's confirm (S_NAME)       -- sm_cfm, renames too
|   0x400241a6  the save it starts (name in d2)              -- sm_svp
|   0x40023f82  the assignment after it (name in d4)         -- sm_asp
        .set    FLEX_PATHS, 0x100b14f0   | FLEX slot (and recorder buffer 128..135) records,
        .set    SLOT_REC, 1096           | 1096 B each, starting with the file's path
        .global sm_cfm, sm_svp, sm_asp
sm_cfm:
        lea     S_NAME,%a0
        bsr     sm_issmpl
        bne     sm_cf_pool               | our own take's save
        moveq   #1,%d0
        cmp.l   S_KIND,%d0
        bne     sm_cf_stock              | not a FLEX object
        move.l  S_OBJ,%d0
        cmpi.l  #135,%d0
        bhi     sm_cf_stock
| A LOOPER / RELOOPER take (its track's own buffer), saved by hand from the editor: to
| AUDIO/SMPL as SAMPLER's are, under the name the keyboard holds, -2 .. while taken
| (Heath, 7 Nov 2026: press SAVE and YES, no typing).
        move.l  %d0,%d1
        subi.l  #128,%d1
        bcs     sm_cf_file               | a FLEX slot, not a recorder buffer
        move.l  %d2,-(%sp)
        move.l  %d1,%d2
        bsr     sm_isloop
        move.l  (%sp)+,%d2
        tst.l   %d0
        beq     sm_cf_file
        bsr     sm_mkdir
        bsr     sm_edname
        bra     sm_cf_pool
sm_cf_file:
        move.l  S_OBJ,%d0
        move.l  #SLOT_REC,%d1
        mulu.l  %d1,%d0
        addi.l  #FLEX_PATHS,%d0
        movea.l %d0,%a0
        bsr     sm_inpool
        beq     sm_cf_stock              | its file is not in AUDIO/SMPL
        bsr     sm_edname
        bra     sm_cf_pool
sm_cf_stock:
        tst.l   SAVE_TO
        beq     sm_cf_pool
        jsr     0x40024eec
        tst.l   %d0
        beq     sm_cf_pool
        jmp     0x40024306
sm_cf_pool:
        jmp     0x400242e4

sm_svp:
        movea.l %d2,%a0
        bsr     sm_issmpl
        bne     sm_sv_pool
        tst.l   SAVE_TO
        beq     sm_sv_pool
        jsr     0x40024eec
        tst.l   %d0
        beq     sm_sv_pool
        jmp     0x400241d8
sm_sv_pool:
        jmp     0x400241b8

sm_asp:
        movea.l %d4,%a0
        bsr     sm_issmpl
        bne     sm_as_pool
        tst.l   SAVE_TO
        beq     sm_as_pool
        jsr     0x40024eec
        tst.l   %d0
        beq     sm_as_pool
        jmp     0x40023f9e
sm_as_pool:
        jmp     0x40023f94

| sm_issmpl: Z clear (d0 = 1) if the name at a0 starts "SMPL/". Uses d0-d1/a0-a1.
sm_issmpl:
        lea     sm_s_pfx,%a1
sm_is_next:
        move.b  (%a1)+,%d1
        beq     sm_is_yes
        move.b  (%a0)+,%d0
        cmp.b   %d1,%d0
        beq     sm_is_next
        moveq   #0,%d0
        rts
sm_is_yes:
        moveq   #1,%d0
        rts

| sm_inpool: Z clear (d0 = 1) if the path at a0 (a slot's) has "/SMPL/" in it. Uses d0-d1/a0-a1.
sm_inpool:
        move.l  %a2,-(%sp)
        move.l  #250,%d1
sm_ip_pos:
        tst.b   (%a0)
        beq     sm_ip_no
        movea.l %a0,%a2
        lea     sm_s_dir,%a1
sm_ip_cmp:
        move.b  (%a1)+,%d0
        beq     sm_ip_yes
        cmp.b   (%a2)+,%d0
        beq     sm_ip_cmp
        addq.l  #1,%a0
        subq.l  #1,%d1
        bne     sm_ip_pos
sm_ip_no:
        movea.l (%sp)+,%a2
        moveq   #0,%d0
        rts
sm_ip_yes:
        movea.l (%sp)+,%a2
        moveq   #1,%d0
        rts

| sm_edname: S_NAME (typed) -> SMPL/<it, less a -2 .. -99 ending>-N, the first N from 2
| with no such file (sm_mkname's loop; a name never used before keeps no number).
sm_edname:
        lea     S_NAME,%a0
        lea     sm_base,%a1
        moveq   #63,%d1
sm_en_cp:
        move.b  (%a0)+,%d0
        move.b  %d0,(%a1)+
        beq     sm_en_end
        subq.l  #1,%d1
        bne     sm_en_cp
        clr.b   (%a1)+
sm_en_end:
        subq.l  #1,%a1                   | a1 -> its NUL
        lea     sm_base,%a0
        move.l  %a1,%d1
        sub.l   %a0,%d1                  | length
        moveq   #3,%d0
        cmp.l   %d0,%d1
        blt     sm_en_go                 | too short to have "x-N"
        mvz.b   -1(%a1),%d0              | last: a digit?
        subi.l  #'0',%d0
        moveq   #9,%d1
        cmp.l   %d1,%d0
        bhi     sm_en_go
        mvz.b   -2(%a1),%d0
        cmpi.l  #'-',%d0
        beq     sm_en_one                | "-N"
        subi.l  #'0',%d0
        cmp.l   %d1,%d0
        bhi     sm_en_go
        tst.l   %d0
        beq     sm_en_go                 | "-0N": not ours
        mvz.b   -3(%a1),%d0
        cmpi.l  #'-',%d0
        bne     sm_en_go
        lea     sm_base+4,%a0
        cmpa.l  %a0,%a1
        bcs     sm_en_go                 | "x-NN" needs 4
        clr.b   -3(%a1)                  | "-NN", 10 .. 99
        bra     sm_en_go
sm_en_one:
        mvz.b   -1(%a1),%d0
        cmpi.l  #'2',%d0
        blt     sm_en_go                 | -0, -1: not ours
        clr.b   -2(%a1)
sm_en_go:
        bra     sm_mkedit

sm_s_pfx:
        .asciz  "SMPL/"
sm_s_dir:
        .asciz  "/SMPL/"
        .balign 2

| sm_restore: put SAVE SAMPLES TO back if a save holds it. Keeps every register.
sm_restore:
        tst.l   sm_held
        beq     sm_rs_out
        clr.l   sm_held
        move.l  %d0,-(%sp)
        move.l  sm_saveto,%d0
        move.l  %d0,SAVE_TO
        move.l  (%sp)+,%d0
sm_rs_out:
        rts

| sm_mkdir: make <set>/AUDIO/SMPL if it is not there (the parent AUDIO is the pool, which
| the set always has). A failure leaves the save to fail at its open, as a full card
| does -- nothing else changes. Keeps every register.
sm_mkdir:
        lea     -16(%sp),%sp
        movem.l %d0-%d1/%a0-%a1,(%sp)
        pea     SET_DIR
        pea     sm_fmt_dir
        pea     sm_path
        jsr     0x40013a08               | sprintf
        lea     12(%sp),%sp
        pea     sm_path
        movea.l FILE_EXISTS,%a0
        jsr     (%a0)
        addq.l  #4,%sp
        tst.l   %d0
        bne     sm_md_out
        pea     sm_path
        movea.l FS_MKDIR,%a0
        jsr     (%a0)
        addq.l  #4,%sp
sm_md_out:
        movem.l (%sp),%d0-%d1/%a0-%a1
        lea     16(%sp),%sp
        rts

| S_NAME <- SMPL/R<sm_cur+1>-YYMMDD-HHMM, with -2 .. -99 while that file exists where stock
| will write it (bufsave.s make_name).
sm_mkname:
        lea     -8(%sp),%sp
        movem.l %d2/%a2,(%sp)
        jsr     0x400819fc               | "YYMMDD-HHMM"
        move.l  %d0,-(%sp)
        move.l  sm_cur,%d0
        addq.l  #1,%d0
        move.l  %d0,-(%sp)
        pea     0x400b39ef               | "R%d-%s"
        pea     sm_base
        jsr     0x40013a08               | sprintf
        lea     16(%sp),%sp
        bra     sm_mn_from
| sm_mkedit: the same from a name already in sm_base (sm_edname).
sm_mkedit:
        lea     -8(%sp),%sp
        movem.l %d2/%a2,(%sp)
sm_mn_from:
        moveq   #1,%d2
sm_mn_try:
        moveq   #1,%d0
        cmp.l   %d0,%d2
        bne     sm_mn_suffix
        pea     sm_base
        pea     sm_fmt_plain
        bra     sm_mn_print
sm_mn_suffix:
        move.l  %d2,-(%sp)
        pea     sm_base
        pea     sm_fmt_suffix
sm_mn_print:
        pea     S_NAME
        jsr     0x40013a08
        lea     12(%sp),%sp
        moveq   #1,%d0
        cmp.l   %d0,%d2
        beq     sm_mn_path
        addq.l  #4,%sp
sm_mn_path:
        pea     S_NAME                   | always the pool (see the save)
        pea     SET_DIR
        pea     0x400b3a85               | "%s/AUDIO/%s.wav"
sm_mn_fmt:
        pea     sm_path
        jsr     0x40013a08
        lea     16(%sp),%sp
        pea     sm_path
        movea.l FILE_EXISTS,%a0
        jsr     (%a0)
        addq.l  #4,%sp
        tst.l   %d0
        beq     sm_mn_done
        addq.l  #1,%d2
        moveq   #99,%d0
        cmp.l   %d0,%d2
        ble     sm_mn_try
sm_mn_done:
        movem.l (%sp),%d2/%a2
        lea     8(%sp),%sp
        rts

sm_fmt_plain:
        .asciz  "SMPL/%s"
sm_fmt_suffix:
        .asciz  "SMPL/%s-%d"
sm_fmt_dir:
        .asciz  "%s/AUDIO/SMPL"
        .balign 4
sm_pin:
        .long   0                        | the take's slot (0x80 + n) the editor stays on; 0 none
sm_live:
        .long   0                        | bit n: buffer n's run (from its first take start to idle)
sm_open:
        .long   0                        | bit n: open the editor on buffer n
sm_save:
        .long   0                        | bit n: buffer n's run has ended, save it
sm_busy:
        .long   0                        | the save in flight: ticks left without progress; 0 = none
sm_cur:
        .long   0                        | the buffer being saved
sm_nstate:
        .long   0                        | 0 idle, 5 scanning, 3 gaining, 2 save sm_cur
sm_spos:
        .long   0                        | the scan's next frame
sm_held:
        .long   0                        | 1: a save holds SAVE SAMPLES TO at AUD POOL
sm_saveto:
        .long   0                        | ... and this is the user's value to put back
sm_tlen:
        .long   0                        | the take's length in frames
sm_peak:
        .long   0                        | the scan's peak so far, |sample| in the take's format
sm_gain:
        .long   0                        | the gain (unity 2048)
sm_gm:
        .long   0                        | ... as m / 2^sm_gs, the multiplier the gain loop uses
sm_gs:
        .long   0
sm_gpos:
        .long   0                        | the gain's next frame; -1 none yet
sm_wpos:
        .long   0                        | the writer's frame (sm_wtap); -1 none yet
sm_wlast:
        .long   0                        | ... as sm_auto last saw it
sm_wtot:
        .long   0                        | the writer's frames in all; 0 not writing yet
sm_dropcb:
        .long   0                        | a dropped edit's done callback, run on the next UI tick
sm_toast:
        .long   0                        | 1: show SAVING TAKE.. on the next UI tick
sm_s_saving:
        .asciz  "SAVING TAKE.."
        .balign 4
sm_stoast:
        .long   0                        | 1: show NO SOUND IN TAKE on the next UI tick
sm_s_silent:
        .asciz  "NO SOUND IN TAKE"
sm_f_proc:
        .asciz  "PROCESSING %d%s"           | stock's sprintf has no %% (printed "SAVING TAKE 99")
sm_f_save:
        .asciz  "SAVING TAKE %d%s"
sm_s_pct:
        .asciz  "%"
        .balign 4
sm_pbuf:
        .space  32
sm_ptick:
        .long   0                        | UI ticks to the next PROCESSING TAKE..
        .balign 4
sm_base:
        .space  64
sm_path:
        .space  256

| ==== TRIG TAKES: A NUMBER OF LOOPS (Part 3) ========================================
| SAMPLER / RESAMPLE ignore recorder trigs (sm_disp): the red key alone takes on them.
| On a LOOPER / RELOOPER track RLEN counts loops: a recorder trig records RLEN loops of the
| track (1 .. 64; MAX: until STOP) as ONE take, then stops; the auto-save and the editor
| (Part 2) see one run. Further recorder trigs on that track are ignored until the
| sequencer stops, so a pattern that loops does not record over the take. A key take is
| free length whatever RLEN says.
| The per-frame recorder dispatcher (0x4000d2a0) calls the arm 0x40005ff0(track, word)
| for every recorder word: a start has 0x10; a recorder trig's start has 0x200 and not
| 0x8000 (port, 24 Oct 2026: trig 0x7210 / 0x7218, the A/B key 0x9010; the low nibble
| is the sample in the frame). Stock re-arms at each trig, each pass over the last.
| Here, on our tracks:
|   * the recorder sees RLEN MAX: the per-frame copy of the recorder setup
|     (0x80000c94 -> 0x80000cf4 + 96 page, memcpy at 0x4000cae2) gets RLEN 64 for
|     each of our tracks (sm_pub), so every take runs until told to stop (the
|     engine reads that RLEN while recording, not only at the arm: port, 24 Oct
|     2026, RLEN 1 cut a key take at one step);
|   * a trig start while our trig run records is not passed on (the take goes on) but
|     counted; the RLEN + 1'th ends it: the stop word 0x80, at the trig's own sample.
        .set    DISP_RET, 0x4000d35e
        .set    ARM, 0x40005ff0
        .set    PUB_REC, 0x80000cf4      | the published recorder setup, 12 per track
        .set    PUB_PAGE, 0x800000e0     | ... its page (x 96)
        .set    TRANSPORT, 0x800065b8    | 1 = the sequencer plays
        .global sm_disp, sm_pub

| 0x4000cae2 ("jsr" detour): the per-frame publish of the recorder setup, memcpy(dest,
| 0x80000c94, 0x60); then RLEN := MAX in the copy for each of our tracks (sm_mask,
| kept by the UI tick). Keeps d2-d7/a2-a6.
sm_pub:
        move.l  12(%sp),-(%sp)
        move.l  12(%sp),-(%sp)
        move.l  12(%sp),-(%sp)
        jsr     0x400208d4               | displaced: memcpy
        lea     12(%sp),%sp
        move.l  sm_mask,%d1
        beq     sm_pb_out
        move.l  PUB_PAGE,%d0
        mulu.w  #96,%d0
        addi.l  #PUB_REC+R_RLEN,%d0
        movea.l %d0,%a0
        moveq   #0,%d0
sm_pb_loop:
        btst    %d0,%d1
        beq     sm_pb_next
        move.l  %d0,-(%sp)
        mulu.w  #12,%d0
        move.l  %d1,-(%sp)
        moveq   #RLEN_MAX,%d1
        move.b  %d1,(%a0,%d0.l)
        move.l  (%sp)+,%d1
        move.l  (%sp)+,%d0
sm_pb_next:
        addq.l  #1,%d0
        cmpi.l  #8,%d0
        blt     sm_pb_loop
sm_pb_out:
        rts

| 0x4000d356 (jmp, 8 B): displaced `move.l %d1,-(%sp); move.l %d3,-(%sp); jsr (%a4);
| addq.l #8,%sp`: d1 = the word, d3 = the track. Keeps d2-d7/a2-a6.
sm_disp:
        move.l  %d2,-(%sp)
        move.l  %d1,-(%sp)               | the word, 0(%sp)
        move.l  %d3,%d2
        bsr     sm_kind
        beq     sm_dp_stock              | not ours
        move.l  (%sp),%d1
        btst    #4,%d1
        beq     sm_dp_stock              | not a start
        move.l  %d3,%d0
        bsr     sm_locked
        beq     sm_dp_unlk
        moveq   #1,%d0                   | its buffer is still saving: no take (SAVE LOCK)
        move.l  %d0,sm_toast
        bra     sm_dp_skip
sm_dp_unlk:
        move.l  (%sp),%d1                | the word again (sm_locked used d1)
        btst    #15,%d1
        bne     sm_dp_free               | a key
        btst    #9,%d1
        beq     sm_dp_free
| a recorder trig's start: LOOPER / RELOOPER only. SAMPLER / RESAMPLE are the red key's,
| tap in, tap out (Heath, 8 Nov 2026): a recorder trig on them starts nothing.
        move.l  %d3,%d2
        bsr     sm_isloop
        beq     sm_dp_skip
        move.l  sm_tdone,%d0
        btst    %d3,%d0
        bne     sm_dp_skip               | this run is done: until the sequencer stops
        move.l  sm_trun,%d0
        btst    %d3,%d0
        beq     sm_dp_first
        lea     sm_tcount(%pc),%a0
        mvz.b   (%a0,%d3.l),%d0
        addq.l  #1,%d0
        move.b  %d0,(%a0,%d3.l)          | loops recorded
        move.l  %d0,%d2
        bsr     ml_part
        move.l  %d3,%d0
        mulu.w  #12,%d0
        addi.l  #REC_OFF+R_RLEN,%d0
        mvz.b   (%a0,%d0.l),%d0          | RLEN raw: loops - 1; 64 = MAX
        cmpi.l  #RLEN_MAX,%d0
        bge     sm_dp_skip               | MAX: until STOP
        addq.l  #1,%d0
        cmp.l   %d0,%d2
        blt     sm_dp_skip               | not yet
        move.l  sm_trun,%d0              | the last loop: stop at this trig's sample
        bclr    %d3,%d0
        move.l  %d0,sm_trun
        move.l  sm_tdone,%d0
        bset    %d3,%d0
        move.l  %d0,sm_tdone
        move.l  (%sp),%d1
        moveq   #15,%d0
        and.l   %d0,%d1
        ori.l   #0x80,%d1
        move.l  %d1,(%sp)
        bra     sm_dp_stock
sm_dp_first:
        bset    %d3,%d0
        move.l  %d0,sm_trun
        lea     sm_tcount(%pc),%a0
        clr.b   (%a0,%d3.l)
sm_dp_free:
sm_dp_stock:
        move.l  (%sp),%d1
        move.l  %d1,-(%sp)
        move.l  %d3,-(%sp)
        jsr     ARM
        addq.l  #8,%sp
sm_dp_skip:
sm_dp_out:
        addq.l  #4,%sp
        move.l  (%sp)+,%d2
        jmp     DISP_RET

| sm_trig_tick, from sm_auto (the UI tick): a trig run whose recorder went idle (STOP,
| memory full) is done; the sequencer stopped clears done.
sm_trig_tick:
        moveq   #0,%d2                   | sm_mask: our tracks
        moveq   #0,%d3
sm_tt_mask:
        bsr     sm_kind
        beq     sm_tt_mnext
        bset    %d2,%d3
sm_tt_mnext:
        addq.l  #1,%d2
        moveq   #8,%d0
        cmp.l   %d0,%d2
        blt     sm_tt_mask
        move.l  %d3,sm_mask
        moveq   #1,%d1
        cmp.l   TRANSPORT,%d1
        beq     sm_tt_play
        clr.l   sm_tdone
sm_tt_play:
        moveq   #0,%d2
sm_tt_loop:
        move.l  sm_trun,%d0
        btst    %d2,%d0
        beq     sm_tt_next
        move.l  %d2,-(%sp)
        jsr     0x40004268               | non-zero = armed or recording
        addq.l  #4,%sp
        tst.b   %d0
        bne     sm_tt_next
        move.l  sm_trun,%d0
        bclr    %d2,%d0
        move.l  %d0,sm_trun
        moveq   #1,%d1
        cmp.l   TRANSPORT,%d1
        bne     sm_tt_next
        move.l  sm_tdone,%d0
        bset    %d2,%d0
        move.l  %d0,sm_tdone
sm_tt_next:
        addq.l  #1,%d2
        moveq   #8,%d0
        cmp.l   %d0,%d2
        blt     sm_tt_loop
        rts

        .balign 4
sm_trun:
        .long   0                        | bit n: a trig run records on track n
sm_tdone:
        .long   0                        | bit n: its run is over; trigs ignored until STOP
sm_mask:
        .long   0                        | bit n: track n is SMPL / RSMP (the UI tick)
sm_tcount:
        .byte   0, 0, 0, 0, 0, 0, 0, 0   | loops recorded in the run, per track
        .balign 4
| ==== THRESHOLD ON RSMP (ACCLOOP10) ================================================
| REC THRESHOLD (modules/rec-threshold, TRIG THR) measures the inputs. An RSMP track
| records its SRC3 source instead, so its level check and the IN meter ask here
| (thresh.s src_peak, a weak reference: without SMPL it measures the inputs as before).
| The block is where the stock recorder reads SRC3 (0x400075de-0x4000760e): T1..T8
| the read-back half 0x800000e4 names, 0x80003190 + 0x80 * (half * 8 + track); MAIN /
| CUE channel 6's buffer, 0x80005e60 + 0x80 * (0 / 1). 16 samples of an L and an R
| long, left-justified 24 bits, as in the input pages.
| sm_thr_src: d1 = a track -> a1 = its RSMP source's block, or 0 (not RSMP, SRC3 "-").
| Preserves every other register. Called from the frame interrupt.
        .global sm_thr_src
        .set    RDBK, 0x80003190         | the tracks' read-back: two halves of 8 x 0x80
        .set    RDBK_HALF, 0x800000e4    | the half the recorder reads
        .set    BUS6, 0x80005e60         | MAIN +0x00, CUE +0x80
sm_thr_src:
        lea     -12(%sp),%sp
        movem.l %d0/%d2/%a0,(%sp)
        suba.l  %a1,%a1
        move.l  %d1,%d2
        bsr     sm_kind
        cmpi.l  #K_RSMP,%d0
        bne     sm_ts_out
        bsr     ml_part
        move.l  %d1,%d0
        mulu.w  #12,%d0
        adda.l  %d0,%a0
        adda.l  #REC_OFF,%a0
        mvz.b   R_SRC3(%a0),%d0          | - 0, T1..T8 1..8, MAIN 9, CUE 10
        tst.l   %d0
        beq     sm_ts_out
        cmpi.l  #MAIN,%d0
        bcc     sm_ts_bus
        subq.l  #1,%d0                   | the track
        move.l  RDBK_HALF,%d2
        lsl.l   #3,%d2
        add.l   %d2,%d0
        lsl.l   #7,%d0
        addi.l  #RDBK,%d0
        movea.l %d0,%a1
        bra     sm_ts_out
sm_ts_bus:
        subi.l  #MAIN,%d0
        moveq   #1,%d2
        cmp.l   %d2,%d0
        bhi     sm_ts_out                | past CUE: nothing
        lsl.l   #7,%d0
        addi.l  #BUS6,%d0
        movea.l %d0,%a1
sm_ts_out:
        movem.l (%sp),%d0/%d2/%a0
        lea     12(%sp),%sp
        rts

sm_remap:
        .long   0                        | bit 0: A/B's press set the internal flag; bit 1: C/D's
sm_here:
        .byte   0, 0, 0, 0               | sm_rsmp_here's answer

sm_name:
        .asciz  "SAMPLER"
rs_name:
        .asciz  "RESAMPLE"
lp_name:
        .asciz  "LOOPER"
rl_name:
        .asciz  "RELOOPER"
        .balign 4
lp_row:
        .byte   'L', 'P', 1, K_SMPL      | the signature "LP", 1; SAMPLER's kind, no auto-save
        .long   lp_name
        .long   0
        .long   sm_page
        .byte   F_LOOP, 0, 0, 0
rl_row:
        .byte   'R', 'L', 1, K_RSMP      | the signature "RL", 1; RESAMPLE's kind, no auto-save
        .long   rl_name
        .long   0
        .long   sm_page
        .byte   F_LOOP, 0, 0, 0
sm_row:
        .byte   'S', 'M', 1, K_SMPL      | the signature "SM", 1; kind SMPL
        .long   sm_name
        .long   0
        .long   sm_page
        .byte   0, 0, 0, 0
rs_row:
        .byte   'R', 'S', 1, K_RSMP      | the signature "RS", 1; kind RSMP
        .long   rs_name
        .long   0
        .long   sm_page
        .byte   0, 0, 0, 0
| THE ROWS after the stock five, in list order.
ml_rows:
        .long   sm_row
        .long   rs_row
        .long   lp_row
        .long   rl_row
| SRC SETUP's name table (the lea at 0x4003c928 points here): the stock five, copied
| by fm_tick, and the rows' names.
fm_src_names:
        .fill   5+ML_COUNT, 4, 0

| ==== TRASH TAKE (Heath, 7 Nov 2026) ===============================================
| The audio editor's FILE page on a SAMPLER / RESAMPLE take gets a seventh entry, TRASH
| TAKE: after a YES the take's file moves to <set>/AUDIO/SMPL/TRASH (made the first time)
| and the buffer is cleared as CLEAR SLOT's one-step clear does, so the track is empty
| again. Nothing is deleted; the TRASH folder is emptied from a computer. A name already
| in TRASH (a retake in the same minute gets the same name) moves as <name>-2, -3 ...
| The FILE page (0x40076de8 list init, 0x40076a2e draw, 0x40076efc dispatch) indexes a
| table of (name, handler) pairs, 0x400b2d92, six for a recording / FLEX slot. The draw
| and the dispatch read sm_ft_table (the same six, then ours); the list init counts 7
| only where sm_tr_ok says yes, so every other slot's page is the stock six.
        .set    ED_KIND, 0x46c8d1a0      | the editor's object kind (1 FLEX / recording, 4)
        .set    SLOT_REC, 0x100b14f0     | slot records, 1096 B; +0 the file it is tied to,
                                         | project-relative ("../AUDIO/SMPL/R1-...wav")
        .set    FS_MOVE, 0x46c82446      | (from, to) -> d0 < 0 failed: the browser's MOVE FILE
                                         | (0x4006bf1a)
        .set    DIALOG, 0x4006d57c       | (title, 2, lines, 3, callback): CLEAR SLOT's dialog
                                         | (0x40021c64); the callback gets 0 on YES
        .global sm_ft_count, sm_ft_table, sm_trash, sm_tr_cb, sm_s_trashed

| 0x40076dfc (jmp, 8 B), the FILE page's list init on a recording / FLEX slot: displaced
| `pea 6; pea 6` (the rows, the rows visible).
sm_ft_count:
        bsr     sm_tr_ok
        beq     sm_fc_six
        pea     7.w
        bra     sm_fc_vis
sm_fc_six:
        pea     6.w
sm_fc_vis:
        pea     6.w
        jmp     0x40076e04

| sm_tr_ok: d0 nonzero (Z clear) when the editor shows track n's own buffer (0x80 + n),
| track n is SAMPLER or RESAMPLE, and the buffer is tied to a file in a SMPL folder.
| Keeps every other register.
sm_tr_ok:
        lea     -12(%sp),%sp
        movem.l %d1-%d2/%a0,(%sp)
        move.l  ED_KIND,%d0
        moveq   #1,%d1
        cmp.l   %d1,%d0
        beq     sm_to_kind
        moveq   #4,%d1
        cmp.l   %d1,%d0
        bne     sm_to_no
sm_to_kind:
        move.l  ED_SHOWN,%d2
        subi.l  #128,%d2
        moveq   #8,%d1
        cmp.l   %d1,%d2
        bcc     sm_to_no
        bsr     sm_kind
        beq     sm_to_no
        move.l  ED_SHOWN,%d0
        bsr     sm_tr_rec
        bsr     sm_tr_insmpl
        bra     sm_to_out
sm_to_no:
        moveq   #0,%d0
sm_to_out:
        movem.l (%sp),%d1-%d2/%a0
        lea     12(%sp),%sp
        tst.l   %d0
        rts

| sm_tr_rec: d0 = a slot -> a0 = its record (the tied file's path at +0). Uses d0/d1.
sm_tr_rec:
        move.l  #1096,%d1
        mulu.l  %d1,%d0
        addi.l  #SLOT_REC,%d0
        movea.l %d0,%a0
        rts

| sm_tr_insmpl: a0 = a path -> d0 = 1 when it has "/SMPL/" in it, else 0. Uses d0/d1/a0.
sm_tr_insmpl:
        move.b  (%a0)+,%d0
        beq     sm_ti_no
        cmpi.b  #'/',%d0
        bne     sm_tr_insmpl
        move.b  (%a0),%d1                | "SMPL", byte by byte (a0 may be odd)
        lsl.l   #8,%d1
        move.b  1(%a0),%d1
        lsl.l   #8,%d1
        move.b  2(%a0),%d1
        lsl.l   #8,%d1
        move.b  3(%a0),%d1
        cmpi.l  #0x534d504c,%d1          | "SMPL"
        bne     sm_tr_insmpl
        move.b  4(%a0),%d1
        cmpi.b  #'/',%d1
        bne     sm_tr_insmpl
        moveq   #1,%d0
        rts
sm_ti_no:
        moveq   #0,%d0
        rts

| TRASH TAKE's handler (sm_ft_table): the dialog. Called as the stock handlers are, no
| arguments, from the UI task.
sm_trash:
        bsr     sm_tr_ok
        beq     sm_tr_none
        move.l  ED_SHOWN,%d0
        move.l  %d0,sm_tr_slot
        subi.l  #128,%d0
        bsr     sm_locked
        bne     sm_tr_saving
        pea     sm_tr_cb
        pea     3.w
        pea     sm_tr_lines
        pea     2.w
        pea     sm_s_trash
        jsr     DIALOG
        lea     20(%sp),%sp
        rts
sm_tr_none:
        pea     48.w
        pea     sm_s_notake
        bra     sm_tr_say
sm_tr_saving:
        pea     48.w
        pea     sm_s_saving
sm_tr_say:
        jsr     0x4005a2b8
        addq.l  #8,%sp
        rts

| The dialog's callback (answer): 0 = YES. The file moves first; the buffer is cleared
| only once it has moved, so a failed move changes nothing.
sm_tr_cb:
        tst.l   4(%sp)
        bne     sm_tc_ret
        lea     -16(%sp),%sp
        movem.l %d2-%d3/%a2-%a3,(%sp)
        move.l  sm_tr_slot,%d0
        subi.l  #128,%d0
        bsr     sm_locked
        bne     sm_tc_saving
        move.l  sm_tr_slot,%d0
        bsr     sm_tr_rec
        tst.b   (%a0)
        beq     sm_tc_none
| a2 = the file's name (after the path's last '/'), a3 = its extension ("" if none)
        movea.l %a0,%a2
sm_tc_slash:
        move.b  (%a0)+,%d0
        beq     sm_tc_named
        cmpi.b  #'/',%d0
        bne     sm_tc_slash
        movea.l %a0,%a2
        bra     sm_tc_slash
sm_tc_named:
        subq.l  #1,%a0
        movea.l %a0,%a3                  | the NUL
        movea.l %a2,%a1
sm_tc_dot:
        move.b  (%a1)+,%d0
        beq     sm_tc_stem
        cmpi.b  #'.',%d0
        bne     sm_tc_dot
        lea     -1(%a1),%a3
        bra     sm_tc_dot
sm_tc_stem:                              | sm_tr_stem <- the name up to its extension
        lea     sm_tr_stem,%a1
        movea.l %a2,%a0
        moveq   #95,%d1
sm_tc_copy:
        cmpa.l  %a3,%a0
        beq     sm_tc_cut
        move.b  (%a0)+,(%a1)+
        subq.l  #1,%d1
        bne     sm_tc_copy
sm_tc_cut:
        clr.b   (%a1)
| the source, which must be there
        move.l  %a2,-(%sp)
        pea     SET_DIR
        pea     sm_fmt_tsrc
        pea     sm_path
        jsr     0x40013a08               | sprintf
        lea     16(%sp),%sp
        pea     sm_path
        movea.l FILE_EXISTS,%a0
        jsr     (%a0)
        addq.l  #4,%sp
        tst.l   %d0
        beq     sm_tc_none
| the TRASH folder
        pea     SET_DIR
        pea     sm_fmt_tdir
        pea     sm_tr_dst
        jsr     0x40013a08
        lea     12(%sp),%sp
        pea     sm_tr_dst
        movea.l FILE_EXISTS,%a0
        jsr     (%a0)
        addq.l  #4,%sp
        tst.l   %d0
        bne     sm_tc_dir
        pea     sm_tr_dst
        movea.l FS_MKDIR,%a0
        jsr     (%a0)
        addq.l  #4,%sp
sm_tc_dir:
| the destination: TRASH/<name>, else TRASH/<stem>-2<ext> .. -99
        moveq   #1,%d2
sm_tc_try:
        moveq   #1,%d0
        cmp.l   %d0,%d2
        bne     sm_tc_sfx
        move.l  %a2,-(%sp)
        pea     SET_DIR
        pea     sm_fmt_tdst
        pea     sm_tr_dst
        jsr     0x40013a08
        lea     16(%sp),%sp
        bra     sm_tc_test
sm_tc_sfx:
        move.l  %a3,-(%sp)
        move.l  %d2,-(%sp)
        pea     sm_tr_stem
        pea     SET_DIR
        pea     sm_fmt_tsfx
        pea     sm_tr_dst
        jsr     0x40013a08
        lea     24(%sp),%sp
sm_tc_test:
        pea     sm_tr_dst
        movea.l FILE_EXISTS,%a0
        jsr     (%a0)
        addq.l  #4,%sp
        tst.l   %d0
        beq     sm_tc_move
        addq.l  #1,%d2
        moveq   #100,%d0
        cmp.l   %d0,%d2
        bcs     sm_tc_try
        bra     sm_tc_err
sm_tc_move:
        pea     sm_tr_dst
        pea     sm_path
        movea.l FS_MOVE,%a0
        jsr     (%a0)
        addq.l  #8,%sp
        tst.l   %d0
        bmi     sm_tc_err
| the take's .ot (its save writes one beside it) follows, under the same name; if it is
| not there, or does not move, the take is trashed all the same
        pea     sm_tr_stem
        pea     SET_DIR
        pea     sm_fmt_tsot
        pea     sm_path
        jsr     0x40013a08
        lea     16(%sp),%sp
        pea     sm_path
        movea.l FILE_EXISTS,%a0
        jsr     (%a0)
        addq.l  #4,%sp
        tst.l   %d0
        beq     sm_tc_clear
        move.l  %d2,-(%sp)
        pea     sm_tr_stem
        pea     SET_DIR
        moveq   #1,%d0
        cmp.l   %d0,%d2
        bne     sm_tc_otsfx
        pea     sm_fmt_tdot
        bra     sm_tc_otfmt
sm_tc_otsfx:
        pea     sm_fmt_tdsot
sm_tc_otfmt:
        pea     sm_tr_dst
        jsr     0x40013a08               | the plain form ignores the -%d's argument
        lea     20(%sp),%sp
        pea     sm_tr_dst
        pea     sm_path
        movea.l FS_MOVE,%a0
        jsr     (%a0)
        addq.l  #8,%sp
sm_tc_clear:
| moved: untie the buffer from its file and clear it (CLEAR SLOT's two confirms)
        move.l  sm_tr_slot,-(%sp)
        jsr     0x40025188
        jsr     0x4002557c
        addq.l  #4,%sp
        pea     48.w
        pea     sm_s_trashed
        jsr     0x4005a2b8
        addq.l  #8,%sp
        jsr     0x4006dbe8               | as RECORDING CLEARED!'s tail (0x40021d22)
        bra     sm_tc_out
sm_tc_saving:
        lea     sm_s_saving,%a0
        bra     sm_tc_say
sm_tc_none:
        lea     sm_s_notake,%a0
        bra     sm_tc_say
sm_tc_err:
        lea     0x400b665f,%a0           | ERROR MOVING FILE (stock)
sm_tc_say:
        pea     48.w
        move.l  %a0,-(%sp)
        jsr     0x4005a2b8
        addq.l  #8,%sp
sm_tc_out:
        movem.l (%sp),%d2-%d3/%a2-%a3
        lea     16(%sp),%sp
sm_tc_ret:
        rts

        .balign 4
| The FILE page's table on a recording / FLEX slot: stock's six (0x400b2d92), then ours.
sm_ft_table:
        .long   0x400b71a2, 0x40076dcc   | LOAD NEW SAMPLE
        .long   0x400b3b01, 0x40076d70   | SAVE SAMPLE SETTINGS
        .long   0x400b71b2, 0x40076cf0   | SAVE SAMPLE COPY
        .long   0x400b71c3, 0x40076c70   | SAVE AND ASSIGN SAMPLE
        .long   0x400b3733, 0x40076c58   | CLEAR SLOT
        .long   0x400b71da, 0x40076ae8   | REVERT TO SAVED FILE
        .long   sm_s_trash, sm_trash     | TRASH TAKE
sm_tr_lines:
        .long   sm_s_tl1, sm_s_tl2
sm_tr_slot:
        .long   0
sm_s_trash:
        .asciz  "TRASH TAKE"
sm_s_tl1:
        .asciz  "MOVE THE TAKE TO"
sm_s_tl2:
        .asciz  "AUDIO/SMPL/TRASH?"
sm_s_trashed:
        .asciz  "TAKE TRASHED!"
sm_s_notake:
        .asciz  "NO TAKE FILE"
sm_fmt_tsrc:
        .asciz  "%s/AUDIO/SMPL/%s"
sm_fmt_tdir:
        .asciz  "%s/AUDIO/SMPL/TRASH"
sm_fmt_tdst:
        .asciz  "%s/AUDIO/SMPL/TRASH/%s"
sm_fmt_tsfx:
        .asciz  "%s/AUDIO/SMPL/TRASH/%s-%d%s"
sm_fmt_tsot:
        .asciz  "%s/AUDIO/SMPL/%s.ot"
sm_fmt_tdot:
        .asciz  "%s/AUDIO/SMPL/TRASH/%s.ot"
sm_fmt_tdsot:
        .asciz  "%s/AUDIO/SMPL/TRASH/%s-%d.ot"
        .balign 4
sm_tr_stem:
        .space  96
sm_tr_dst:
        .space  256
