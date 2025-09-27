; initializes the input buffer pointers to make the buffer empty
; Modifies: flags
INIT_BUFFER:
    pha
    lda read_ptr
    sta write_ptr
    pla
    rts

; reads next char from input buffer into A register
; Modifies: flags, A, X
READ_BUFFER:
    ldx read_ptr
    lda input_buffer,X
    inc read_ptr
    rts

; writes the character in the A register to the input buffer, if there is space
; Modifies: flags, X
WRITE_BUFFER:
    pha
    lda write_ptr
    tax
    ; check for buffer full condition
    inc
    cmp read_ptr        ; if next write would make buffer full, skip write
    beq _buffer_full
    pla
    sta input_buffer,X
    inc write_ptr
    jmp _end_write
_buffer_full:
    pla
_end_write:
    rts