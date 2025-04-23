PORTB = $6000
PORTA = $6001
DDRB = $6002
DDRA = $6003

E = %10000000
RW = %01000000
RS = %00100000

    .org $8000

    
reset:
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

    jsr print_str

loop:
    jmp loop

message: .asciiz "Hello, World!"

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