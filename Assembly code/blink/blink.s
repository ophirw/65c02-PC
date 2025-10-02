.setcpu "65c02"
.include "../defines.s"
.segment "CODE"

code_start:
blink_loop:
    lda #$ff
    sta PORTA
    jsr blink_delay
    lda #$00
    sta PORTA
    jsr blink_delay
    jmp blink_loop


blink_delay:
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

.segment "DRIVERS"
.include "../drivers/ps2.s"
.include "../drivers/lcd.s"
.include "../drivers/input_buf.s"

.include "../sys_routines.s"

