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
    cmp #$08 ; is it backspace?
    beq _backspace
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
    lda #$20 ; " "
    ldx #4
_tab_loop:
    jsr CHR_OUT
    dex
    bne _tab_loop
    plx
    pla
    rts
_backspace:
    pha
    lda #%00010000 ; cursor shift left
    jsr lcd_instruction
    lda #$20 ; " " print blank
    jsr CHR_OUT
    lda #%00010000 ; cursor shift left
    jsr lcd_instruction
    pla
    rts