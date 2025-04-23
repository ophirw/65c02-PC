PORTB = $6000
PORTA = $6001
DDRB = $6002
DDRA = $6003

E = %10000000
RW = %01000000
RS = %00100000

    .org $8000

    
reset:
    lda #%11111111 ; set all pins in B register to output
    sta DDRB

    lda #%11100000 ; set top 3 pins in A register to output
    sta DDRA


    lda #%00111000 ;set 8-bit mode. 2-line display. 5x8 font
    sta PORTB
    ; send command to LCD
    lda #0
    sta PORTA  ; clear RS/E/RW
    lda #E
    sta PORTA  ; set E pin
    lda #0
    sta PORTA  ; clear E pin

    ldx #$ff
wait_1:
    ldy #$ff
wait_2:
    dey
    bne wait_2
    dex
    bne wait_1

    lda #%00111000 ;set 8-bit mode. 2-line display. 5x8 font
    sta PORTB
    ; send command to LCD
    lda #0
    sta PORTA  ; clear RS/E/RW
    lda #E
    sta PORTA  ; set E pin
    lda #0
    sta PORTA  ; clear E pin

    ldx #$ff
wait_1:
    ldy #$ff
wait_2:
    dey
    bne wait_2
    dex
    bne wait_1

    lda #%00111000 ;set 8-bit mode. 2-line display. 5x8 font
    sta PORTB
    ; send command to LCD
    lda #0
    sta PORTA  ; clear RS/E/RW
    lda #E
    sta PORTA  ; set E pin
    lda #0
    sta PORTA  ; clear E pin

    lda #%00001110 ; Turn on display. Turn on cursor. Blink off.
    sta PORTB
    ; send command to LCD
    lda #0
    sta PORTA  ; clear RS/E/RW
    lda #E
    sta PORTA  ; set E pin
    lda #0
    sta PORTA  ; clear E pin

    lda #%00000110 ; Write left-to-right. shift cursor. no display shift.
    sta PORTB
    ; send command to LCD
    lda #0
    sta PORTA  ; clear RS/E/RW
    lda #E
    sta PORTA  ; set E pin
    lda #0
    sta PORTA  ; clear E pin


    lda #1 ; clear display
    sta PORTB
    ; send command to LCD
    lda #0
    sta PORTA  ; clear RS/E/RW
    lda #E
    sta PORTA  ; set E pin
    lda #0
    sta PORTA  ; clear E pin

; send "hello world" to LCD

    lda #"H"
    sta PORTB
    ; send character to LCD
    lda #RS
    sta PORTA  ; set RS pin
    lda #(RS | E) 
    sta PORTA  ; set E pin
    lda #RS
    sta PORTA  ; clear E pin

    lda #"e"
    sta PORTB
    ; send character to LCD
    lda #RS
    sta PORTA  ; set RS pin
    lda #(RS | E) 
    sta PORTA  ; set E pin
    lda #RS
    sta PORTA  ; clear E pin

    lda #"l"
    sta PORTB
    ; send character to LCD
    lda #RS
    sta PORTA  ; set RS pin
    lda #(RS | E) 
    sta PORTA  ; set E pin
    lda #RS
    sta PORTA  ; clear E pin

    lda #"l"
    sta PORTB
    ; send character to LCD
    lda #RS
    sta PORTA  ; set RS pin
    lda #(RS | E) 
    sta PORTA  ; set E pin
    lda #RS
    sta PORTA  ; clear E pin

    lda #"o"
    sta PORTB
    ; send character to LCD
    lda #RS
    sta PORTA  ; set RS pin
    lda #(RS | E) 
    sta PORTA  ; set E pin
    lda #RS
    sta PORTA  ; clear E pin

    lda #","
    sta PORTB
    ; send character to LCD
    lda #RS
    sta PORTA  ; set RS pin
    lda #(RS | E) 
    sta PORTA  ; set E pin
    lda #RS
    sta PORTA  ; clear E pin

    lda #" "
    sta PORTB
    ; send character to LCD
    lda #RS
    sta PORTA  ; set RS pin
    lda #(RS | E) 
    sta PORTA  ; set E pin
    lda #RS
    sta PORTA  ; clear E pin

    lda #"W"
    sta PORTB
    ; send character to LCD
    lda #RS
    sta PORTA  ; set RS pin
    lda #(RS | E) 
    sta PORTA  ; set E pin
    lda #RS
    sta PORTA  ; clear E pin

    lda #"o"
    sta PORTB
    ; send character to LCD
    lda #RS
    sta PORTA  ; set RS pin
    lda #(RS | E) 
    sta PORTA  ; set E pin
    lda #RS
    sta PORTA  ; clear E pin

    lda #"r"
    sta PORTB
    ; send character to LCD
    lda #RS
    sta PORTA  ; set RS pin
    lda #(RS | E) 
    sta PORTA  ; set E pin
    lda #RS
    sta PORTA  ; clear E pin

    lda #"l"
    sta PORTB
    ; send character to LCD
    lda #RS
    sta PORTA  ; set RS pin
    lda #(RS | E) 
    sta PORTA  ; set E pin
    lda #RS
    sta PORTA  ; clear E pin

    lda #"d"
    sta PORTB
    ; send character to LCD
    lda #RS
    sta PORTA  ; set RS pin
    lda #(RS | E) 
    sta PORTA  ; set E pin
    lda #RS
    sta PORTA  ; clear E pin

    lda #"!"
    sta PORTB
    ; send character to LCD
    lda #RS
    sta PORTA  ; set RS pin
    lda #(RS | E) 
    sta PORTA  ; set E pin
    lda #RS
    sta PORTA  ; clear E pin

loop:
    jmp loop
    
    .org $fffc
    .word reset
    .word $0000