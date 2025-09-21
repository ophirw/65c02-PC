PORTB = $7f90
PORTA = $7f91
DDRB  = $7f92
DDRA  = $7f93
PCR = $7f9c

E = %00000001
RW = %00000010
RS = %00000100

    .org $8000
    nop
    .org $C000
reset:
    lda #%00001111
    sta PCR

    lda #%11111111
    sta DDRA

    lda #%10111111
    sta DDRB

    lda #%00111000      ; set 8-bit mode. 2-line display. 5x8 font
    jsr lcd_instruction
    lda #%00001110      ; Turn on display. Turn on cursor. Blink off.
    jsr lcd_instruction
    lda #%00000110      ; Write left-to-right. shift cursor. no display shift.
    jsr lcd_instruction
    lda #1              ; clear display
    jsr lcd_instruction

    jsr print_str

loop:
    jmp loop

message: .asciiz "Hello, World!"

lcd_wait:
    pha
    lda #%00000000      ; set all pins in A register to input
    sta DDRA
busy:
    lda #RW
    sta PORTB
    lda #(RW | E)       ; send read instruction to LCD
    sta PORTB
    lda PORTA
    and #%10000000
    bne busy            ; if busy flag is set, loop back
    lda #RW             ; clear E pin
    sta PORTB
    lda #%11111111      ; set all pins in A register to output
    sta DDRA
    pla
    rts


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

print_chr:
    jsr lcd_wait
    sta PORTA
    lda #RS        ; set RS pin
    sta PORTB
    lda #(RS | E)  ; set E pin
    sta PORTB
    lda #RS        ; clear E pin
    sta PORTB
    rts

print_str:
    ldx #0
print_loop:
    lda message, x
    beq end_of_string
    jsr print_chr
    inx
    jmp print_loop
end_of_string:
    rts


    .org $fffc
    .word reset
    .word $0000