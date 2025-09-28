; TODO: handle extended codes (0xE0)
; TODO: handle right-shift, escape, delete keys
; TODO: send commands to keyboard (e.g. reset to set as PS2, set LEDs)
; TODO: handle non-ascii keys (e.g. ctrl, arrows, home, end) using escape sequences

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

; Loads timer 2 with the value in A (low byte) and 0 (high byte)
; Modifies: flags
load_t2:
    sta T2CL
    stz T2CH
    rts

; 256-long nop loop
; Modifies: flags 
delay:
	phx
	ldx #0
delayloop:
	nop
    dex
    bne delayloop
	plx
	rts


keymap_reversed:
    .byte "??????????????0?" ; 0x00 - 0x0F
    .byte "????????????????" ; 0x10 - 0x1F
    .byte "??o?e?????[?g?6?" ; 0x20 - 0x2F
    .byte "??;?t?7?a???u?*?" ; 0x30 - 0x3F
    .byte "??k?x?????'?b?2?" ; 0x40 - 0x4F
    .byte "??/?v???z?", $0A, "?m?3?" ; 0x50 - 0x5F
    .byte "??9?3?", $08, "?1???6?", $1B, "?" ; 0x60 - 0x6F
    .byte "`?-?5???2???8???" ; 0x70 - 0x7F
    .byte "??,?c???????n?.?" ; 0x80 - 0x8F
    .byte "??.? ?1???????+?" ; 0x90 - 0x9F
    .byte "??0?4???q?=?y?8?" ; 0xA0 - 0xAF
    .byte $09, "?p?r???w?\?7?9?" ; 0xB0 - 0xBF
    .byte "??i?d???????h?5?" ; 0xC0 - 0xCF
    .byte "??l?f?4?s?]?j?-?" ; 0xD0 - 0xDF
    .byte "????????????????" ; 0xE0 - 0xEF
    .byte "???????????????X" ; 0xF0 - 0xFF

shifted_keymap_reversed:
    .byte "??????????????)?" ; 0x00 - 0x0F
    .byte "????????????????" ; 0x10 - 0x1F
    .byte "??O?E?????{?G?^?" ; 0x20 - 0x2F
    .byte "??:?T?&?A???U?*?" ; 0x30 - 0x3F
    .byte "??K?X?????", $22, "?B?@?" ; 0x40 - 0x4F
    .byte "????V???Z?", $0A, "?M?#?" ; 0x50 - 0x5F
    .byte "??(?#?", $08, "?!???^?", $1B, "?" ; 0x60 - 0x6F
    .byte "~?_?%???@???*???" ; 0x70 - 0x7F
    .byte "??<?C???????N?>?" ; 0x80 - 0x8F
    .byte "??>? ?!???????+?" ; 0x90 - 0x9F
    .byte "??)?$???Q?+?Y?*?" ; 0xA0 - 0xAF
    .byte "??P?R???W?|?&?(?" ; 0xB0 - 0xBF
    .byte "??I?D???????H?%?" ; 0xC0 - 0xCF
    .byte "??L?F?$?S?}?J?_?" ; 0xD0 - 0xDF
    .byte "????????????????" ; 0xE0 - 0xEF
    .byte "???????????????X" ; 0xF0 - 0xFF