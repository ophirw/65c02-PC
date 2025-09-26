; defines
;---------
PORTB = $7f90
PORTA = $7f91
DDRB  = $7f92
DDRA  = $7f93
T2CL = $7f98
T2CH = $7f99
SR = $7f9a
ACR = $7f9b
PCR = $7f9c
IFR = $7f9d
IER = $7f9e

E = %00000001
RW = %00000010
RS = %00000100

IFR_SR = %00000100
IFR_T2 = %00100000
IFR_SET = %10000000


; variables
;---------
write_ptr = $0000
read_ptr = $0001
ps2_read_result = $0002
kboard_flags = $0003  ; 7: break code recieved, 6: shift held
input_buffer = $0200

    .org $8000
    nop
    .org $C000

;TODO: 
    ; handle extended codes (0xE0)
    ; check for framing error in SR handler
    ; check for framing error\parity in T2 handler
    ; write framing error handler
    ; handle right-shift, backspace, delete keys
    ; send commands to keyboard (e.g. reset to set as PS2, set LEDs)


reset:
    lda #%00011111
    sta PCR      ; set CA2 output, CA1 input (need to be tied high), CB1 positive going edge. CB2 controlled by SR.
    lda #%11111111
    sta DDRA     ; set all pins in A register to output
    lda #%10111111
    sta DDRB     ; set all pins (except PB6, connected to PS2 clk) in B register to output

    jsr lcd_init
    jsr ps2_init

loop:
    sei
    lda write_ptr
    cmp read_ptr
    cli
    beq loop     ; if read_ptr == write_ptr, no new char:
    jsr READ_BUFFER
    jsr CHR_OUT
    jmp loop


; Subroutines
;------------

; initializes the LCD
; Modifies: flags, A
lcd_init:
    lda #%00111000      ; set 8-bit mode. 2-line display. 5x8 font
    jsr lcd_instruction
    lda #%00001110      ; Turn on display. Turn on cursor. Blink off
    jsr lcd_instruction
    lda #%00000110      ; Write left-to-right. shift cursor. no display shift
    jsr lcd_instruction
    lda #1              ; clear display
    jsr lcd_instruction
    rts

; waits for LCD busy flag to clear
; Modifies: flags
lcd_wait:
    pha
    lda #%00000000
    sta DDRA      ; set all pins in A register to input
_busy:
    lda #RW
    sta PORTB
    lda #(RW | E)                  ; send read instruction to LCD
    sta PORTB
    lda PORTA
    and #%10000000
    bne _busy                      ; if busy flag is set, loop back
    lda #RW                        ; clear E pin
    sta PORTB
    lda #%11111111
    sta DDRA      ; set all pins in A register to output
    pla
    rts

; sends the LCD an instruction from the A register
; Modifies: flags, A
lcd_instruction:
    jsr lcd_wait
    sta PORTA
    lda #0      ; clear RS/E/RW
    sta PORTB
    lda #E      ; set E pin
    sta PORTB  
    lda #0      ; clear E pin
    sta PORTB
    rts

; sends the character in the A register to the LCD
; Modifies: flags
CHR_OUT:
    jsr lcd_wait
    cmp #$0A ; is it a line-feed?
    beq _line_feed
    cmp #$09 ; is it tab?
    beq _tab
    sta PORTA
    pha
    lda #RS        ; set RS pin
    sta PORTB
    lda #(RS | E)  ; set E pin
    sta PORTB
    lda #RS        ; clear E pin
    sta PORTB
    pla
    rts
_line_feed:
    pha
    lda #%11000000 ; change LF to new-line lcd instruction
    jsr lcd_instruction
    pla
    rts
_tab:
    pha
    phx
    lda #" "
    ldx #4
_tab_loop:
    jsr CHR_OUT
    dex
    bne _tab_loop
    plx
    pla
    rts

; initializes the input buffer pointers to make the buffer empty
; Modifies: flags
INIT_BUFFER:
    pha
    lda read_ptr
    sta write_ptr
    pla
    rts

; reads next char from input buffer into A register
; Modifies: flags, A, X
READ_BUFFER:
    ldx read_ptr
    lda input_buffer,X
    inc read_ptr
    rts

; writes the character in the A register to the input buffer, if there is space
; Modifies: flags, X
WRITE_BUFFER:
    pha
    lda write_ptr
    tax
    ; check for buffer full condition
    inc
    cmp read_ptr        ; if next write would make buffer full, skip write
    beq _buffer_full
    pla
    sta input_buffer,X
    inc write_ptr
    jmp _end_write
_buffer_full:
    pla
_end_write:
    rts

; Loads timer 2 with the value in A (low byte) and 0 (high byte)
; Modifies: flags
load_t2:
    sta T2CL
    stz T2CH
    rts

; Initializes PS/2 interface by setting up SR and T2, enabling interrupts, and initializing buffer
; Modifies: flags, A
ps2_init:
    lda #%00101100
    sta ACR       ; set T2 count pulses on PB6, set SR to shift in under external clock on CB1. diasble all others
    jsr INIT_BUFFER
    lda #0
    sta kboard_flags
    jsr ps2_prepare_for_character
    lda #%01111111
    sta IER       ; disable all interrupts
    lda #(IFR_SET | IFR_SR | IFR_T2)
    sta IER       ; enable interrupts on SR and T2
    cli
    rts

; reInitializes Shift register and timer 2 to prepare for receiving a character
; Modifies: flags, A
ps2_prepare_for_character:
    ; ReStart SR
	lda #%00100000
    sta ACR
	lda #%00101100
    sta ACR
	lda SR
    ; set T2 to count 11 bits
    lda #10     
    jsr load_t2
    rts
    
; adds contents of ps2_read_result to input buffer, and hanles kb_flags like shift and ignoring break codes
; Modifies: flags, A, X
ps2_add_to_buffer:
    ldx ps2_read_result
    lda kboard_flags
    ; is break flag set?
    bmi _break_code_set
    ; is the char a break code?
    cpx #$0F  ; ignore 0xF0 break code
    beq _break_code
    ; is the char the shift key?
    cpx #$48  ; check for shift key 0x12 reversed
    beq _shift_pressed
    ; is the shift flag set?
    bit kboard_flags
    bvs _add_shifted
    ; if no break or shift flag set, and not a break code or shift code, add char
    lda keymap_reversed, X
    jsr WRITE_BUFFER
    rts
_break_code_set:
    and #%01111111  ; clear the break kb flag
    sta kboard_flags
    cpx #$48        ; is the char the shift key? code 0x12 reversed
    beq _shift_released
    rts             ; if realesed key is a char, ignore
_shift_released:    ; clear shift kb flag
    and #%10111111
    sta kboard_flags
    rts
_break_code:        ; set break kb flag
    ora #%10000000
    sta kboard_flags
    rts
_shift_pressed:     ; set shift kb flag
    ora #%01000000
    sta kboard_flags
    rts 
_add_shifted:       ; if adding char while shifted, add from shifted keymap
    lda shifted_keymap_reversed, X
    jsr WRITE_BUFFER
    rts

IRQ:
    pha
    phx

    ; check if PS/2 related interrupt
    lda IFR
    and #(IFR_SR | IFR_T2)
    cmp #IFR_T2
    beq _irq_ps2_t2
    cmp #IFR_SR
    beq _irq_ps2_sr
    
    ; if not, just return
    jmp _irq_done

_irq_ps2_sr:
    lda SR ; clear SR interrupt flag and read first 8 bits.
    ; A register now has first 8 bits (start bit 0 (in position 7, MSB), and 7 least significant data bits (in reverse order))
    ; HERE: check for framing error - MSB needs to be 0. use bmi instruction
    sta ps2_read_result
    jmp _irq_done

_irq_ps2_t2:
    bit T2CL; clear t2 interrupt flag
    lda SR  ; read next 3 bits.
    ; A register now has last 3 bits (code MSB in position 2, parity bit in position 1, stop bit 1 in position 0)
    ror     ; rotate right 3 times to put MSB in carry bit, parity in bit 7, stop bit in bit 6
    ; HERE: check for framing error - carry bit needs to be 1. use bcc instruction
    ror
    ror 
    rol ps2_read_result ; put MSB in position 0 of result byte, now contains full byte in reverse order
    ; HERE: check for parity - ps2_read_result has correct bits (in reverse order). A has parity bit in bit 7.
    jsr ps2_add_to_buffer
    jsr ps2_prepare_for_character ; reset T2 and SR counters

_irq_done:
    plx
    pla
    rti

NMI:
    rti

keymap_reversed:
    .byte "??????????????0?" ; 0x00 - 0x0F
    .byte "????????????????" ; 0x10 - 0x1F
    .byte "??o?e?????[?g?6?" ; 0x20 - 0x2F
    .byte "??;?t?7?a???u?*?" ; 0x30 - 0x3F
    .byte "??k?x?????'?b?2?" ; 0x40 - 0x4F
    .byte "??/?v???z?", 0x0A, "?m?3?" ; 0x50 - 0x5F
    .byte "??9?3???1???6???" ; 0x60 - 0x6F
    .byte "`?-?5???2???8???" ; 0x70 - 0x7F
    .byte "??,?c???????n?.?" ; 0x80 - 0x8F
    .byte "??.? ?1???????+?" ; 0x90 - 0x9F
    .byte "??0?4???q?=?y?8?" ; 0xA0 - 0xAF
    .byte 0x09, "?p?r???w?\?7?9?" ; 0xB0 - 0xBF
    .byte "??i?d???????h?5?" ; 0xC0 - 0xCF
    .byte "??l?f?4?s?]?j?-?" ; 0xD0 - 0xDF
    .byte "????????????????" ; 0xE0 - 0xEF
    .byte "????????????????" ; 0xF0 - 0xFF

shifted_keymap_reversed:
    .byte "??????????????)?" ; 0x00 - 0x0F
    .byte "????????????????" ; 0x10 - 0x1F
    .byte "??O?E?????{?G?^?" ; 0x20 - 0x2F
    .byte "??:?T?&?A???U?*?" ; 0x30 - 0x3F
    .byte "??K?X?????", 0x22, "?B?@?" ; 0x40 - 0x4F
    .byte "????V???Z?", 0x0A, "?M?#?" ; 0x50 - 0x5F
    .byte "??(?#???!???^???" ; 0x60 - 0x6F
    .byte "~?_?%???@???*???" ; 0x70 - 0x7F
    .byte "??<?C???????N?>?" ; 0x80 - 0x8F
    .byte "??>? ?!???????+?" ; 0x90 - 0x9F
    .byte "??)?$???Q?+?Y?*?" ; 0xA0 - 0xAF
    .byte "??P?R???W?|?&?(?" ; 0xB0 - 0xBF
    .byte "??I?D???????H?%?" ; 0xC0 - 0xCF
    .byte "??L?F?$?S?}?J?_?" ; 0xD0 - 0xDF
    .byte "????????????????" ; 0xE0 - 0xEF
    .byte "????????????????" ; 0xF0 - 0xFF

; sys vectors
;-------------
    .org $fffa
    .word NMI
    .word reset
    .word IRQ