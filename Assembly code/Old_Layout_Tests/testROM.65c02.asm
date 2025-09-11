 .org $8000
reset:
  jsr wait
  jsr write



write:
    ldx #$ff
outer_loop_write:
    ldy #$ff
inner_loop_write:
    sta $6000
    dex
    bne inner_loop_write
    dey
    bne outer_loop_write

    rts



wait:
    lda #3
thrice:
    ldy #$ff
outer_loop:
    ldx #$ff
inner_loop:
    dex
    bne inner_loop

    dey
    bne outer_loop

    sbc #1
    bne thrice

    rts

    .org $fffc
    .word reset
    .word $0000