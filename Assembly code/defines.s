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
write_ptr = $0000
read_ptr = $0001
ps2_read_result = $0002
kboard_flags = $0003  ; 7: break code recieved, 6: shift held
input_buffer = $0200