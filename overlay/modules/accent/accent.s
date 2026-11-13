| accent.s -- ACCENT: TR-909-style soft / full steps in GRID RECORDING.
|
| A soft step is a sample trig (mask 0) whose AMP VOL lock is below the
| Part's AMP VOL. No new data: the soft level is an ordinary lock, so it
| saves, copies, pastes and undoes as every lock does.
|
| acc_led  (grid painter 0x40034e5e, between the colour pass and the level
|          pass): a soft step's red LED gets level 5 instead of 15.
| acc_tap  (trig-key release 0x400601aa, the audio path that removes the
|          trig): a FULL trig is turned soft instead of removed, so a tap
|          cycles off -> full -> soft -> off. A soft trig goes on to stock's
|          removal, which wipes the step's 32 lock bytes.
|
| Soft VOL = round(PartVOL / sqrt 2) = -6 dB under AMP VOL's (v/127)^2 law,
| (v*181 + 128) >> 8, kept one below PartVOL so it always reads as soft.
| Audio tracks only: the painter and the release path are gated on
| 0x80000012 == 0 (stock's own MIDI test) and edit state 0.
|
| acc_cue  (CUE press 0x4004e978): with a TRACK key already held, CUE
|          toggles ACCENT and toasts ACCENT ON / OFF instead of cueing. Stock
|          cueing (CUE held first, then TRACK) is untouched. Starts ON at
|          every boot (acc_on is DRAM, not battery-backed).

        .set    DBPTR,     0x46c82456   | current bank's blob
        .set    MIRROR,    0x1001614e   | its battery copy, same offsets
        .set    UI_TRACK,  0x100b14cc
        .set    UI_PTN,    0x100b14d0
        .set    UI_PART,   0x100b14cf
        .set    MIDI_MODE, 0x80000012   | nonzero: MIDI tracks shown
        .set    EDIT,      0x460d5db4   | grid edit state; 0 = trig entry
        .set    PAGE,      0x460d1e04   | shown page 0..3
        .set    LOCKMAP,   0x46c7d48c   | per step: bit t = track t has locks
        .set    DIRTY_OFF, 0x9b332
        .set    DIRTY_G,   0x100f8598
        .set    NOTIFY,    0x40027e00
        .set    PTN_STR,   0x8ed8
        .set    TRK_STR,   0x91a
        .set    PART_STR,  6322
        .set    AMP_VOL,   0x8eea3      | Part: AMP p1 + t*24, VOL = +3
        .set    LOCK_VOL,  0x59+15      | step lock bytes + AMP VOL flat index
        .set    SET_LEVEL, 0x400135b0
        .set    LED_JOIN,  0x40034e66   | painter: braw to the level pass
        .set    TAP_JOIN,  0x400601b0   | release: stock removal goes on
        .set    TAP_DONE,  0x4006066c   | release: handled, clear key flags
        .set    DIM,       5            | stock's dim level (trigless locks)
        .set    HELD,      0x460fab40   | held track keys, bit t (REC TRIG MUTE)
        .set    CUE_HELD,  0x460d168c
        .set    CUE_JOIN,  0x4004e980
        .set    TOAST,     0x4005a2b8   | (string, duration): legal from a key handler

        .text
        .globl  acc_led, acc_tap, acc_cue, acc_on

| ---- 0x4004e978: CUE press ---------------------------------------------------
| Displaced: moveq #1,%d0 ; movel %d0,0x460d168c (the cue-held flag).
acc_cue:
        tstl    HELD
        beq.s   9f
        movel   acc_on,%d0
        eoril   #1,%d0
        movel   %d0,acc_on
        lea     T_OFF:l,%a0
        beq.s   1f
        lea     T_ON:l,%a0
1:      pea     0x30
        movel   %a0,-(%sp)
        jsr     TOAST
        addql   #8,%sp
        rts
9:      moveq   #1,%d0
        movel   %d0,CUE_HELD
        jmp     CUE_JOIN

| ---- 0x40034e5e: grid painter, before the level pass ----------------------
| Displaced: clrl %d2 ; lea 0x400135b0,%a2. Entry sp is the painter's own:
| its 32 LED levels (one long per bit id) are at 44(sp); d6 = keys shown.
acc_led:
        tstl    acc_on
        beq.w   9f
        tstl    EDIT
        bne.w   9f
        tstl    MIDI_MODE
        bne.w   9f
        lea     -24(%sp),%sp
        movem.l %d2-%d5/%a2-%a3,(%sp)
        bsr.w   acc_part_vol
        movel   %d0,%d3
        bsr.w   acc_trac_off
        moveal  DBPTR,%a2
        addal   %d0,%a2                 | a2 = TRAC
        lea     68(%sp),%a3             | levels (44 + our 24)
        movel   PAGE,%d4
        lsll    #4,%d4                  | first step shown
        moveq   #0,%d5                  | key
1:      cmpl    %d6,%d5
        bge.s   8f
        movel   %d4,%d2
        addl    %d5,%d2
        bsr.w   acc_soft
        tstl    %d0
        beq.s   2f
        movel   %d5,%d0
        lsll    #3,%d0                  | red id = 2*key, 4 bytes a level
        moveq   #DIM,%d1
        movel   %d1,(%a3,%d0.l)
2:      addql   #1,%d5
        bra.s   1b
8:      movem.l (%sp),%d2-%d5/%a2-%a3
        lea     24(%sp),%sp
9:      clrl    %d2
        lea     SET_LEVEL,%a2
        jmp     LED_JOIN

| ---- 0x400601aa: release removes a trig (audio) --------------------------
| Displaced: moveal 0x46c82456,%a0. a5 = key 0..15, d7 = its bit.
acc_tap:
        tstl    acc_on
        beq.w   7f
        lea     -16(%sp),%sp
        movem.l %d2-%d3/%a2-%a3,(%sp)
        bsr.w   acc_part_vol
        movel   %d0,%d3
        beq.w   6f                      | VOL 0: nothing softer, remove
        bsr.w   acc_trac_off
        moveal  %d0,%a3                 | TRAC offset, for the mirror
        moveal  DBPTR,%a2
        addal   %d0,%a2
        movel   PAGE,%d2
        lsll    #4,%d2
        addl    %a5,%d2                 | step
        bsr.w   acc_trig
        tstl    %d0
        beq.w   6f                      | not a sample trig: stock
        bsr.w   acc_soft
        tstl    %d0
        bne.w   6f                      | soft: stock removes it
        | full -> soft
        movel   %d3,%d0
        movel   #181,%d1
        mulsl   %d1,%d0
        addil   #128,%d0
        asrl    #8,%d0
        cmpl    %d3,%d0
        blt.s   1f
        movel   %d3,%d0
        subql   #1,%d0
1:      movel   %d2,%d1
        lsll    #5,%d1
        addil   #LOCK_VOL,%d1
        moveb   %d0,(%a2,%d1.l)
        addl    %a3,%d1
        addil   #MIRROR,%d1
        moveal  %d1,%a0
        moveb   %d0,(%a0)
        lea     LOCKMAP,%a0             | stock clears this bit on removal
        moveq   #0,%d0
        moveb   UI_TRACK,%d0
        moveq   #1,%d1
        lsll    %d0,%d1
        moveq   #0,%d0
        moveb   (%a0,%d2.l),%d0
        orl     %d1,%d0
        moveb   %d0,(%a0,%d2.l)
        moveal  DBPTR,%a0
        addal   #DIRTY_OFF,%a0
        moveq   #1,%d0
        movel   %d0,(%a0)
        movel   %d0,DIRTY_G
        jsr     NOTIFY
        movem.l (%sp),%d2-%d3/%a2-%a3
        lea     16(%sp),%sp
        jmp     TAP_DONE
6:      movem.l (%sp),%d2-%d3/%a2-%a3
        lea     16(%sp),%sp
7:      moveal  DBPTR,%a0
        jmp     TAP_JOIN

| ---- helpers ---------------------------------------------------------------

| d0 := pattern*PTN_STR + track*TRK_STR (the TRAC's offset in the blob).
| Clobbers d1.
acc_trac_off:
        moveq   #0,%d0
        moveb   UI_PTN,%d0
        movel   #PTN_STR,%d1
        mulsl   %d1,%d0
        movel   %d0,-(%sp)
        moveq   #0,%d0
        moveb   UI_TRACK,%d0
        movel   #TRK_STR,%d1
        mulsl   %d1,%d0
        addl    (%sp)+,%d0
        rts

| d0 := Part AMP VOL of the current track. Clobbers d1, a0.
acc_part_vol:
        moveal  DBPTR,%a0
        moveq   #0,%d0
        moveb   UI_PART,%d0
        movel   #PART_STR,%d1
        mulsl   %d1,%d0
        addal   %d0,%a0
        addal   #AMP_VOL,%a0
        moveq   #0,%d0
        moveb   UI_TRACK,%d0
        movel   %d0,%d1
        lsll    #4,%d0
        lsll    #3,%d1
        addl    %d1,%d0                 | track*24
        moveq   #0,%d1
        moveb   (%a0,%d0.l),%d1
        movel   %d1,%d0
        rts

| d0 := nonzero when step d2 of TRAC a2 has a sample trig (mask 0, 64-bit
| big-endian: byte 7 - s/8, bit s%8). Clobbers d1.
acc_trig:
        movel   %d2,%d1
        lsrl    #3,%d1
        moveq   #7,%d0
        subl    %d1,%d0
        moveq   #0,%d1
        moveb   (%a2,%d0.l),%d1
        movel   %d2,%d0
        andil   #7,%d0
        btst    %d0,%d1
        sne     %d0
        andil   #1,%d0
        rts

| d0 := nonzero when step d2 of TRAC a2 is soft: a sample trig whose VOL
| lock is below d3 (Part VOL). No lock is 0xff, never below. Clobbers d1.
acc_soft:
        bsr.s   acc_trig
        tstl    %d0
        beq.s   9f
        movel   %d2,%d1
        lsll    #5,%d1
        moveq   #0,%d0
        moveb   LOCK_VOL(%a2,%d1.l),%d0
        cmpl    %d3,%d0
        scs     %d0
        andil   #1,%d0
9:      rts

T_ON:   .asciz  "ACCENT ON"
T_OFF:  .asciz  "ACCENT OFF"

        .data
        .balign 4
acc_on: .long   1                       | ACCENT on; TRACK + CUE toggles
