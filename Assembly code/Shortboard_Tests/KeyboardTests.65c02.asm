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
input_buffer = $0200

    .org $8000
    nop
    .org $C000

;TODO: 
    ; add buffer overflow check to WRITE_BUFFER
    ; read actual data from PS/2, not just which intrpt happened
    ; write add_to_buffer subroutine
    ; write code to print buffer contents to LCD
    ; check for framing error in SR handler
    ; check for framing error\parity in T2 handler
    ; write framing error handler
    ; translate scan codes to ascii
    ; handle shift, ctrl, alt keys
    ; send commands to keyboard (e.g. set LEDs)


reset:
    lda #%00001111
    sta PCR      ; set CA2 output, CA1 input (need to be tied high), CB1 positive going edge. CB2 controlled by SR.
    lda #%11111111
    sta DDRA     ; set all pins in A register to output
    lda #%10111111
    sta DDRB     ; set all pins (except PB6, connected to PS2 clk) in B register to output

    jsr lcd_init
    jsr ps2_init


loop:
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
    sta PORTA
    lda #RS        ; set RS pin
    sta PORTB
    lda #(RS | E)  ; set E pin
    sta PORTB
    lda #RS        ; clear E pin
    sta PORTB
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
    ldx write_ptr
    sta input_buffer,X
    inc write_ptr
    rts

; Loads timer 2 with the value in A (low byte) and 0 (high byte)
; Modifies: flags
load_t2:
    sta T2CL
    stz T2CH
    rts

ps2_init:
    cli
    lda #%00101100
    sta ACR       ; set T2 count pulses on PB6, set SR to shift in under external clock on CB1. diasble all others
    jsr INIT_BUFFER
    jsr ps2_prepare_for_character
    lda #%01111111
    sta IER       ; disable all interrupts
    lda #(IFR_SET | IFR_SR | IFR_T2)
    sta IER       ; enable interrupts on SR and T2
    rts

ps2_prepare_for_character:
    ; ReStart SR
	lda #$20 + $00
    sta ACR
	lda #$20 + $0c
    sta ACR
	lda SR
    ; set T2 to count 11 bits
    lda #10     
    jsr load_t2
    rts
    
IRQ:
    pha
    ; check if PS/2 related interrupt
    lda IFR
    and #(IFR_SR | IFR_T2)
    cmp #IFR_T2
    beq _irq_ps2_t2
    cmp #IFR_SR
    beq _irq_ps2_sr
    ; if not, just return
    lda #"?"
    jsr CHR_OUT
    jmp _irq_done
_irq_ps2_sr:
    lda SR ; clear SR interrupt flag
    lda #"S"
    jsr CHR_OUT
    jmp _irq_done
_irq_ps2_t2:
    bit T2CL ; clear t2 interrupt flag
    lda #"T"
    jsr CHR_OUT 
    jsr ps2_prepare_for_character ; reset T2 and SR counters
_irq_done:
    pla
    rti

NMI:
    rti
; sys vectors
;-------------
    .org $fffa
    .word NMI
    .word reset
    .word IRQ