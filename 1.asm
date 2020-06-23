assume cs:code, ds:data, ss:stack
data segment
MAP_WIDTH equ 36
MAP_HEIGHT equ 22
MAP_SIZE equ 792; 36*22
map db MAP_SIZE dup(0)
head dw 0; position
tail dw 0
food dw 0
score dw 65535
data ends

stack segment stack
dw 100 dup(?)
stack ends

code segment
main proc far
    mov ax, data
    mov ds, ax

    mov ax, 0b800h
    mov es, ax; gpu map

    call reset_screen
    call draw_border
    call draw_score
    call blink_score
    
    mov ah, 4ch
    int 21h
main endp

reset_screen proc near
    ; setting display method to "80*25, 16 color" to reset the screen
    push ax
    mov ax, 3; ah = 00h, al = 03h
    int 10h
    pop ax
    ret
reset_screen endp

get_rand_38 proc near
    ; getting random number from 0~37, and saving it to ah
    ; don't know how it works
    push bx
    mov ax, 0h
    out 43h, al
    in al, 40h
    in al, 40h
    in al, 40h

    mov bl, 38
    div bl
    pop bx
    ret
get_rand_38 endp

get_rand_22 proc near
    ; getting random number from 0~21, and saving it to ah
    ; don't know how it works
    push bx
    mov ax, 0h
    out 43h, al
    in al, 40h
    in al, 40h
    in al, 40h

    mov bl, 22
    div bl
    pop bx
    ret
get_rand_22 endp

draw_border proc near
    mov dl, 23h; #
    mov dh, 07h; 00000111

    mov bx, 0000h
    mov cx, 40
    draw_border_row:
        call draw_block
        add bh, 23
        call draw_block
        sub bh, 23
        inc bl
    loop draw_border_row

    mov bx, 0100h
    mov cx, 22
    draw_border_column:
        call draw_block
        add bl, 39
        call draw_block
        sub bl, 39
        inc bh
    loop draw_border_column

    ret
draw_border endp

draw_block proc near
    ; drawing dx to bh:bl block
    push ax
    push bx
    push si

    mov ax, 80
    mul bh
    mov bh, 0
    sal bl, 1
    add ax, bx

    mov si, ax
    sal si, 1

    mov es:[si], dl
    mov es:[si+1], dh
    mov es:[si+2], dl
    mov es:[si+3], dh

    pop si
    pop bx
    pop ax
    ret
draw_block endp

draw_score proc near
    ; drawing the game score at row 25
    push ax
    push bx
    push cx
    push dx
    push si

    mov dh, 07h; 00000111

    ; setting the color of whole row 25
    mov cx, 40
    mov si, 3841; row 25, column 1, 3841 = (80*24+0)*2+1
    draw_score_set_color:
        mov es:[si], dh
        add si, 2
    loop draw_score_set_color

    ; setting the characters part of score
    ; there is a gap before the string below
    mov byte ptr es:[3842], 's'
    mov byte ptr es:[3844], 'c'
    mov byte ptr es:[3846], 'o'
    mov byte ptr es:[3848], 'r'
    mov byte ptr es:[3850], 'e'
    mov byte ptr es:[3852], ':'
    ; there is a gap follow the string above

    ; setting the decimal number part of score
    mov ax, score
    mov bx, 10
    mov cx, 5
    mov si, 3864
    draw_score_number:
        mov dx, 0
        div bx
        add dl, 30h
        mov byte ptr es:[si], dl
        sub si, 2
    loop draw_score_number

    pop si
    pop dx
    pop cx
    pop bx
    pop ax
    ret
draw_score endp

init_map proc near
    mov cx, MAP_SIZE

blink_score proc near
    ; blinking the score by modifying the values in memory
    push cx
    push si

    mov cx, 5
    mov si, 3857; the number part of score start from row 25, column 9,
    ; 3857 = (80*24+8)*2+1
    blink_score_set_blink:
        mov byte ptr es:[si], 87h; 10000111(blink, bg:black, fg:white)
        add si, 2
    loop blink_score_set_blink
    
    pop si
    pop cx
    ret
blink_score endp

unblink_score proc near
    push cx
    push si
    mov cx, 5
    mov si, 3855
    unblink_score_set_blink:
        mov byte ptr es:[si], 07h; 00000111
        add si, 2
    loop unblink_score_set_blink
    pop si
    pop cx
    ret
unblink_score endp

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

code ends
end main