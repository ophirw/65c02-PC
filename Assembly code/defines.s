; memory location defines
;-------------------------

; VIA
PORTB = $7f90
PORTA = $7f91
DDRB  = $7f92
DDRA  = $7f93
T2CL  = $7f98
T2CH  = $7f99
SR    = $7f9a
ACR   = $7f9b
PCR   = $7f9c
IFR   = $7f9d
IER   = $7f9e

; variables
write_ptr       = $00
read_ptr        = $01
ps2_read_result = $02
kboard_flags    = $03  ; 7: break code recieved, 6: shift held

; wozmon variables
XAML = $24             ;Last "opened" location Low
XAMH = $25             ;Last "opened" location High
STL  = $26             ;Store address Low
STH  = $27             ;Store address High
L    = $28             ;Hex value parsing Low
H    = $29             ;Hex value parsing High
YSAV = $2A             ;Used to see if hex value is given
MODE = $2B             ;$00=XAM, $7F=STOR, $AE=BLOCK XAM
IN   = $0300

input_buffer = $0200


;-------------------------------------------------------------------------
;  Constants
;-------------------------------------------------------------------------

; wozmon constants
BS     = $08             ;Backspace key, arrow left key
CR     = $0A             ;Carriage Return
ESC    = $1B             ;ESC key
PROMPT = '>'             ;Prompt character

; lcd pins
E      = %00000001
RW     = %00000010
RS     = %00000100

; via registers
IFR_SR = %00000100
IFR_T2 = %00100000
IFR_SET= %10000000