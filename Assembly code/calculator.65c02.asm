PORTB = $6000
PORTA = $6001
DDRB = $6002
DDRA = $6003
PCR = $600c
IFR = $600d
IER = $600e

E = %10000000
RW = %01000000
RS = %00100000

    .org $0200                  ; DATA segment
    
length_of_operand:  .byte   0   ; 1 byte (char)
first_operand:      .dword  0   ; 4 bytes (int)
second_operand:     .dword  0   ; 4 bytes (int)
operator:           .byte   0   ; 1 byte (char)
result:             .dword  0   ; 4 bytes (int)
operand_digits:     .dword  0   ; 4 bytes (int)

    .org $8000                  ; CODE segment
reset:
    lda #%10011011      ; set CA1, CA2, CB1, CB2 to enable interrupts
    sta IER
    lda #0              ; set button interrupts to negative edge
    sta PCR
    
    lda #%11111111      ; set all pins in B register to output
    sta DDRB
    lda #%11100000      ; set top 3 pins in A register to output
    sta DDRA

    lda #%00111000      ; set 8-bit mode. 2-line display. 5x8 font
    jsr lcd_instruction
    lda #%00001110      ; Turn on display. Turn on cursor. Blink off.
    jsr lcd_instruction
    lda #%00000110      ; Write left-to-right. shift cursor. no display shift.
    jsr lcd_instruction
    lda #1              ; clear display
    jsr lcd_instruction

loop:
    ; TODO: continously print appropriate message and current value of operand/operator/result
    jmp loop

multiply_by_ten: ; assuming number to multiply is in A register
    phx
    clc
    tax
    lda #0
multiply_loop:
    adc #10
    dex
    bne multiply_loop
    plx
    rts

print_digit:
    clc
    adc #"0"
    jsr print_chr

get_operand:
    pha
    phx
    clc
    ldx #0
    lda #0
next_digit:
    adc operand_digits, x
    ; TODO: check if overflow
    jsr multiply_by_ten
    ; TODO: check if overflow
    inx
    cpx length_of_operand
    bne next_digit
    ; TODO: store result (multiple bytes if needed) to 'result'
    plx
    pla
    rts

lcd_wait:
    pha
    lda #%00000000      ; set all pins in B register to input
    sta DDRB
busy:
    lda #RW
    sta PORTA
    lda #(RW | E)       ; send read instruction to LCD
    sta PORTA
    lda PORTB
    and #%10000000
    bne busy            ; if busy flag is set, loop back
    lda #RW             ; clear E pin
    sta PORTA
    lda #%11111111      ; set all pins in B register to output
    sta DDRB
    pla
    rts

lcd_instruction:
    jsr lcd_wait
    sta PORTB
    lda #0      ; clear RS/E/RW
    sta PORTA
    lda #E      ; set E pin
    sta PORTA  
    lda #0      ; clear E pin
    sta PORTA
    rts

print_chr:
    jsr lcd_wait
    sta PORTB
    lda #RS        ; set RS pin
    sta PORTA
    lda #(RS | E)  ; set E pin
    sta PORTA
    lda #RS        ; clear E pin
    sta PORTA
    rts

irq:

    phx
    pha
    ; TODO: check what caused the interrupt and handle it
    ; IF interrupt was caused by increment button
    ldx length_of_operand
    inc operand_digits, x
    lda operand_digits, x
    cmp #$A
    bne exit_irq
    lda #0
    sta operand_digits, x
exit_irq
    pla
    plx
    rti

nmi:
    rti

    .org $fffa
vectors:
    .word nmi
    .word reset
    .word irq