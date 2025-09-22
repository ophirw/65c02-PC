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

; variables
;---------
;LCD_RS = $00
write_ptr = $0001
read_ptr = $0002
parity_temp = $0003
ps2_read_result = $0004
input_buffer = $0200

E = %00000001
RW = %00000010
RS = %00000100

    .org $8000
    nop
    .org $C000

reset:
    lda #%00001111
    sta PCR      ; set CA2 output, CA1 input (need to be tiesd high), rest dont care - controlled by shift reg
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
    bne _new_char ; if read_ptr != write_ptr, process new char
    jmp loop
_new_char:
    jsr READ_BUFFER
    jmp loop


; Subroutines
;------------

; initializes the LCD
; Modifies: flags, A
lcd_init:
    ;stz LCD_RS
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

; sends the LCD a packet of data in the A register, instruction/data determined by LCD_RS
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

    ;jsr lcd_wait
    ;sta PORTA
    ;lda LCD_RS          ; clear RS/E/RW
    ;sta PORTB
    ;lda #(LCD_RS | E)   ; set E pin
    ;sta PORTB  
    ;lda LCD_RS          ; clear E pin
    ;sta PORTB
    ;rts

; initializes the PS2 keyboard interface. enables the correct interrupts, and chooses operating mode for T2 and SR
; Modifies: flags, A
ps2_init:
    lda #%10111111
    sta DDRB      ; set all pins (except PB6, connected to PS2 clk) in B register to output
    lda #%00101100
    sta ACR       ; set T2 count pulses on PB6, set SR to shift in under external clock on CB1. diasble all others
    jsr INIT_BUFFER
    jsr ps2_prepare_for_character
    lda #%01111111
    sta IER       ; disable all interrupts
    lda #%10100100
    sta IER       ; enable interrupts on T2 and SR
    rts


; reset Shift register and timer 2 to prepare for receiving a character
; Modifies: flags, A
ps2_prepare_for_character:
    ; Start SR
	;lda #$20 + $00
    ;sta ACR
	lda #$20 + $0c
    sta ACR
	lda SR
    ; Set T2 to interrupt after 11 bits
	lda #10
    sta T2CL
    stz T2CH
    rts

ps2_add_to_buffer:
; The bits of the result byte are now in reverse order
    ; check for 0x00 or 0xFF (error codes)
    ;lda ps2_read_result
    ;beq _error_code
    ;cmp #$ff
    ;beq _error_code
    ; check for 0x0F (break code - 0xF0 reversed)
    ;cmp #$0f
    ;beq _ignore_next
    ; check for 0x07 (extended code - 0xE0 reversed)
    ; check for shift key make/break
    ; convert to ASCII (using a table)
    ;ldx ps2_read_result
    ;lda keymap, X
    ; add to input buffer
    lda ps2_read_result
    jsr WRITE_BUFFER
_error_code:
_ignore_next
    rts

; initializes the input buffer pointers to make the buffer empty
; Modifies: flags
INIT_BUFFER:
    pha
    lda read_ptr
    sta write_ptr
    pla
    rts

; reads next char from input buffer into A register and calls CHR_OUT
; Modifies: flags, A, X
READ_BUFFER:
    ldx read_ptr
    lda input_buffer,X
    inc read_ptr
    jsr CHR_OUT
    rts

; writes the character in the A register to the input buffer, if there is space
; Modifies: flags, X
WRITE_BUFFER:
    pha
    lda write_ptr
    tax
    ;inc
    ;cmp read_ptr        ; if next write would make buffer full, skip write
    ;beq _buffer_full
    pla
    sta input_buffer,X
    inc write_ptr
    ;jmp _end_write
;_buffer_full:
    ;pla
;_end_write:
    rts

; sends the character in the A register to the LCD
; Modifies: flags
CHR_OUT:
    jsr lcd_wait
    sta PORTA
    lda #RS        ; set RS pin
    sta PORTB
    lda #(RS | E)  ; set E pin
    sta PORTB
    lda #RS        ; clear E pin
    sta PORTB
    rts

    ;pha
    ;lda RS
    ;sta LCD_RS      ; set LCD_RS
    ;pla
    ;jsr lcd_instruction
    ;rts

; IRQ handler - reads from PS2 keyboard and stores in input buffer
; Modifies:
IRQ:
    ; Check for VIA interrupts
;	bit IFR
;	bmi _irq_via
;	rti
;_irq_via:
	pha
;	; Check for PS/2 related VIA interrupts
;	lda IFR
;	and #$24
;	bne _irq_via_ps2
;	pla
;	rti
_irq_via_ps2:
	phx
    phy
	; It's either T2 or SR (shouldn't be both) - check for T2 first
	cmp #$20
	bcs _irq_via_ps2_t2
	; Fall through to handle shift register interrupt

; SR interrupt happens after first 8 bits are read - a start bit and the first seven data bits
_irq_via_ps2_sr:
	lda SR	
	; The start bit should have been zero
	;bmi _irq_via_ps2_framingerror
	sta ps2_read_result
	ply
    plx
    pla
    rti

; T2 interrupt happens at the end of the character, read the last few bits, check parity, and add to buffer
_irq_via_ps2_t2:
	bit T2CL    ; clear T2 interrupt flag
	lda SR      ; Read the SR again
	ror         ; The bottom bit is the stop bit, which should be set
    ;bcc _irq_via_ps2_framingerror
	ror	        ; Next is parity - then the last data bit.  Add the data bit to the result byte.
    ror	        ; The parity will move to the bit 7 of A.
    rol ps2_read_result

    ; Check parity
	;and #$80
    ;eor ps2_read_result
    ;lsr
    ;eor ps2_read_result
	;sta parity_temp
    ;lsr
    ;lsr
    ;eor parity_temp
	;and #17
    ;beq _irq_via_ps2_framingerror
	;cmp #17
    ;beq _irq_via_ps2_framingerror
	
	; No framing errors
	jsr ps2_prepare_for_character
	jsr ps2_add_to_buffer
	ply
    plx
    pla
    rti

;_irq_via_ps2_framingerror:
;	; Interrupt the device to resynchronise
;   lda #%00001000
;   sta PORTB ; clock low, LED at PB3 high
;	lda #$ff
;   sta DDRB        
;	jsr delay                  ; at least 100us
;	lda #%10111111
;   sta DDRB  ; release clock
;
;	jsr ps2_prepare_for_character
;	lda #$ff                   ; error code
;   jsr ps2_add_to_buffer
;	ply
;   plx
;   pla
;   rti


; NMI handler - does nothing
NMI:
    rti

; sys vectors
;-------------
    .org $fffa
    .word NMI
    .word reset
    .word IRQ