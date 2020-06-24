MAP_WIDTH equ 38
MAP_HEIGHT equ 22
MAP_SIZE equ 836; 38*22

assume cs:code, ds:data, ss:stack

data segment
map db MAP_SIZE dup(0)
direction db 0; up down left right 1234
head dw 0; position
tail dw 0
food dw 0
score dw 0
delay_time dw 32768
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
    call initiate_map
    call initiate_game
    call draw_content
    game_loop:
        call delay
        mov ax, head
        mov bl, direction
        call position_plus_direction
        call check_position
        jnc game_end
        call get_map
        cmp bl, 0h
        jne game_end
        call move_snake
        call draw_content
    jmp game_loop
    
    game_end:
    ; call reset_screen
    mov ah, 4ch
    int 21h
main endp

delay proc near
    push cx
    mov cx, delay_time
    delay_loop:
        call get_input
    loop delay_loop
    pop cx
    ret
delay endp

move_snake proc near
    push ax
    
    mov ax, head
    mov bl, direction
    call set_map
    call position_plus_direction
    mov head, ax

    mov ax, tail
    call get_map
    push bx
    mov bl, 0
    call set_map
    pop bx
    mov ax, tail
    call position_plus_direction
    mov tail, ax

    pop ax
    ret
move_snake endp

set_map proc near
    ; setting the map value of position ax to bl
    push ax
    push si

    mov si, bx
    mov bx, ax
    mov ax, MAP_WIDTH
    mul bh
    mov bh, 0
    add ax, bx
    mov bx, si
    mov si, ax

    mov map[si], bl

    pop si
    pop ax
    ret
set_map endp

get_map proc near
    ; getting the map value of position ax, saving it to bl
    push ax
    push si

    mov bx, ax
    mov ax, MAP_WIDTH
    mul bh
    mov bh, 0
    add ax, bx
    mov si, ax

    mov bl, map[si]

    pop si
    pop ax
    ret
get_map endp

check_position proc near
    ; checking whether the position is still in map, affect cf
    cmp ah, MAP_HEIGHT
    jns check_position_false
    cmp al, MAP_WIDTH
    jns check_position_false
    stc
    jmp check_position_end
    check_position_false:
    clc
    check_position_end:
    ret
check_position endp

position_plus_direction proc near
    ; calculating the position in ax and bl
    cmp bl, 1
    je position_plus_direction_1
    cmp bl, 2
    je position_plus_direction_2
    cmp bl, 3
    je position_plus_direction_3
    cmp bl, 4
    je position_plus_direction_4
    jmp position_plus_direction_end

    position_plus_direction_1:
    sub ax, 0100h
    jmp position_plus_direction_end
    position_plus_direction_2:
    add ax, 0100h
    jmp position_plus_direction_end
    position_plus_direction_3:
    sub ax, 0001h
    jmp position_plus_direction_end
    position_plus_direction_4:
    add ax, 0001h
    position_plus_direction_end:
    ret
position_plus_direction endp

get_input proc near
    push ax
    mov al, 0
    mov ah, 1
    int 16h; check data
    cmp ah, 1
    je get_input_end

    mov al, 0
    mov ah, 0
    int 16h
    ; 4800h up
    ; 5000h down
    ; 4b00h left
    ; 4d00h right
    get_input_up:
        cmp ax, 4800h
        jne get_input_down
        cmp direction, 2
        je get_input_end
        mov direction, 1
    get_input_down:
        cmp ax, 5000h
        jne get_input_left
        cmp direction, 1
        je get_input_end
        mov direction, 2
    get_input_left:
        cmp ax, 4b00h
        jne get_input_right
        cmp direction, 4
        je get_input_end
        mov direction, 3
    get_input_right:
        cmp ax, 4d00h
        jne get_input_end
        cmp direction, 3
        je get_input_end
        mov direction, 4
    get_input_end:
    pop ax
    ret
get_input endp

draw_block proc near
    ; drawing dx to row bh column bl block
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

draw_border proc near
    mov dl, 23h; #
    mov dh, 07h; 00000111

    mov bx, 0000h
    mov cx, MAP_WIDTH+2
    draw_border_row:
        call draw_block
        add bh, MAP_HEIGHT+1
        call draw_block
        sub bh, MAP_HEIGHT+1
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

draw_score proc near
    ; drawing the game score at row 25
    push ax
    push bx
    push cx
    push dx
    push si

    mov dh, 07h; 00000111

    ; setting the color of whole row 25
    mov cx, MAP_WIDTH+4
    mov si, 3841; row 25, column 1, (80*24+0)*2+1
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
    mov si, 3864 ; the least significan bit, row 25, column 13, (80*24+12)*2
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

draw_content proc near
    push ax
    push bx
    push dx
    push cx
    push si

    mov si, MAP_SIZE-1
    mov cx, MAP_HEIGHT
    draw_content_row:
        push cx
        mov cx, MAP_WIDTH
        draw_content_column:
            cmp map[si], 0
            je draw_content_empty
            mov dx, 7720h; normal, bg:white, fg:white, ' '
            jmp draw_content_draw
            draw_content_empty:
            mov dx, 0020h; normal, bg:white, fg:white, ' '
            draw_content_draw:
            mov bl, cl
            pop ax
            push ax
            mov bh, al
            call draw_block
            dec si
        loop draw_content_column
        pop cx
    loop draw_content_row

    mov dx, 1120h; normal, bg:blue, fg:blue, ' '
    mov bx, food
    add bx, 0101h
    call draw_block
    mov dx, 4420h; normal, bg:red, fg:red, ' '
    mov bx, head
    add bx, 0101h
    call draw_block

    pop si
    pop dx
    pop cx
    pop bx
    pop ax
    ret
draw_content endp

initiate_game proc near
    mov food, 0404h; row 4, column 4
    mov map[156], 5; 4*38+4
    mov direction, 4
    mov head, 0907h; row 9, column 7
    mov tail, 0904h; row 9, column 4
    mov map[346], 4; 9*38+4
    mov map[347], 4; 9*38+5
    mov map[348], 4; 9*38+6
    ret
initiate_game endp

initiate_map proc near
    push ax
    push bx
    push dx
    push cx
    push si

    mov si, MAP_SIZE-1
    mov cx, MAP_HEIGHT
    initiate_map_row:
        push cx
        mov cx, MAP_WIDTH
        initiate_map_column:
            cmp map[si], 23h; #
            jnz initiate_map_common
            mov dx, 0723h; normal, bg:black, fg:white, '#'
            jmp initiate_map_display
            initiate_map_common:
            mov dx, 0020h; normal, bg:black, fg:black, ' '
            initiate_map_display:
            mov bl, cl
            pop ax
            push ax
            mov bh, al
            call draw_block
            dec si
        loop initiate_map_column
        pop cx
    loop initiate_map_row

    pop si
    pop dx
    pop cx
    pop bx
    pop ax
    ret
initiate_map endp

blink_score proc near
    ; blinking the score by modifying the values in memory
    push cx
    push si

    mov cx, 5; 5 bits
    mov si, 3857; the number part of score start from row 25, column 9
    blink_score_set_blink:
        mov byte ptr es:[si], 87h; blink, bg:black, fg:white
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
    mov si, 3857
    unblink_score_set_blink:
        mov byte ptr es:[si], 07h; normal, bg:black, fg:white
        add si, 2
    loop unblink_score_set_blink
    pop si
    pop cx
    ret
unblink_score endp

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

code ends
end main