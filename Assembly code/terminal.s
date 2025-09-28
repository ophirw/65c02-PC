.setcpu "65c02"

.segment "CODE"
.include "defines.s"

; TODO: when adapting to VGA terminal, write general display driver that will:
;   -> add internal virtual state, with a moveable physical state ontop, redraw invalidated cells (this will add scrollability).
;   -> keep track of cursor and handle arrows, enter, etc.
;   -> handle implementing recieved escape sequences 
;       (e.g. home key pressed -> ps2 driver adds home escape sequence to buffer -> when display driver called to print escape sequence, instead move cursor)
; TODO: wrap diaplay, lcd and vga drivers in bios that knows which driver to call and is opaque to other programs.
;   -> program calls CHR_OUT in bios. bios calls display driver to update internal state and mark invalidated cells. 
;       then bios calls specific hardware driver to redraw invalidated cells. 
;   -> this flow allows arbitrary writing location, scrollability, obfuscation of hardware to user programs 
;       and modularity in cases where the hardware routine is blocking and costly to only redraw the screen when there is time to do so.

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