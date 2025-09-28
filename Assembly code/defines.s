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
write_ptr = $00
read_ptr = $01
ps2_read_result = $02
kboard_flags = $03  ; 7: break code recieved, 6: shift held

; wozmon variables
XAML            .EQ     $24             ;Last "opened" location Low
XAMH            .EQ     $25             ;Last "opened" location High
STL             .EQ     $26             ;Store address Low
STH             .EQ     $27             ;Store address High
L               .EQ     $28             ;Hex value parsing Low
H               .EQ     $29             ;Hex value parsing High
YSAV            .EQ     $2A             ;Used to see if hex value is given
MODE            .EQ     $2B             ;$00=XAM, $7F=STOR, $AE=BLOCK XAM

input_buffer = $0200