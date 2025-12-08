[org 0x0100]
jmp start

; ==================== DATA SECTION ====================
; Screen dimensions
SCREEN_WIDTH	equ 80
SCREEN_HEIGHT	equ 25

; Road layout - 3 lanes with wider grass
GRASS_WIDTH	equ 15		; Increased from 10 to 15
ROAD_START	equ 15		; Start further right
ROAD_WIDTH	equ 50		; Narrower road (was 60)
ROAD_END	equ 65		; End earlier (15 + 50)

; Lane positions (3 lanes) - adjusted for new road dimensions
LANE_LEFT	equ 27		; Left lane (was 25)
LANE_CENTER	equ 40		; Center lane (unchanged) 
LANE_RIGHT	equ 53		; Right lane (was 55)

; Lane numbers
LANE_NUM_LEFT	equ 0
LANE_NUM_CENTER	equ 1
LANE_NUM_RIGHT	equ 2

; Lane dividers (2 dividers for 3 lanes)
LANE_DIV1	equ 33		; Between lane 1 and 2 (was 32)
LANE_DIV2	equ 47		; Between lane 2 and 3 (unchanged)

; Colors
COLOR_GRASS	equ 0xAA
COLOR_BORDER	equ 0x22
COLOR_ROAD	equ 0x88
COLOR_LANE	equ 0x8F
COLOR_RED_CAR	equ 0xCC
COLOR_BLUE_CAR	equ 0x99
COLOR_YELLOW	equ 0xEE
COLOR_BLACK	equ 0x00
COLOR_COIN	equ 0xE0
COLOR_FUEL	equ 0x4F

; Animation parameters
OBSTACLE_SPAWN_FREQ	equ 25
COIN_SPAWN_FREQ		equ 60
FUEL_SPAWN_FREQ		equ 180
FUEL_DECREASE_RATE	equ 32
MIN_ITEM_SPACING	equ 8

; Delay timing
DELAY_HIGH	equ 0x0001
DELAY_LOW	equ 0x8000

; Car dimensions
CAR_HEIGHT	equ 4

; Player limits
PLAYER_MIN_ROW	equ 5
PLAYER_MAX_ROW	equ 21

; Car positions
player_row:	dw 20
player_lane:	db 1		; Start in center lane (0=left, 1=center, 2=right)

; Obstacle array
MAX_OBSTACLES	equ 5
obstacle_active:	times MAX_OBSTACLES db 0
obstacle_row:		times MAX_OBSTACLES dw 0
obstacle_col:		times MAX_OBSTACLES dw 0
obstacle_fade_state:	times MAX_OBSTACLES db 0

; Coin array
MAX_COINS	equ 8
coin_active:	times MAX_COINS db 0
coin_row:	times MAX_COINS dw 0
coin_col:	times MAX_COINS dw 0

; Fuel array
MAX_FUEL	equ 3
fuel_active:	times MAX_FUEL db 0
fuel_row:	times MAX_FUEL dw 0
fuel_col:	times MAX_FUEL dw 0

; Player information
player_name:		times 30 db 0	; Player name (max 30 chars)
player_name_len:	db 0		; Length of name entered
player_rollno:		times 15 db 0	; Roll number (max 15 chars)
player_rollno_len:	db 0		; Length of roll no entered

; Game state
frame_count:		dw 0
score:			dw 0
fuel_level:		dw 100
lane_offset:		dw 0
last_spawn_row:		dw 100
game_started:		db 0		; 0 = not started, 1 = running
game_paused:		db 0		; 0 = running, 1 = paused, 2 = quit
show_quit_confirm:	db 0		; 0 = no, 1 = yes
confirm_drawn:		db 0		; 0 = not drawn, 1 = already drawn
intro_shown:		db 0		; 0 = not shown, 1 = shown
name_entered:		db 0		; 0 = not entered, 1 = entered
rollno_entered:		db 0		; 0 = not entered, 1 = entered
instructions_shown:	db 0		; 0 = not shown, 1 = shown
in_game:		db 0		; 0 = pre-game screens, 1 = in actual game

; Keyboard state
key_pressed:		db 0		; Last key pressed
key_released_flag:	db 1		; 1 = key was released, 0 = key held

; Keyboard ISR
oldkb:			dd 0

; Messages
title_msg:		db 'RACING GAME', 0
developer1_msg:		db 'Developed by:', 0
developer2_msg:		db 'Riyyan Ahmed - Roll No: 23K-0001', 0
developer3_msg:		db 'Student Name 2 - Roll No: 23K-0002', 0
press_key_msg:		db 'Press any key to continue...', 0

; Player input screen
input_title:		db 'PLAYER INFORMATION', 0
name_prompt:		db 'Enter your name: ', 0
roll_prompt:		db 'Enter your roll number: ', 0
input_done_msg:		db 'Press ENTER to continue...', 0

; Instructions
instructions_title:	db 'INSTRUCTIONS', 0
inst_line1:		db 'Arrow Keys: Move car left/right/up/down', 0
inst_line2:		db 'Objective: Avoid blue cars and collect items', 0
inst_line3:		db 'Coins ($): Collect to increase score', 0
inst_line4:		db 'Fuel (F): Collect to refill fuel tank', 0
inst_line5:		db 'ESC Key: Pause game and show quit menu', 0
inst_line6:		db 'Fuel decreases over time - collect fuel!', 0
inst_line7:		db 'Game ends when fuel reaches zero', 0
press_start_msg:	db 'Press any key to start the game...', 0

; Game messages
score_msg:		db 'Score: ', 0
fuel_msg:		db 'Fuel: ', 0
gameover_msg:		db 'GAME OVER! Press ESC to exit', 0
quit_confirm_msg:	db 'Do you want to quit? (Y/N)', 0
paused_msg:		db 'PAUSED', 0

; ==================== KEYBOARD ISR ====================
kbisr:
	push ax
	push bx
	push ds
	
	; Set DS to our data segment
	push cs
	pop ds
	
	; Read scan code
	in al, 0x60
	
	; Check if in game
	cmp byte [in_game], 1
	je handle_game_isr
	
	; Pre-game - just advance screens on any key
	; (Input screens use INT 16h directly, not ISR)
	jmp chain_old
	
handle_game_isr:
	; Check if game started
	cmp byte [game_started], 0
	je start_game_check
	
	; Game is running - check for pause/quit confirm
	cmp byte [show_quit_confirm], 1
	je handle_quit_confirm
	
	; Normal game controls
	jmp handle_game_keys
	
start_game_check:
	; Any key starts the game (except releases)
	test al, 0x80
	jz start_the_game
	jmp chain_old
	
start_the_game:
	mov byte [game_started], 1
	jmp chain_old

handle_quit_confirm:
	; In quit confirmation screen
	
	; Y key pressed (scan code 0x15)
	cmp al, 0x15
	je quit_yes
	
	; N key pressed (scan code 0x31)
	cmp al, 0x31
	je quit_no
	
	; ESC pressed (scan code 0x01)
	cmp al, 0x01
	je quit_no		; ESC also resumes
	
	jmp chain_old
	
quit_yes:
	; User wants to quit
	mov byte [show_quit_confirm], 0
	mov byte [game_started], 0
	mov byte [game_paused], 2	; Special flag to quit
	mov byte [confirm_drawn], 0
	jmp chain_old
	
quit_no:
	; User wants to continue
	mov byte [show_quit_confirm], 0
	mov byte [game_paused], 0
	mov byte [confirm_drawn], 0
	jmp chain_old

handle_game_keys:
	; Check for key release (bit 7 set)
	test al, 0x80
	jnz key_release
	
	; Key press
	cmp byte [key_released_flag], 0
	jne new_key_press
	jmp chain_old
	
new_key_press:
	; New key press
	mov byte [key_released_flag], 0
	
	; ESC key (0x01)
	cmp al, 0x01
	jne check_left_key
	jmp handle_esc
	
check_left_key:
	; Left arrow (0x4B)
	cmp al, 0x4B
	jne check_right_key
	jmp handle_left
	
check_right_key:
	; Right arrow (0x4D)
	cmp al, 0x4D
	jne check_up_key
	jmp handle_right
	
check_up_key:
	; Up arrow (0x48)
	cmp al, 0x48
	jne check_down_key
	jmp handle_up
	
check_down_key:
	; Down arrow (0x50)
	cmp al, 0x50
	jne no_key_match
	jmp handle_down
	
no_key_match:
	jmp chain_old

key_release:
	; Key released - check which key
	and al, 0x7F		; Remove release bit
	
	; Check if it was an arrow key or ESC
	cmp al, 0x01
	je mark_released
	cmp al, 0x4B
	je mark_released
	cmp al, 0x4D
	je mark_released
	cmp al, 0x48
	je mark_released
	cmp al, 0x50
	je mark_released
	jmp short skip_to_chain
	
mark_released:
	mov byte [key_released_flag], 1
	
skip_to_chain:
	jmp chain_old

handle_esc:
	; Toggle pause and show quit confirmation
	cmp byte [game_paused], 0
	jne resume_game
	
	; Pause and show confirmation
	mov byte [game_paused], 1
	mov byte [show_quit_confirm], 1
	mov byte [confirm_drawn], 0		; Reset draw flag
	jmp chain_old
	
resume_game:
	; Resume game
	mov byte [game_paused], 0
	mov byte [show_quit_confirm], 0
	mov byte [confirm_drawn], 0		; Reset draw flag
	jmp chain_old

handle_left:
	; Move to left lane
	cmp byte [player_lane], LANE_NUM_LEFT
	jg do_move_left
	jmp chain_old
do_move_left:
	dec byte [player_lane]
	jmp chain_old

handle_right:
	; Move to right lane
	cmp byte [player_lane], LANE_NUM_RIGHT
	jl do_move_right
	jmp chain_old
do_move_right:
	inc byte [player_lane]
	jmp chain_old

handle_up:
	; Move up one row
	mov ax, [player_row]
	cmp ax, PLAYER_MIN_ROW
	jg do_move_up
	jmp chain_old
do_move_up:
	dec word [player_row]
	jmp chain_old

handle_down:
	; Move down one row
	mov ax, [player_row]
	cmp ax, PLAYER_MAX_ROW
	jl do_move_down
	jmp chain_old
do_move_down:
	inc word [player_row]
	jmp chain_old

chain_old:
	; Send EOI
	mov al, 0x20
	out 0x20, al
	
	pop ds
	pop bx
	pop ax
	
	; Chain to old interrupt
	jmp far [cs:oldkb]

; ==================== INTERRUPT MANAGEMENT ====================

; Hook keyboard interrupt
hook_keyboard:
	push ax
	push bx
	push es
	
	xor ax, ax
	mov es, ax
	
	; Save old interrupt vector
	mov ax, [es:9*4]
	mov [oldkb], ax
	mov ax, [es:9*4+2]
	mov [oldkb+2], ax
	
	; Install new handler
	cli
	mov word [es:9*4], kbisr
	mov [es:9*4+2], cs
	sti
	
	pop es
	pop bx
	pop ax
	ret

; Unhook keyboard interrupt
unhook_keyboard:
	push ax
	push es
	
	xor ax, ax
	mov es, ax
	
	; Restore old interrupt
	cli
	mov ax, [oldkb]
	mov [es:9*4], ax
	mov ax, [oldkb+2]
	mov [es:9*4+2], ax
	sti
	
	pop es
	pop ax
	ret

; ==================== INITIALIZATION SUBROUTINES ====================

; Initialize game
init_game:
	call clear_screen
	call flush_keyboard
	call hide_cursor
	call hook_keyboard
	ret

; Cleanup game
cleanup_game:
	call unhook_keyboard
	call show_cursor
	call clear_screen
	ret

; Hide cursor
hide_cursor:
	push ax
	push cx
	
	mov ah, 0x01
	mov ch, 0x20
	mov cl, 0x00
	int 0x10
	
	pop cx
	pop ax
	ret

; Show cursor
show_cursor:
	push ax
	push cx
	
	mov ah, 0x01
	mov ch, 0x06
	mov cl, 0x07
	int 0x10
	
	pop cx
	pop ax
	ret

; Clear screen
clear_screen:
	push ax
	push cx
	push di
	push es
	
	mov ah, 0x00
	mov al, 0x03
	int 10h
	
	mov ax, 0xB800
	mov es, ax
	mov di, 0
	mov cx, SCREEN_WIDTH * SCREEN_HEIGHT
	mov ax, 0x0720
	cld
	rep stosw
	
	mov ah, 0x02
	mov bh, 0
	mov dx, 0
	int 10h
	
	pop es
	pop di
	pop cx
	pop ax
	ret

; Flush keyboard buffer
flush_keyboard:
	push ax
flush_loop:
	mov ah, 0x01
	int 0x16
	jz flush_done
	mov ah, 0x00
	int 0x16
	jmp flush_loop
flush_done:
	pop ax
	ret

; ==================== DRAWING SUBROUTINES ====================

; Draw all background elements
draw_background:
	call draw_grass
	call draw_road
	call draw_lanes
	ret

; Draw grass borders
draw_grass:
	push ax
	push bx
	push cx
	push di
	push es
	
	mov ax, 0xB800
	mov es, ax
	mov di, 0
	mov cx, SCREEN_HEIGHT
	
grass_row_loop:
	push cx
	push di
	
	mov cx, GRASS_WIDTH
	mov ax, COLOR_GRASS
	shl ax, 8
	or ax, 0x20
	cld
	rep stosw
	
	pop di
	push di
	
	add di, ROAD_END * 2
	mov cx, GRASS_WIDTH
	mov ax, COLOR_GRASS
	shl ax, 8
	or ax, 0x20
	rep stosw
	
	pop di
	add di, SCREEN_WIDTH * 2
	pop cx
	loop grass_row_loop
	
	pop es
	pop di
	pop cx
	pop bx
	pop ax
	ret

; Draw road
draw_road:
	push ax
	push bx
	push cx
	push di
	push es
	
	mov ax, 0xB800
	mov es, ax
	mov di, ROAD_START * 2
	mov cx, SCREEN_HEIGHT
	
road_row_loop:
	push cx
	push di
	
	mov cx, ROAD_WIDTH
	mov ax, COLOR_ROAD
	shl ax, 8
	or ax, 0x20
	cld
	rep stosw
	
	pop di
	add di, SCREEN_WIDTH * 2
	pop cx
	loop road_row_loop
	
	pop es
	pop di
	pop cx
	pop bx
	pop ax
	ret

; Draw lane markers
draw_lanes:
	push bx
	
	mov bx, LANE_DIV1
	call draw_single_lane
	
	mov bx, LANE_DIV2
	call draw_single_lane
	
	pop bx
	ret

; Draw single lane divider
draw_single_lane:
	push ax
	push cx
	push di
	push es
	
	mov ax, 0xB800
	mov es, ax
	
	mov cx, 0
	
lane_loop:
	mov ax, cx
	add ax, [lane_offset]
	
	push cx
	mov cx, 4
	mov dx, 0
	div cx
	pop cx
	
	cmp dx, 0
	je draw_marker
	cmp dx, 1
	je draw_marker
	jmp skip_marker
	
draw_marker:
	mov ax, cx
	push dx
	mov dx, SCREEN_WIDTH
	mul dx
	shl ax, 1
	mov di, ax
	mov ax, bx
	shl ax, 1
	add di, ax
	pop dx
	
	mov byte [es:di], 0xDB
	mov byte [es:di+1], COLOR_LANE
	
skip_marker:
	inc cx
	cmp cx, SCREEN_HEIGHT
	jl lane_loop
	
	pop es
	pop di
	pop cx
	pop ax
	ret

; Get column from lane number
get_lane_column:
	push bx
	
	cmp al, LANE_NUM_LEFT
	je use_left
	cmp al, LANE_NUM_CENTER
	je use_center
	jmp use_right
	
use_left:
	mov ax, LANE_LEFT
	jmp lane_col_done
use_center:
	mov ax, LANE_CENTER
	jmp lane_col_done
use_right:
	mov ax, LANE_RIGHT
	
lane_col_done:
	pop bx
	ret

; Draw player car
draw_player_car:
	push ax
	push bx
	push cx
	push di
	push es
	
	mov ax, 0xB800
	mov es, ax
	
	; Get column from lane
	mov al, [player_lane]
	call get_lane_column
	mov bx, ax
	
	; Calculate position
	mov ax, [player_row]
	push dx
	mov dx, SCREEN_WIDTH
	mul dx
	pop dx
	shl ax, 1
	mov di, ax
	mov ax, bx
	shl ax, 1
	add di, ax
	
	; Row 1 - Top
	sub di, SCREEN_WIDTH * 2
	mov byte [es:di-2], ' '
	mov byte [es:di-1], COLOR_ROAD
	mov byte [es:di], 0xDC
	mov byte [es:di+1], COLOR_RED_CAR
	mov byte [es:di+2], ' '
	mov byte [es:di+3], COLOR_ROAD
	
	; Row 2 - Windows
	add di, SCREEN_WIDTH * 2
	mov byte [es:di-2], 0xDB
	mov byte [es:di-1], COLOR_RED_CAR
	mov byte [es:di], ' '
	mov byte [es:di+1], COLOR_BLACK
	mov byte [es:di+2], 0xDB
	mov byte [es:di+3], COLOR_RED_CAR
	
	; Row 3 - Body
	add di, SCREEN_WIDTH * 2
	mov byte [es:di-2], 0xDB
	mov byte [es:di-1], COLOR_RED_CAR
	mov byte [es:di], 0xDB
	mov byte [es:di+1], COLOR_RED_CAR
	mov byte [es:di+2], 0xDB
	mov byte [es:di+3], COLOR_RED_CAR
	
	; Row 4 - Bottom
	add di, SCREEN_WIDTH * 2
	mov byte [es:di-2], 0xDC
	mov byte [es:di-1], COLOR_YELLOW
	mov byte [es:di], 0xDF
	mov byte [es:di+1], COLOR_RED_CAR
	mov byte [es:di+2], 0xDC
	mov byte [es:di+3], COLOR_YELLOW
	
	pop es
	pop di
	pop cx
	pop bx
	pop ax
	ret

; Draw obstacle car row by row
draw_obstacle_car_row:
	push ax
	push bx
	push cx
	push dx
	push di
	push es
	
	mov dx, 0xB800
	mov es, dx
	
	mov dx, SCREEN_WIDTH
	mul dx
	shl ax, 1
	mov di, ax
	mov ax, bx
	shl ax, 1
	add di, ax
	
	cmp cl, 0
	je draw_obs_row1
	cmp cl, 1
	je draw_obs_row2
	cmp cl, 2
	je draw_obs_row3
	jmp draw_obs_row4
	
draw_obs_row1:
	mov byte [es:di-2], 0xDF
	mov byte [es:di-1], COLOR_YELLOW
	mov byte [es:di], 0xDC
	mov byte [es:di+1], COLOR_BLUE_CAR
	mov byte [es:di+2], 0xDF
	mov byte [es:di+3], COLOR_YELLOW
	jmp draw_obs_done
	
draw_obs_row2:
	mov byte [es:di-2], 0xDB
	mov byte [es:di-1], COLOR_BLUE_CAR
	mov byte [es:di], 0xDB
	mov byte [es:di+1], COLOR_BLUE_CAR
	mov byte [es:di+2], 0xDB
	mov byte [es:di+3], COLOR_BLUE_CAR
	jmp draw_obs_done
	
draw_obs_row3:
	mov byte [es:di-2], 0xDB
	mov byte [es:di-1], COLOR_BLUE_CAR
	mov byte [es:di], ' '
	mov byte [es:di+1], COLOR_BLACK
	mov byte [es:di+2], 0xDB
	mov byte [es:di+3], COLOR_BLUE_CAR
	jmp draw_obs_done
	
draw_obs_row4:
	mov byte [es:di-2], ' '
	mov byte [es:di-1], COLOR_ROAD
	mov byte [es:di], 0xDC
	mov byte [es:di+1], COLOR_BLUE_CAR
	mov byte [es:di+2], ' '
	mov byte [es:di+3], COLOR_ROAD
	
draw_obs_done:
	pop es
	pop di
	pop dx
	pop cx
	pop bx
	pop ax
	ret

; Draw single complete obstacle
draw_single_obstacle:
	push ax
	push bx
	push cx
	
	mov cx, 0
draw_obs_all_rows:
	push ax
	push cx
	call draw_obstacle_car_row
	pop cx
	pop ax
	
	inc ax
	inc cx
	cmp cx, CAR_HEIGHT
	jl draw_obs_all_rows
	
	pop cx
	pop bx
	pop ax
	ret

; Draw all active obstacles with fade-in effect
draw_all_obstacles:
	push ax
	push bx
	push cx
	push dx
	push si
	
	mov cx, MAX_OBSTACLES
	mov si, 0
	
draw_obs_loop:
	cmp byte [obstacle_active + si], 1
	jne skip_obs
	
	; Get obstacle position
	mov bx, si
	shl bx, 1
	mov ax, [obstacle_row + bx]  ; AX = current row
	mov dx, [obstacle_col + bx]  ; DX = column
	
	; Calculate how many rows to draw based on position
	; When row = 2, draw 1 row
	; When row = 3, draw 2 rows
	; When row = 4, draw 3 rows
	; When row >= 5, draw all 4 rows
	
	push si
	push ax
	push dx
	
	; Determine number of rows to draw
	mov cx, ax      ; CX = current row position (0, 1, 2, 3...)
	inc cx          ; CX = number of rows to draw (1, 2, 3, 4...)
	
	; Cap at 4 rows maximum
	cmp cx, CAR_HEIGHT
	jle rows_ok
	mov cx, CAR_HEIGHT
rows_ok:
	
	; Draw only the visible rows
	mov si, 0       ; SI = which row we're drawing (0-3)
	
draw_partial_car:
	cmp si, cx      ; Have we drawn enough rows?
	jge done_partial_car
	
	; Draw this row
	push ax
	push bx
	push cx
	push si
	
	; Calculate actual screen row for this car row
	mov bx, dx      ; Column
	mov cx, si      ; Which car row (0-3)
	; AX already has base row
	
	call draw_obstacle_car_row
	
	pop si
	pop cx
	pop bx
	pop ax
	
	inc ax          ; Next screen row
	inc si          ; Next car row
	jmp draw_partial_car
	
done_partial_car:
	pop dx
	pop ax
	pop si
	
skip_obs:
	inc si
	loop draw_obs_loop
	
	pop si
	pop dx
	pop cx
	pop bx
	pop ax
	ret

; Draw single coin
draw_single_coin:
	push ax
	push bx
	push cx
	push di
	push es
	
	mov cx, 0xB800
	mov es, cx
	
	mov cx, SCREEN_WIDTH
	mul cx
	shl ax, 1
	mov di, ax
	mov ax, bx
	shl ax, 1
	add di, ax
	
	mov byte [es:di], '$'
	mov byte [es:di+1], COLOR_COIN
	
	pop es
	pop di
	pop cx
	pop bx
	pop ax
	ret

; Draw all active coins
draw_all_coins:
	push ax
	push bx
	push cx
	push si
	
	mov cx, MAX_COINS
	mov si, 0
	
draw_coin_loop:
	cmp byte [coin_active + si], 1
	jne skip_coin
	
	mov bx, si
	shl bx, 1
	mov ax, [coin_row + bx]
	mov bx, [coin_col + bx]
	call draw_single_coin
	
skip_coin:
	inc si
	loop draw_coin_loop
	
	pop si
	pop cx
	pop bx
	pop ax
	ret

; Draw single fuel
draw_single_fuel:
	push ax
	push bx
	push cx
	push di
	push es
	
	mov cx, 0xB800
	mov es, cx
	
	mov cx, SCREEN_WIDTH
	mul cx
	shl ax, 1
	mov di, ax
	mov ax, bx
	shl ax, 1
	add di, ax
	
	mov byte [es:di], 'F'
	mov byte [es:di+1], COLOR_FUEL
	
	pop es
	pop di
	pop cx
	pop bx
	pop ax
	ret

; Draw all active fuel
draw_all_fuel:
	push ax
	push bx
	push cx
	push si
	
	mov cx, MAX_FUEL
	mov si, 0
	
draw_fuel_loop:
	cmp byte [fuel_active + si], 1
	jne skip_fuel
	
	mov bx, si
	shl bx, 1
	mov ax, [fuel_row + bx]
	mov bx, [fuel_col + bx]
	call draw_single_fuel
	
skip_fuel:
	inc si
	loop draw_fuel_loop
	
	pop si
	pop cx
	pop bx
	pop ax
	ret

; Draw all game objects
draw_all_objects:
	call draw_all_obstacles
	call draw_all_coins
	call draw_all_fuel
	call draw_player_car
	ret

; Display HUD
display_hud:
	push ax
	push bx
	push cx
	push dx
	push di
	push es
	push si
	
	mov ax, 0xB800
	mov es, ax
	
	; Display "Score: "
	mov di, 2
	mov si, score_msg
hud_score_str:
	lodsb
	cmp al, 0
	je hud_score_num
	mov byte [es:di], al
	mov byte [es:di+1], 0x0F
	add di, 2
	jmp hud_score_str
	
hud_score_num:
	mov ax, [score]
	mov bx, 10
	mov cx, 0
hud_score_conv:
	mov dx, 0
	div bx
	push dx
	inc cx
	cmp ax, 0
	jne hud_score_conv
	
hud_score_print:
	pop dx
	add dl, '0'
	mov byte [es:di], dl
	mov byte [es:di+1], 0x0F
	add di, 2
	loop hud_score_print
	
	; Display "Fuel: "
	mov di, 140
	mov si, fuel_msg
hud_fuel_str:
	lodsb
	cmp al, 0
	je hud_fuel_num
	mov byte [es:di], al
	mov byte [es:di+1], 0x0F
	add di, 2
	jmp hud_fuel_str
	
hud_fuel_num:
	mov ax, [fuel_level]
	mov bx, 10
	mov cx, 0
hud_fuel_conv:
	mov dx, 0
	div bx
	push dx
	inc cx
	cmp ax, 0
	jne hud_fuel_conv
	
hud_fuel_print:
	pop dx
	add dl, '0'
	mov byte [es:di], dl
	mov byte [es:di+1], 0x0F
	add di, 2
	loop hud_fuel_print
	
	pop si
	pop es
	pop di
	pop dx
	pop cx
	pop bx
	pop ax
	ret

; ==================== SCREEN DISPLAYS ====================

; Show introduction screen
show_intro_screen:
	push ax
	push bx
	push si
	
	call clear_screen
	
	; Draw title at top
	mov si, title_msg
	mov bh, 8
	mov bl, 34
	call print_string_large
	
	; Draw "Developed by:"
	mov si, developer1_msg
	mov bh, 12
	mov bl, 30
	call print_string
	
	; Draw developer 1
	mov si, developer2_msg
	mov bh, 14
	mov bl, 20
	call print_string
	
	; Draw developer 2
	mov si, developer3_msg
	mov bh, 15
	mov bl, 20
	call print_string
	
	; Draw instruction to continue
	mov si, press_key_msg
	mov bh, 20
	mov bl, 25
	call print_string
	
	pop si
	pop bx
	pop ax
	ret

; Show player input screen
show_input_screen:
	push ax
	push bx
	push si
	
	call clear_screen
	
	; Display title
	mov si, input_title
	mov bh, 6
	mov bl, 28
	call print_string_large
	
	; Get player name
	mov si, name_prompt
	mov bh, 10
	mov bl, 20
	call print_string
	
	mov bh, 10
	mov bl, 37
	mov di, player_name
	mov cl, 29  ; Max length
	call get_text_input
	mov [player_name_len], al
	
	; Get roll number
	mov si, roll_prompt
	mov bh, 12
	mov bl, 20
	call print_string
	
	mov bh, 12
	mov bl, 45
	mov di, player_rollno
	mov cl, 14  ; Max length
	call get_text_input
	mov [player_rollno_len], al
	
	; Show continue message
	mov si, input_done_msg
	mov bh, 16
	mov bl, 25
	call print_string
	
	; Wait for ENTER
wait_input_enter:
	mov ah, 0x00
	int 0x16
	cmp al, 0x0D  ; ENTER
	jne wait_input_enter
	
	pop si
	pop bx
	pop ax
	ret

; Get text input from user
; Input: BH = row, BL = start col, DI = buffer, CL = max length
; Output: AL = length entered
get_text_input:
	push bx
	push cx
	push dx
	push di
	push si
	
	mov byte [di], 0  ; Clear first byte
	xor si, si  ; Length counter
	
input_loop:
	; Wait for key
	mov ah, 0x00
	int 0x16
	
	; Check for Enter (done)
	cmp al, 0x0D
	je input_done
	
	; Check for Backspace
	cmp al, 0x08
	je input_backspace
	
	; Check if printable character
	cmp al, 32
	jl input_loop
	cmp al, 126
	jg input_loop
	
	; Check length limit
	cmp si, cx
	jge input_loop
	
	; Store character using BP for addressing
	push bp
	mov bp, di
	add bp, si
	mov [bp], al
	pop bp
	
	inc si
	
	; Echo character to screen
	push ax
	call print_char_at
	pop ax
	inc bl  ; Move cursor right
	
	jmp input_loop
	
input_backspace:
	; Check if anything to delete
	cmp si, 0
	je input_loop
	
	; Remove character
	dec si
	dec bl
	
	; Clear in buffer
	push bp
	mov bp, di
	add bp, si
	mov byte [bp], 0
	pop bp
	
	; Clear character on screen
	push ax
	mov al, ' '
	call print_char_at
	pop ax
	
	jmp input_loop
	
input_done:
	; Null terminate
	push bp
	mov bp, di
	add bp, si
	mov byte [bp], 0
	pop bp
	
	; Return length in AL
	mov ax, si
	; AL already contains lower byte of SI
	
	pop si
	pop di
	pop dx
	pop cx
	pop bx
	ret

; Print character at cursor position
; Input: AL = char, BH = row, BL = col
print_char_at:
	push ax
	push bx
	push cx
	push di
	push es
	
	mov cx, 0xB800
	mov es, cx
	
	; Calculate position
	push ax
	mov al, bh
	mov ah, 0
	push dx
	mov dx, 80
	mul dx
	pop dx
	mov di, ax
	mov al, bl
	mov ah, 0
	add di, ax
	shl di, 1
	pop ax
	
	; Write character
	mov byte [es:di], al
	mov byte [es:di+1], 0x0F
	
	pop es
	pop di
	pop cx
	pop bx
	pop ax
	ret

; Show instruction screen
show_instruction_screen:
	push ax
	push bx
	push si
	
	call clear_screen
	
	; Draw title
	mov si, instructions_title
	mov bh, 5
	mov bl, 32
	call print_string_large
	
	; Draw instructions line by line
	mov si, inst_line1
	mov bh, 9
	mov bl, 15
	call print_string
	
	mov si, inst_line2
	mov bh, 11
	mov bl, 15
	call print_string
	
	mov si, inst_line3
	mov bh, 13
	mov bl, 15
	call print_string
	
	mov si, inst_line4
	mov bh, 14
	mov bl, 15
	call print_string
	
	mov si, inst_line5
	mov bh, 16
	mov bl, 15
	call print_string
	
	mov si, inst_line6
	mov bh, 17
	mov bl, 15
	call print_string
	
	mov si, inst_line7
	mov bh, 18
	mov bl, 15
	call print_string
	
	; Draw start instruction
	mov si, press_start_msg
	mov bh, 22
	mov bl, 23
	call print_string
	
	pop si
	pop bx
	pop ax
	ret

; Print string in large/highlighted format
print_string_large:
	push ax
	push bx
	push cx
	push di
	push es
	push si
	
	mov ax, 0xB800
	mov es, ax
	
	mov al, bh
	mov ah, 0
	mov cx, SCREEN_WIDTH
	mul cx
	mov di, ax
	mov al, bl
	mov ah, 0
	add di, ax
	shl di, 1
	
print_str_large_loop:
	lodsb
	cmp al, 0
	je print_str_large_done
	
	mov byte [es:di], al
	mov byte [es:di+1], 0x0E	; Yellow on black
	add di, 2
	jmp print_str_large_loop
	
print_str_large_done:
	pop si
	pop es
	pop di
	pop cx
	pop bx
	pop ax
	ret

; Show quit confirmation
show_quit_confirmation:
	push ax
	push bx
	push cx
	push dx
	push di
	push es
	push si
	
	mov ax, 0xB800
	mov es, ax
	
	; Draw a centered box
	; Box dimensions: 40 chars wide, 5 rows tall
	; Starting position: row 10, col 20
	
	; Draw top border
	mov bx, 10
	mov cx, 20
	call draw_box_line_top
	
	; Draw empty line
	mov bx, 11
	mov cx, 20
	call draw_box_line_middle
	
	; Draw message line
	mov bx, 12
	mov cx, 20
	call draw_box_line_middle
	
	; Draw empty line
	mov bx, 13
	mov cx, 20
	call draw_box_line_middle
	
	; Draw bottom border
	mov bx, 14
	mov cx, 20
	call draw_box_line_bottom
	
	; Draw the message
	mov si, quit_confirm_msg
	mov bh, 12
	mov bl, 27
	call print_string_white_bg
	
	pop si
	pop es
	pop di
	pop dx
	pop cx
	pop bx
	pop ax
	ret

; Draw top border line
draw_box_line_top:
	push ax
	push cx
	push di
	
	mov al, bl
	mov ah, 0
	push dx
	mov dx, SCREEN_WIDTH
	mul dx
	pop dx
	mov di, ax
	mov ax, cx
	add di, ax
	shl di, 1
	
	; Top-left corner
	mov byte [es:di], 0xDA
	mov byte [es:di+1], 0x1F
	add di, 2
	
	; Top border (38 chars)
	mov cx, 38
draw_top_loop:
	mov byte [es:di], 0xC4
	mov byte [es:di+1], 0x1F
	add di, 2
	loop draw_top_loop
	
	; Top-right corner
	mov byte [es:di], 0xBF
	mov byte [es:di+1], 0x1F
	
	pop di
	pop cx
	pop ax
	ret

; Draw middle line
draw_box_line_middle:
	push ax
	push cx
	push di
	
	mov al, bl
	mov ah, 0
	push dx
	mov dx, SCREEN_WIDTH
	mul dx
	pop dx
	mov di, ax
	mov ax, cx
	add di, ax
	shl di, 1
	
	; Left border
	mov byte [es:di], 0xB3
	mov byte [es:di+1], 0x1F
	add di, 2
	
	; Middle (38 spaces)
	mov cx, 38
draw_middle_loop:
	mov byte [es:di], ' '
	mov byte [es:di+1], 0x1F
	add di, 2
	loop draw_middle_loop
	
	; Right border
	mov byte [es:di], 0xB3
	mov byte [es:di+1], 0x1F
	
	pop di
	pop cx
	pop ax
	ret

; Draw bottom border line
draw_box_line_bottom:
	push ax
	push cx
	push di
	
	mov al, bl
	mov ah, 0
	push dx
	mov dx, SCREEN_WIDTH
	mul dx
	pop dx
	mov di, ax
	mov ax, cx
	add di, ax
	shl di, 1
	
	; Bottom-left corner
	mov byte [es:di], 0xC0
	mov byte [es:di+1], 0x1F
	add di, 2
	
	; Bottom border (38 chars)
	mov cx, 38
draw_bottom_loop:
	mov byte [es:di], 0xC4
	mov byte [es:di+1], 0x1F
	add di, 2
	loop draw_bottom_loop
	
	; Bottom-right corner
	mov byte [es:di], 0xD9
	mov byte [es:di+1], 0x1F
	
	pop di
	pop cx
	pop ax
	ret

; Print string with white on blue
print_string_white_bg:
	push ax
	push bx
	push cx
	push di
	push es
	push si
	
	mov ax, 0xB800
	mov es, ax
	
	mov al, bh
	mov ah, 0
	mov cx, SCREEN_WIDTH
	mul cx
	mov di, ax
	mov al, bl
	mov ah, 0
	add di, ax
	shl di, 1
	
print_str_wb_loop:
	lodsb
	cmp al, 0
	je print_str_wb_done
	
	mov byte [es:di], al
	mov byte [es:di+1], 0x1F
	add di, 2
	jmp print_str_wb_loop
	
print_str_wb_done:
	pop si
	pop es
	pop di
	pop cx
	pop bx
	pop ax
	ret

; Print string
print_string:
	push ax
	push bx
	push cx
	push di
	push es
	push si
	
	mov ax, 0xB800
	mov es, ax
	
	mov al, bh
	mov ah, 0
	mov cx, SCREEN_WIDTH
	mul cx
	mov di, ax
	mov al, bl
	mov ah, 0
	add di, ax
	shl di, 1
	
print_str_loop:
	lodsb
	cmp al, 0
	je print_str_done
	
	mov byte [es:di], al
	mov byte [es:di+1], 0x0F
	add di, 2
	jmp print_str_loop
	
print_str_done:
	pop si
	pop es
	pop di
	pop cx
	pop bx
	pop ax
	ret

; ==================== RANDOM NUMBER SUBROUTINES ====================

; Get random number
get_random:
	push dx
	
	mov al, 0x00
	out 0x70, al
	jmp delay1
delay1:	
	in al, 0x71
	mov ah, al
	
	mov al, 0x02
	out 0x70, al
	jmp delay2
delay2:
	in al, 0x71
	
	add al, ah
	mov ah, 0
	
	pop dx
	ret

; Get random lane position
get_random_lane:
	push bx
	push dx
	
	call get_random
	
	mov dx, 0
	mov bx, 3
	div bx
	
	cmp dx, 0
	je rand_lane1
	cmp dx, 1
	je rand_lane2
	jmp rand_lane3
	
rand_lane1:
	mov ax, LANE_LEFT
	jmp rand_lane_done
rand_lane2:
	mov ax, LANE_CENTER
	jmp rand_lane_done
rand_lane3:
	mov ax, LANE_RIGHT
	
rand_lane_done:
	pop dx
	pop bx
	ret

; ==================== SPAWN SUBROUTINES ====================

; Check spawn spacing
check_spawn_spacing:
	push ax
	push bx
	
	mov ax, [last_spawn_row]
	
	cmp ax, 50
	jg can_spawn
	
	sub ax, 2
	
	cmp ax, MIN_ITEM_SPACING
	jl cannot_spawn
	
can_spawn:
	pop bx
	pop ax
	clc
	ret
	
cannot_spawn:
	pop bx
	pop ax
	stc
	ret

; Spawn obstacle
spawn_obstacle:
	push ax
	push bx
	push cx
	push si
	
	call check_spawn_spacing
	jc spawn_obs_done
	
	mov cx, MAX_OBSTACLES
	mov si, 0
	
find_obs_slot:
	cmp byte [obstacle_active + si], 0
	je found_obs_slot
	inc si
	loop find_obs_slot
	jmp spawn_obs_done
	
found_obs_slot:
	mov byte [obstacle_active + si], 1
	mov byte [obstacle_fade_state + si], 0
	
	mov bx, si
	shl bx, 1
	mov word [obstacle_row + bx], 0	; Spawn from very top
	
	call get_random_lane
	mov [obstacle_col + bx], ax
	
	mov word [last_spawn_row], 0	; Track spawn at row 0
	
spawn_obs_done:
	pop si
	pop cx
	pop bx
	pop ax
	ret

; Spawn coin
spawn_coin:
	push ax
	push bx
	push cx
	push si
	
	call check_spawn_spacing
	jc spawn_coin_done
	
	mov cx, MAX_COINS
	mov si, 0
	
find_coin_slot:
	cmp byte [coin_active + si], 0
	je found_coin_slot
	inc si
	loop find_coin_slot
	jmp spawn_coin_done
	
found_coin_slot:
	mov byte [coin_active + si], 1
	
	mov bx, si
	shl bx, 1
	mov word [coin_row + bx], 1	; Spawn from near top
	
	call get_random_lane
	mov [coin_col + bx], ax
	
	mov word [last_spawn_row], 1	; Track spawn at row 1
	
spawn_coin_done:
	pop si
	pop cx
	pop bx
	pop ax
	ret

; Spawn fuel
spawn_fuel:
	push ax
	push bx
	push cx
	push si
	
	call check_spawn_spacing
	jc spawn_fuel_done
	
	mov cx, MAX_FUEL
	mov si, 0
	
find_fuel_slot:
	cmp byte [fuel_active + si], 0
	je found_fuel_slot
	inc si
	loop find_fuel_slot
	jmp spawn_fuel_done
	
found_fuel_slot:
	mov byte [fuel_active + si], 1
	
	mov bx, si
	shl bx, 1
	mov word [fuel_row + bx], 1	; Spawn from near top
	
	call get_random_lane
	mov [fuel_col + bx], ax
	
	mov word [last_spawn_row], 1	; Track spawn at row 1
	
spawn_fuel_done:
	pop si
	pop cx
	pop bx
	pop ax
	ret

; Handle spawning
handle_spawning:
	push ax
	push bx
	push dx
	
	mov ax, [frame_count]
	mov dx, 0
	mov bx, OBSTACLE_SPAWN_FREQ
	div bx
	
	cmp dx, 0
	jne check_coin_spawn
	call spawn_obstacle
	
check_coin_spawn:
	mov ax, [frame_count]
	mov dx, 0
	mov bx, COIN_SPAWN_FREQ
	div bx
	
	cmp dx, 15
	jne check_fuel_spawn
	call spawn_coin
	
check_fuel_spawn:
	mov ax, [frame_count]
	mov dx, 0
	mov bx, FUEL_SPAWN_FREQ
	div bx
	
	cmp dx, 30
	jne spawn_done
	call spawn_fuel
	
spawn_done:
	pop dx
	pop bx
	pop ax
	ret

; ==================== UPDATE SUBROUTINES ====================

; Update obstacles
update_obstacles:
	push ax
	push bx
	push cx
	push si
	
	mov cx, MAX_OBSTACLES
	mov si, 0
	
update_obs_loop:
	cmp byte [obstacle_active + si], 0
	je skip_update_obs
	
	mov bx, si
	shl bx, 1
	inc word [obstacle_row + bx]
	
	cmp word [obstacle_row + bx], 24
	jl skip_update_obs
	
	mov byte [obstacle_active + si], 0
	
skip_update_obs:
	inc si
	loop update_obs_loop
	
	pop si
	pop cx
	pop bx
	pop ax
	ret

; Update coins
update_coins:
	push ax
	push bx
	push cx
	push si
	
	mov cx, MAX_COINS
	mov si, 0
	
update_coin_loop:
	cmp byte [coin_active + si], 0
	je skip_update_coin
	
	mov bx, si
	shl bx, 1
	inc word [coin_row + bx]
	
	cmp word [coin_row + bx], 24
	jl skip_update_coin
	
	mov byte [coin_active + si], 0
	
skip_update_coin:
	inc si
	loop update_coin_loop
	
	pop si
	pop cx
	pop bx
	pop ax
	ret

; Update fuel
update_fuel:
	push ax
	push bx
	push cx
	push si
	
	mov cx, MAX_FUEL
	mov si, 0
	
update_fuel_loop:
	cmp byte [fuel_active + si], 0
	je skip_update_fuel
	
	mov bx, si
	shl bx, 1
	inc word [fuel_row + bx]
	
	cmp word [fuel_row + bx], 24
	jl skip_update_fuel
	
	mov byte [fuel_active + si], 0
	
skip_update_fuel:
	inc si
	loop update_fuel_loop
	
	pop si
	pop cx
	pop bx
	pop ax
	ret

; Update last spawn row
update_last_spawn_row:
	push ax
	
	mov ax, [last_spawn_row]
	cmp ax, 50
	jg update_spawn_done
	
	inc word [last_spawn_row]
	
	cmp word [last_spawn_row], 25
	jl update_spawn_done
	mov word [last_spawn_row], 100
	
update_spawn_done:
	pop ax
	ret

; Update all positions
update_all_positions:
	call update_obstacles
	call update_coins
	call update_fuel
	call update_last_spawn_row
	ret

; Update lane scrolling
update_lane_scrolling:
	push ax
	
	inc word [lane_offset]
	cmp word [lane_offset], 4
	jl lane_scroll_done
	mov word [lane_offset], 0
	
lane_scroll_done:
	pop ax
	ret

; Update fuel level
update_fuel_level:
	push ax
	
	mov ax, [frame_count]
	and ax, FUEL_DECREASE_RATE - 1
	cmp ax, 0
	jne fuel_update_done
	
	cmp word [fuel_level], 0
	je fuel_update_done
	dec word [fuel_level]
	
fuel_update_done:
	pop ax
	ret

; Update score
update_score:
	inc word [score]
	ret

; Update frame counter
update_frame_counter:
	inc word [frame_count]
	ret

; Update game state
update_game_state:
	call update_lane_scrolling
	call update_fuel_level
	call update_score
	call update_frame_counter
	ret

; ==================== GAME CHECKS ====================

; Check game over
check_game_over:
	push ax
	
	cmp word [fuel_level], 0
	jg not_game_over
	
	pop ax
	stc
	ret
	
not_game_over:
	pop ax
	clc
	ret

; Show game over
show_game_over:
	push ax
	push bx
	push si
	
	mov si, gameover_msg
	mov bh, 12
	mov bl, 25
	call print_string
	
wait_exit:
	mov ah, 0x00
	int 0x16
	cmp ah, 0x01
	jne wait_exit
	
	pop si
	pop bx
	pop ax
	ret

; ==================== DELAY ====================

delay:
	push cx
	push dx
	
	mov cx, DELAY_HIGH
	mov dx, DELAY_LOW
	mov ah, 0x86
	int 0x15
	
	pop dx
	pop cx
	ret

; ==================== MAIN PROGRAM ====================
start:
	call init_game
	
	; Show introduction screen
	call show_intro_screen
	
wait_intro:
	mov ah, 0x00
	int 0x16
	
	; Show player input screen
	call show_input_screen
	
	; Show instruction screen
	call show_instruction_screen
	
wait_instructions:
	mov ah, 0x00
	int 0x16
	
	; Set in-game flag
	mov byte [in_game], 1
	
	; Clear and wait for game start
	call clear_screen
	
wait_game_start:
	cmp byte [game_started], 0
	je wait_game_start
	
game_loop:
	; Check if paused
	cmp byte [game_paused], 0
	je game_running
	
	; Check if quit requested
	cmp byte [game_paused], 2
	je exit_game
	
	; Show quit confirmation only once
	cmp byte [show_quit_confirm], 1
	jne pause_wait
	
	; Check if already drawn
	cmp byte [confirm_drawn], 1
	je pause_wait
	
	; Draw confirmation box once
	call show_quit_confirmation
	mov byte [confirm_drawn], 1
	
pause_wait:
	; Just wait while paused
	call delay
	jmp game_loop
	
game_running:
	call draw_background
	call draw_all_objects
	call display_hud
	call update_all_positions
	call handle_spawning
	call update_game_state
	
	call check_game_over
	jc game_over
	
	call delay
	jmp game_loop
	
game_over:
	call show_game_over
	
exit_game:
	call cleanup_game
	
	mov ax, 0x4C00
	int 21h