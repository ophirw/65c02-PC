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
IER = $7f9e


E = %00000001
RW = %00000010
RS = %00000100

    .org $8000
    nop
    .org $C000

; data
;------
    LCD_RS: .res 1
    write_ptr: .res 1
    read_ptr: .res 1
    input_buffer: .res $100

; text
;------
reset:
    lda #%00001111      ; set CA2 output, CA1 input (need to be tiesd high), rest dont care - controlled by shift reg
    sta PCR
    lda #%11111111      ; set all pins in A register to output
    sta DDRA
    lda #%10111111      ; set all pins (except PB6, connected to PS2 clk) in B register to output
    sta DDRB

    jsr lcd_init
    jsr INIT_BUFFER

loop:
    lda write_ptr
    cmp read_ptr
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
    lda #%00000000      ; set all pins in A register to input
    sta DDRA
_busy:
    lda #RW
    sta PORTB
    lda #(RW | E)       ; send read instruction to LCD
    sta PORTB
    lda PORTA
    and #%10000000
    bne _busy            ; if busy flag is set, loop back
    lda #RW             ; clear E pin
    sta PORTB
    lda #%11111111      ; set all pins in A register to output
    sta DDRA
    pla
    rts

; sends the LCD a packet of data in the A register, instruction/data determined by LCD_RS
; Modifies: flags, A
lcd_instruction:
    jsr lcd_wait
    sta PORTA
    lda LCD_RS      ; clear RS/E/RW
    sta PORTB
    lda #E          ; set E pin
    sta PORTB  
    lda LCD_RS      ; clear E pin
    sta PORTB
    rts

; initializes the PS2 keyboard interface. enables the correct interrupts, and chooses operating mode for T2 and SR
; Modifies: flags, A
ps2_init:
    lda #%10111111 : sta DDRB      ; set all pins (except PB6, connected to PS2 clk) in B register to output
    lda #%00101100 : sta ACR       ; set T2 count pulses on PB6, set SR to shift in under external clock on CB1. diasble all others
    jsr INIT_BUFFER
    jsr ps2_prepare_for_character
    lda #%01111111 : sta IER       ; disable all interrupts
    lda #%10100100 : sta IER       ; enable interrupts on T2 and SR
    rts


; reset Shift register and timer 2 to prepare for receiving a character
; Modifies: flags, A
ps2_prepare_for_character:
    ; Start SR
	lda #$20 + $00 : sta ACR
	lda #$20 + $0c : sta ACR
	lda SR
    ; Set T2 to interrupt after 11 bits
	lda #10 : sta T2CL : stz T2CH
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

; sends the character in the A register to the LCD
; Modifies: flags
CHR_OUT:
    pha
    lda RS
    sta LCD_RS      ; set LCD_RS
    pla
    jsr lcd_instruction
    rts

; IRQ handler - reads from PS2 keyboard and stores in input buffer
; Modifies:
IRQ:
    rti

; NMI handler - does nothing
NMI:
    rti

; sys vectors
;-------------
    .org $fffa
    .word NMI
    .word reset
    .word IRQ