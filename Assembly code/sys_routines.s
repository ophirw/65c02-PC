;TODO: check for parity in PS2 IRQ handler

reset:
    lda #%00011111
    sta PCR      ; set CA2 output, CA1 input (need to be tied high), CB1 positive going edge. CB2 controlled by SR.
    lda #%11111111
    sta DDRA     ; set all pins in A register to output
    lda #%10111111
    sta DDRB     ; set all pins (except PB6, connected to PS2 clk) in B register to output

    jsr lcd_init
    jsr ps2_init
    jmp terminal_loop

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

_ps2_framing_error:
    ; Interrupt the device to resynchronise
    lda PORTB
    and #%10111111      ; pb6 low
    sta PORTB
    lda DDRB
    tax
    ora #%01000000      ; pb6 output
    sta DDRB            ; clock low
	jsr delay           ; at least 100us
    stx DDRB            ; release clock

	; Prepare for the next character
	jsr ps2_prepare_for_character

	lda #$ff
    jsr ps2_add_to_buffer
    jmp _irq_done

_irq_ps2_sr:
    lda SR ; clear SR interrupt flag and read first 8 bits.
    ; A register now has first 8 bits (start bit 0 (in position 7, MSB), and 7 least significant data bits (in reverse order))
    ;check for framing error - MSB needs to be 0 (start bit)
    bmi _ps2_framing_error
    sta ps2_read_result
    jmp _irq_done

_irq_ps2_t2:
    bit T2CL; clear t2 interrupt flag
    lda SR  ; read next 3 bits.
    ; A register now has last 3 bits (code MSB in position 2, parity bit in position 1, stop bit 1 in position 0)
    ror     ; rotate right 3 times to put MSB in carry bit, parity in bit 7, stop bit in bit 6
    ;heck for framing error - carry bit needs to be 1 (stop bit)
    bcc _ps2_framing_error
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


.segment "SYSVEC"

; sys vectors
;-------------
    .word NMI
    .word reset
    .word IRQ