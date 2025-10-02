;-------------------------------------------------------------------------
;
;  The WOZ Monitor for the Apple 1
;  Written by Steve Wozniak 1976
;  Adapted for the OW6502 by Ophir Wesley 2025
;   
;  TODO: use my input_buf instead of the IN array
;-------------------------------------------------------------------------
.setcpu "65c02"
.include "../defines.s"

.segment "WOZMON"
code_start:
WOZMON:     LDY #$7F

;-------------------------------------------------------------------------
; The GETLINE process
;-------------------------------------------------------------------------

NOTCR:           
    CMP     #BS             ;Backspace key?
    BEQ     BACKSPACE       ;Yes
    CMP     #ESC            ;ESC?
    BEQ     ESCAPE          ;Yes
    INY                     ;Advance text index
    BPL     NEXTCHAR        ;Auto ESC if line longer than 127

ESCAPE:
    LDA     #PROMPT         ;Print prompt character
    JSR     ECHO            ;Output it.

GETLINE:         
    LDA     #CR             ;Send CR
    JSR     ECHO

    LDY     #0+1            ;Start a new input line
BACKSPACE:       
    DEY                     ;Backup text index
    BMI     GETLINE         ;Oops, line's empty, reinitialize

NEXTCHAR:        
    SEI                     ;Disable interrupts to avoid a key being pressed while checking
    LDA     write_ptr       ;Wait for key press
    CMP     read_ptr
    CLI                     ;re-enable interrupts
    BEQ     NEXTCHAR        ;No key yet! read_ptr==write_ptr
    JSR     READ_BUFFER     ;load the new char
    STA     IN,Y            ;save char in the IN array
    JSR     CHR_OUT         ;Display character
    CMP     #CR
    BNE     NOTCR           ;It's not CR!

; Line received, now let's parse it

    LDY     #$ff             ;Reset text index
    LDA     #0              ;Default mode is XAM
    TAX                     ;X=0

SETSTOR:     
    ASL                     ;Leaves $7B if setting STOR mode

SETMODE:
    STA     MODE            ;Set mode flags

BLSKIP:
    INY                     ;Advance text index

NEXTITEM:
    LDA     IN,Y            ;Get character
    CMP     #CR
    BEQ     GETLINE         ;We're done if it's CR!
    CMP     #'.'
    BCC     BLSKIP          ;Ignore everything below "."!
    BEQ     SETMODE         ;Set BLOCK XAM mode ("." = $AE)
    CMP     #':'
    BEQ     SETSTOR         ;Set STOR mode! $BA will become $7B
    CMP     #':'
    BEQ     RUN             ;Run the program! Forget the rest
    STX     L               ;Clear input value (X=0)
    STX     H
    STY     YSAV            ;Save Y for comparison

; Here we're trying to parse a new hex value

NEXTHEX:
    LDA     IN,Y            ;Get character for hex test
    EOR     #$B0            ;Map digits to 0-9
    CMP     #9+1            ;Is it a decimal digit?
    BCC     DIG             ;Yes!
    ADC     #$88            ;Map letter "A"-"F" to $FA-FF
    CMP     #$FA            ;Hex letter?
    BCC     NOTHEX          ;No! Character not hex

DIG:
    ASL
    ASL                     ;Hex digit to MSD of A
    ASL
    ASL
    LDX     #4              ;Shift count
HEXSHIFT:
    ASL                     ;Hex digit left, MSB to carry
    ROL     L               ;Rotate into LSD
    ROL     H               ;Rotate into MSD's
    DEX                     ;Done 4 shifts?
    BNE     HEXSHIFT        ;No, loop
    INY                     ;Advance text index
    BNE     NEXTHEX         ;Always taken

NOTHEX:
    CPY     YSAV            ;Was at least 1 hex digit given?
    BEQ     ESCAPE          ;No! Ignore all, start from scratch

    BIT     MODE            ;Test MODE byte
    BVC     NOTSTOR         ;B6=0 is STOR, 1 is XAM or BLOCK XAM
; STOR mode, save LSD of new hex byte

    LDA     L               ;LSD's of hex data
    STA     (STL,X)         ;Store current 'store index'(X=0)
    INC     STL             ;Increment store index.
    BNE     NEXTITEM        ;No carry!
    INC     STH             ;Add carry to 'store index' high
TONEXTITEM:
    JMP     NEXTITEM        ;Get next command item.

;-------------------------------------------------------------------------
;  RUN user's program from last opened location
;-------------------------------------------------------------------------

RUN:
    JMP     (XAML)          ;Run user's program

;-------------------------------------------------------------------------
;  We're not in Store mode
;-------------------------------------------------------------------------

NOTSTOR:
    BMI     XAMNEXT         ;B7 = 0 for XAM, 1 for BLOCK XAM

; We're in XAM mode now

    LDX     #2              ;Copy 2 bytes
SETADR:
    LDA     L-1,X           ;Copy hex data to
    STA     STL-1,X         ;'store index'
    STA     XAML-1,X        ;and to 'XAM index'
    DEX                     ;Next of 2 bytes
    BNE     SETADR          ;Loop unless X = 0

; Print address and data from this address, fall through next BNE.

NXTPRNT:
    BNE     PRDATA          ;NE means no address to print
    LDA     #CR             ;Print CR first
    JSR     ECHO
    LDA     XAMH            ;Output high-order byte of address
    JSR     PRBYTE
    LDA     XAML            ;Output low-order byte of address
    JSR     PRBYTE
    LDA     #':'            ;Print colon
    JSR     ECHO

PRDATA:
    LDA     #' '            ;Print space
    JSR     ECHO
    LDA     (XAML,X)        ;Get data from address (X=0)
    JSR     PRBYTE          ;Output it in hex format
XAMNEXT:
    STX     MODE            ;0 -> MODE (XAM mode).
    LDA     XAML            ;See if there's more to print
    CMP     L
    LDA     XAMH
    SBC     H
    BCS     TONEXTITEM      ;Not less! No more data to output

    INC     XAML            ;Increment 'examine index'
    BNE     MOD8CHK         ;No carry!
    INC     XAMH

MOD8CHK:
    LDA     XAML            ;If address MOD 8 = 0 start new line
    AND     #%00000111
    BPL     NXTPRNT         ;Always taken.

;-------------------------------------------------------------------------
;  Subroutine to print a byte in A in hex form (destructive)
;-------------------------------------------------------------------------

PRBYTE:
    PHA                     ;Save A for LSD
    LSR
    LSR
    LSR                     ;MSD to LSD position
    LSR
    JSR     PRHEX           ;Output hex digit
    PLA                     ;Restore A

; Fall through to print hex routine

;-------------------------------------------------------------------------
;  Subroutine to print a hexadecimal digit
;-------------------------------------------------------------------------

PRHEX:
    AND     #%00001111      ;Mask LSD for hex print
    ORA     #'0'            ;Add "0"
    CMP     #'9'+1          ;Is it a decimal digit?
    BCC     ECHO            ;Yes! output it
    ADC     #6              ;Add offset for letter A-F

; Fall through to print routine

;-------------------------------------------------------------------------
;  Subroutine to print a character to the terminal
;-------------------------------------------------------------------------

ECHO:
    JMP CHR_OUT


.segment "DRIVERS"
.include "../drivers/input_buf.s"
.include "../drivers/lcd.s"
.include "../drivers/ps2.s"

.include "../sys_routines.s"