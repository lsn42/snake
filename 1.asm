data segment
food dw 0
body dw 400 dup(?)
data ends

get_input proc near
    mov al, 0
    mov ah, 1
    int 16h ; check data
    cmp ah, 1
    je get_input_end

    mov al, 0
    mov ah, 0
    int 16h
get_input_end:
    ret