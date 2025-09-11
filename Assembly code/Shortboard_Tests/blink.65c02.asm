PORTB = $7f90
PORTA = $7f91
DDRB  = $7f92
DDRA  = $7f93
PCR = $7f9c


    .org $8000
reset:
    lda #%00001111
    sta PCR

    lda #%11111111
    sta DDRA

    lda #%11111101
    sta DDRB

loop:
    lda #$aa
    sta PORTA

    jsr delay

    lda #$55
    sta PORTA

    jsr delay

    jmp loop

delay:
    lda #3
_thrice:
    ldy #$ff
_outer_loop:
    ldx #$ff
_inner_loop:
    dex
    bne _inner_loop
    dey
    bne _outer_loop
    sec
    sbc #1
    bne _thrice
    rts

    .org $fffc
    .word reset
    .word $0000