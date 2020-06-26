; NOTE: if you change the MAP_WIDTH or MAP_HEIGHT, you also need to change the
; MAP_SIZE, and modify initialize_game process.
; 38*22 is the max size of the game
MAP_WIDTH equ 38
MAP_HEIGHT equ 22
MAP_SIZE equ 836; 836 = 38*22
WALL_CHARACTER equ "#"
SPACE_CHARACTER equ " "
ACCELERATION equ 256
COLOR_TEXT equ 07h; 00000111(normal, bg:black, fg:white)
COLOR_WALL equ 07h; 00000111(normal, bg:black, fg:white)
COLOR_NONE equ 0; 00000000(normal, bg:black, fg:black)
COLOR_HEAD equ 44h; 01000100(normal, bg:red, fg:red)
COLOR_FOOD equ 33h; 00010001(normal, bg:cyan, fg:cyan)
COLOR_BODY equ 77h; 01110111(normal, bg:white, fg:white)

assume cs:code, ds:data, ss:stack

data segment
map db MAP_SIZE dup(0)
direction db 0; up down left right = 1234
head dw 0; coordinate
tail dw 0; coordinate
score dw 0
delay_time dw 32768; decide how fast the game goes
STRING_SCORE db "score:", 24h
STRING_GAMEOVER db "Game Over!", 24h
data ends

stack segment stack
dw 0ffh dup(?)
stack ends

code segment
main proc far
    ; data segment
    mov ax, data
    mov ds, ax
    ; mapping
    mov ax, 0b800h
    mov es, ax

    ; game logic
    call reset_screen; clean the screen
    call initialize_game; prepare the game map
    call draw_GUI; draw the whole game GUI
    call draw_content; draw the map and the snake
    game_loop:
        call delay; delay a little period
        mov ax, head
        mov bl, direction
        call coordinate_plus_direction; get next coordinate
        call check_coordinate; check whether next coordinate still in map
        jnc game_over; collide into border wall, game over
        call get_map; get the map value
        cmp bl, 5; food
        je game_scored; eat food, extend snake and increase score
        cmp bl, 0; empty
        jne game_over; collide into body or some other thing, game over
        call move_snake; extend the head of snake and reduce the tail
        jmp game_draw

        game_scored:
            inc score
            cmp score, ACCELERATION
            jnc game_fastest
            sub delay_time, ACCELERATION; accelerate
            game_fastest:
            call generate_food; get a new food
            call extend_snake; extend the head of snake but not reduce the tail

        ; drawing changes when every moves done
        game_draw:
        call draw_content
        ; setting bx for drawing score
        mov bh, MAP_HEIGHT+2; drawing it at outer edge
        mov bl, 13; the least significan bit of score in column 13
        call draw_score
    jmp game_loop

    game_over:
    ; drawing the game over text
    mov bx, 0b22h; position
    mov dh, COLOR_TEXT
    lea di, STRING_GAMEOVER
    call draw_string
    ; waiting for any key pressed and then cleaning the screen
    mov ah, 0
    int 16h
    call reset_screen
    ; returning cursor that hide before
    mov ah, 1
    mov cx, 0607h
    int 10h

    mov ah, 4ch
    int 21h
main endp

initialize_game proc near
    mov map[362], 5; first food at row 9, column 20, 362 = 9*38+20
    mov direction, 4; right
    mov head, 0907h; row 9, column 7
    mov tail, 0905h; row 9, column 5
    mov map[347], 4; 347 = 9*38+5
    mov map[348], 4; 348 = 9*38+6
    ret
initialize_game endp

delay proc near
    ; continually getting the keyboard input, consume time
    push cx
    mov cx, delay_time
    delay_loop:
        call get_input; get the keyboard input
    loop delay_loop
    pop cx
    ret
delay endp

extend_snake proc near
    ; extend the head of snake
    push ax
    push bx
    
    mov ax, head
    mov bl, direction
    call set_map; save the direction value into map
    call coordinate_plus_direction; get the next coordinate
    mov head, ax; save the new coordinate to head

    pop bx
    pop ax
    ret
extend_snake endp

move_snake proc near
    ; extend the head of snake and reduce the tail
    push ax
    push bx
    
    call extend_snake

    ; move the tail according to the value saved in map
    mov ax, tail
    call get_map; get the direction value of tail in map
    push bx
    mov bl, 0
    call set_map; set it to empty
    pop bx
    mov ax, tail
    call coordinate_plus_direction; get the next coordinate
    mov tail, ax; save the new coordinate to tail

    pop bx
    pop ax
    ret
move_snake endp

generate_food proc near
    ; putting a new food on the map
    push ax
    push bx

    generate_food_start:
        ; getting a random coordinate inside map, saving it to bx
        mov al, MAP_WIDTH
        call get_rand
        mov bh, ah
        mov al, MAP_HEIGHT
        call get_rand
        mov al, bh

        ; checking whether that coordinate empty
        call get_map
        cmp bl, 0
        jne generate_food_start; it's not empty, getting a new random coordinate
        mov bl, 5
        call set_map; setting the food

    pop bx
    pop ax
    ret
generate_food endp

coordinate_plus_direction proc near
    ; calculating the new coordinate according to olds in ax and direction in bl
    cmp bl, 1
    je coordinate_plus_direction_1; up
    cmp bl, 2
    je coordinate_plus_direction_2; down
    cmp bl, 3
    je coordinate_plus_direction_3; left
    cmp bl, 4
    je coordinate_plus_direction_4; right
    jmp coordinate_plus_direction_end

    coordinate_plus_direction_1:
    sub ax, 0100h
    jmp coordinate_plus_direction_end
    coordinate_plus_direction_2:
    add ax, 0100h
    jmp coordinate_plus_direction_end
    coordinate_plus_direction_3:
    sub ax, 0001h
    jmp coordinate_plus_direction_end
    coordinate_plus_direction_4:
    add ax, 0001h
    coordinate_plus_direction_end:
    ret
coordinate_plus_direction endp

check_coordinate proc near
    ; checking whether the coordinate is still in map, affect cf
    cmp ah, MAP_HEIGHT
    jnc check_coordinate_false
    cmp al, MAP_WIDTH
    jnc check_coordinate_false
    stc
    jmp check_coordinate_end
    check_coordinate_false:
    clc
    check_coordinate_end:
    ret
check_coordinate endp

draw_block proc near
    ; drawing value in dx to the block of row bh column bl
    push ax
    push bx
    push si

    ; getting the gpu memory offset and saving it to si
    mov ax, 80
    mul bh
    mov bh, 0
    sal bl, 1
    add ax, bx
    mov si, ax
    sal si, 1

    ; drawing two same value in memory
    mov es:[si], dl
    mov es:[si+1], dh
    mov es:[si+2], dl
    mov es:[si+3], dh

    pop si
    pop bx
    pop ax
    ret
draw_block endp

draw_string proc near
    ; drawing the string which pointed by the effective address in di, to
    ; row bh, column bl, with color dh
    push ax
    push bx
    push di
    push si
    
    ; getting the gpu memory offset and saving it to si
    mov ax, 80
    mul bh
    mov bh, 0
    add ax, bx
    mov si, ax
    sal si, 1

    ; start drawing the string
    draw_string_loop:
        mov dl, ds:[di]; load the first character
        cmp dl, 24h
        je draw_string_end; string ends with '$'
        mov es:[si], dl; set the character
        mov es:[si+1], dh; set the color
        inc di; next character
        add si, 2; next position
    jmp draw_string_loop

    draw_string_end:
    pop si
    pop di
    pop bx
    pop ax
    ret
draw_string endp

draw_GUI proc near
    ; drawing the outer GUI of the game
    push ax
    push bx
    push cx
    push dx
    push si

    ; drawing border
    mov dh, COLOR_WALL
    mov dl, WALL_CHARACTER
    ; drawing horizontal border
    mov bx, 0000h; start frome row 0, column 0
    mov cx, MAP_WIDTH+2
    draw_GUI_border_horizontal:
        call draw_block; draw the up edge block
        add bh, MAP_HEIGHT+1; jump to the down edge
        call draw_block; draw the down edge block
        sub bh, MAP_HEIGHT+1; recover bh
        inc bl; next block
    loop draw_GUI_border_horizontal
    ; drawing vertical border
    mov bx, 0100h; start frome row 1, column 0
    mov cx, MAP_HEIGHT
    draw_GUI_column:
        call draw_block; draw the left edge block
        add bl, MAP_WIDTH+1; jump to the right edge
        call draw_block; draw the right edge block
        sub bl, MAP_WIDTH+1; recover bl
        inc bh; next block
    loop draw_GUI_column

    ; drawing the string part of score
    lea di, STRING_SCORE
    mov bh, MAP_HEIGHT+2; drawing it at outer edge
    mov bl, 1; 1 character gap
    mov dh, COLOR_WALL
    call draw_string
    ; drawing the numeric part of score
    mov bh, MAP_HEIGHT+2; drawing it at outer edge
    mov bl, 13; the least significan bit of score in column 13
    call draw_score

    pop si
    pop dx
    pop cx
    pop bx
    pop ax
    ret
draw_GUI endp

draw_content proc near
    ; drawing the whole map, including the snake head, body, and food, wall
    push ax
    push bx
    push dx
    push cx
    push si

    ; drawing body, food, wall
    mov si, MAP_SIZE-1; start from the end of map
    mov cx, MAP_HEIGHT; row
    draw_content_row:
        push cx
        mov cx, MAP_WIDTH; column
        draw_content_column:
            cmp map[si], 0; empty
            je draw_content_empty
            cmp map[si], 5; food
            je draw_content_food
            cmp map[si], WALL_CHARACTER; wall
            je draw_content_wall
            mov dl, SPACE_CHARACTER
            mov dh, COLOR_BODY
            jmp draw_content_draw; draw body(1, 2, 3, 4)
            draw_content_wall:
                mov dl, WALL_CHARACTER
                mov dh, COLOR_WALL
                jmp draw_content_draw
            draw_content_food:
                mov dl, SPACE_CHARACTER
                mov dh, COLOR_FOOD
                jmp draw_content_draw
            draw_content_empty:
                mov dl, SPACE_CHARACTER
                mov dh, COLOR_NONE
            draw_content_draw:
            ; move the row and column loop value to bx
            mov bl, cl
            pop ax
            push ax
            mov bh, al
            call draw_block
            dec si
        loop draw_content_column
        pop cx
    loop draw_content_row

    ; drawing head
    mov dl, SPACE_CHARACTER
    mov dh, COLOR_HEAD
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

draw_score proc near
    ; drawing the numeric score at row bh, column bl
    push ax
    push bx
    push cx
    push dx
    push si

    ; getting the gpu memory offset and saving it to si
    mov ax, 80
    mul bh
    mov bh, 0
    add ax, bx
    mov si, ax
    sal si, 1

    ; setting the number part of score
    mov ax, score
    mov bx, 10; decimal
    mov cx, 5
    draw_score_number:
        mov dx, 0; prepare for 32 bit division
        div bx
        add dl, 30h; get the number ascii code
        mov es:[si], dl
        mov byte ptr es:[si+1], COLOR_TEXT
        sub si, 2; next position
    loop draw_score_number

    pop si
    pop dx
    pop cx
    pop bx
    pop ax
    ret
draw_score endp

get_input proc near
    ; getting the user input from keyboard buffer and modifying direction
    push ax
    mov ax, 0100h
    int 16h; check data
    cmp ah, 1
    je get_input_end; no input

    mov ax, 0000h
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

get_map proc near
    ; getting the map value of position ax, saving it to bl
    push ax
    push si

    ; getting the offset and saving it to si
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

set_map proc near
    ; setting the map value of position ax to bl
    push ax
    push si

    ; getting the offset and saving it to si
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

reset_screen proc near
    ; setting the display method to "80*25, 16 color" to reset the screen, and
    ; hiding the cursor
    push ax
    push cx

    ; setting display mode
    mov ax, 0003h; ah = 00h, al = 03h
    int 10h
    ; hiding cursor
    mov cx, 2000h
    mov ah, 01h
    int 10h

    pop cx
    pop ax
    ret
reset_screen endp

get_rand proc near
    ; getting random number not bigger than al, and saving it to ah
    ; don't know how it works
    push bx
    push ax

    mov ax, 0h
    out 43h, al
    in al, 40h
    in al, 40h
    in al, 40h

    pop bx
    div bl
    pop bx
    ret
get_rand endp

code ends
end main