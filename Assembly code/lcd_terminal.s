.setcpu "65c02"

.segment "CODE"
.include "defines.s"

terminal_loop:
    sei
    lda write_ptr
    cmp read_ptr
    cli
    beq terminal_loop    ; if read_ptr == write_ptr, no new char:
    jsr READ_BUFFER
    jsr CHR_OUT
    jmp terminal_loop

.include "drivers/input_buf.s"
.include "drivers/lcd.s"
.include "drivers/ps2.s"
.include "sys_routines.s"