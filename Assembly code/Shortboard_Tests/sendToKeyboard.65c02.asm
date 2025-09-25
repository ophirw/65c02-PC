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

    .org $8000
    nop
    .org $C000

reset:
    lda #%00011111
    sta PCR      ; set CA2 output, CA1 input (need to be tied high), CB1 positive going edge. CB2 controlled by SR.
    lda #%11111111
    sta DDRA     ; set all pins in A register to output
    lda #%10111111
    sta DDRB     ; set all pins (except PB6, connected to PS2 clk) in B register to output

    lda #$ff
    jsr ps2_write

loop:
    jmp loop

ps2_write:
	; Clock low
	stz PORTB
    ldx #$ff
    stx DDRB
    ; Data low
	ldx #%11011111
    stx PCR
	; Wait a while
	jsr delay
	; Let the clock float again
	ldx #%10111111
    stx DDRB

	; Track odd parity
	ldy #1

	; Loop once per bit
	ldx #8
ps2_write_bitloop:
	; Send next bit
	rol
	jsr ps2_write_bit
	dex
	bne ps2_write_bitloop

	; Send the parity bit
	tya
    ror
	jsr ps2_write_bit

	; Send the stop bit
	sec
	jsr ps2_write_bit

	; Wait one more time
	jsr ps2_write_bit

	rts
	
ps2_write_bit:
	pha
	; The bit to write is in the carry
	; Default to pull CB2 low
	lda #%11011111

	; If next bit is clear, that's the right state for CB2
	bcc ps2_write_bit_clear

	; Otherwise track parity and let CB2 float instead
	iny
	lda #%00011111

ps2_write_bit_clear:
	; Wait for one tick from the device
	jsr waitpb6high
    jsr waitpb6low

	; Set the CB2 state
	sta PCR

	pla
	rts

waitpb6low:
	bit PORTB
    bvs waitpb6low
	rts

waitpb6high:
	bit PORTB
    bvc waitpb6high
	rts

delay:
	phx
	ldx #0
delayloop:
	nop
    dex
    bne delayloop
	plx
	rts

NMI:
    rti
IRQ:
    rti

; sys vectors
;-------------
    .org $fffa
    .word NMI
    .word reset
    .word IRQ
