    .org $8000
reset:
    lda #$ff    
    sta $6002
loop:
    lda #$55
    sta $6000


    ; wait:
    lda #3
thrice_1:
    ldy #$ff
outer_loop_1:
    ldx #$ff
inner_loop_1:
    dex
    bne inner_loop_1

    dey
    bne outer_loop_1

    sec
    sbc #1
    bne thrice_1


    lda #$00
    sta $6000


    ; wait:
    lda #3
thrice_2:
    ldy #$ff
outer_loop_2:
    ldx #$ff
inner_loop_2:
    dex
    bne inner_loop_2

    dey
    bne outer_loop_2

    sec
    sbc #1
    bne thrice_2


    jmp loop

    .org $fffc
    .word reset
    .word $0000