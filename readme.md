# snake in masm
![](https://github.com/lsn42/snake/blob/master/image/snake.gif)
|process|description|
|----|----|
|extend_snake|extend the head of snake|
|move_snake|extend the head of snake and reduce the tail|
|generate_food|putting a new food on the map|
|coordinate_plus_direction|calculating the new coordinate according to olds in ax and direction in bl|
|check_coordinate|checking whether the coordinate is still in map, affect cf|
|draw_block|drawing value in dx to the block of row bh column bl|
|draw_string|drawing the string which pointed by the effective address in di, to row bh, column bl, with color dh|
|draw_GUI|drawing the outer GUI of the game|
|draw_content|drawing the whole map, including the snake head, body, and food, wall|
|draw_score|drawing the numeric score at row bh, column bl|
|get_input|getting the user input from keyboard buffer and modifying direction|
|get_map|getting the map value of position ax, saving it to bl|
|set_map|setting the map value of position ax to bl|
|reset_screen|setting the display method to "80*25, 16 color" to reset the screen, and hiding the cursor|
|get_rand|getting random number not bigger than al, and saving it to ah|