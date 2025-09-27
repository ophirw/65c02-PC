.setcpu "65c02"

.segment "CODE"
.include "defines.s"

; TODO: add internal virtual state, with a moveable physical state ontop, redraw invalidated cells (this will add scrollability).
; TODO: have the virtual and physical states resizeable, to accomodate different terminal harware
; TODO: change the call to CHR_OUT to instead call the bios
; TODO: handle moving cursor (arrows, enter, etc.) here and not in CHR_OUT.
; TODO: add escape sequences specific to each terminal (e.g. clear, home, tab)

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