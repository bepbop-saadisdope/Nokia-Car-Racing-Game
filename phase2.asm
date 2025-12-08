[org 0x0100]
jmp start

; ==================== DATA SECTION ====================
; Screen dimensions
SCREEN_WIDTH	equ 80
SCREEN_HEIGHT	equ 25

; Road layout - wider road, narrower grass
GRASS_WIDTH	equ 5
ROAD_START	equ 5
ROAD_WIDTH	equ 70
ROAD_END	equ 75

; Lane positions (centered in lanes)
LANE1_COL	equ 20
LANE2_COL	equ 35
LANE3_COL	equ 50
LANE4_COL	equ 65

; Colors - more pleasant
COLOR_GRASS	equ 0xAA	; bright green on bright green
COLOR_BORDER	equ 0x22	; dark green border
COLOR_ROAD	equ 0x88	; dark gray road
COLOR_LANE	equ 0x8F	; white on dark gray
COLOR_RED_CAR	equ 0xCC	; bright red
COLOR_BLUE_CAR	equ 0x99	; bright blue
COLOR_YELLOW	equ 0xEE	; yellow (for car details)
COLOR_BLACK	equ 0x00	; black (for windows)
COLOR_COIN	equ 0xE0	; yellow on black for coins
COLOR_FUEL	equ 0x4F	; white on red for fuel

; Animation parameters
ANIMATION_DELAY	equ 3		; Delay between frames (smaller = faster)
SPAWN_TIME	equ 30		; Frames between obstacle spawns

; Delay timing (adjust these to change animation speed)
; Higher values = slower animation, Lower values = faster animation
; Try values between 0x4000 (fast) and 0xFFFF (slow)
DELAY_HIGH	equ 0x0001	; High word of delay
DELAY_LOW	equ 0x8000	; Low word of delay (change this mainly)

; Car positions
player_row:	dw 20
player_col:	dw 35		; center lane (lane 2)

; Obstacle array (up to 5 obstacles on screen)
MAX_OBSTACLES	equ 5
obstacle_active:	times MAX_OBSTACLES db 0	; 1 = active, 0 = inactive
obstacle_row:		times MAX_OBSTACLES dw 0
obstacle_col:		times MAX_OBSTACLES dw 0

; Coin array (up to 8 coins on screen)
MAX_COINS	equ 8
coin_active:	times MAX_COINS db 0
coin_row:	times MAX_COINS dw 0
coin_col:	times MAX_COINS dw 0

; Fuel array (up to 3 fuel items on screen)
MAX_FUEL	equ 3
fuel_active:	times MAX_FUEL db 0
fuel_row:	times MAX_FUEL dw 0
fuel_col:	times MAX_FUEL dw 0

; Game state
frame_count:	dw 0
score:		dw 0
fuel_level:	dw 100		; starts at 100%
lane_offset:	dw 0		; for scrolling lane markers

; Messages
score_msg:	db 'Score: ', 0
fuel_msg:	db 'Fuel: ', 0
gameover_msg:	db 'GAME OVER! Press ESC to exit', 0

; ==================== SUBROUTINES ====================

; Clear screen properly - both BIOS and manual clear
clear_screen:
	push ax
	push cx
	push di
	push es
	
	; BIOS clear
	mov ah, 0x00
	mov al, 0x03
	int 10h
	
	; Manual clear - fill entire screen with spaces
	mov ax, 0xB800
	mov es, ax
	mov di, 0
	mov cx, SCREEN_WIDTH * SCREEN_HEIGHT
	mov ax, 0x0720		; black background, white text, space
	cld
	rep stosw
	
	; Reset cursor to home
	mov ah, 0x02
	mov bh, 0
	mov dx, 0
	int 10h
	
	pop es
	pop di
	pop cx
	pop ax
	ret

; Draw grass borders with darker edges
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
	
	; Left grass border
	mov cx, GRASS_WIDTH
	mov ax, 0xAA20		; bright green
	cld
	rep stosw
	
	pop di
	push di
	
	; Right grass border
	add di, ROAD_END * 2
	mov cx, GRASS_WIDTH
	mov ax, 0xAA20		; bright green
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

; Draw road with darker gray
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
	mov ax, 0x8820		; dark gray road
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

; Draw lane markers with scrolling effect - 3 lanes (4 sections)
draw_lanes:
	push ax
	push bx
	push cx
	push dx
	push di
	push es
	
	mov ax, 0xB800
	mov es, ax
	
	; Lane 1 divider (column 27)
	mov bx, 27
	call draw_single_lane
	
	; Lane 2 divider (column 42)
	mov bx, 42
	call draw_single_lane
	
	; Lane 3 divider (column 57)
	mov bx, 57
	call draw_single_lane
	
	pop es
	pop di
	pop dx
	pop cx
	pop bx
	pop ax
	ret

draw_single_lane:
	push ax
	push cx
	push di
	
	mov cx, 0
	
lane_loop:
	; Add offset for scrolling effect
	mov ax, cx
	add ax, [lane_offset]
	
	; Draw marker every 2 rows, skip 2 rows (creates dashed pattern)
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
	; Calculate position
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
	
	; Draw white dashed line
	mov byte [es:di], 0xDB		; solid block
	mov byte [es:di+1], 0x8F	; white on gray
	
skip_marker:
	inc cx
	cmp cx, SCREEN_HEIGHT
	jl lane_loop
	
	pop di
	pop cx
	pop ax
	ret

; Draw player car (red) - improved design
draw_player_car:
	push ax
	push bx
	push cx
	push di
	push es
	
	mov ax, 0xB800
	mov es, ax
	
	; Calculate position
	mov ax, [player_row]
	mov bx, SCREEN_WIDTH
	mul bx
	shl ax, 1
	mov di, ax
	mov ax, [player_col]
	shl ax, 1
	add di, ax
	
	; Row 1 - Top of car (roof)
	sub di, SCREEN_WIDTH * 2
	mov byte [es:di-2], ' '
	mov byte [es:di-1], 0x88
	mov byte [es:di], 0xDC		; upper half block
	mov byte [es:di+1], 0xCC	; bright red
	mov byte [es:di+2], ' '
	mov byte [es:di+3], 0x88
	
	; Row 2 - Windows
	add di, SCREEN_WIDTH * 2
	mov byte [es:di-2], 0xDB	; solid
	mov byte [es:di-1], 0xCC	; red
	mov byte [es:di], ' '		; window
	mov byte [es:di+1], 0x00	; black window
	mov byte [es:di+2], 0xDB	; solid
	mov byte [es:di+3], 0xCC	; red
	
	; Row 3 - Body
	add di, SCREEN_WIDTH * 2
	mov byte [es:di-2], 0xDB
	mov byte [es:di-1], 0xCC	; red
	mov byte [es:di], 0xDB
	mov byte [es:di+1], 0xCC	; red
	mov byte [es:di+2], 0xDB
	mov byte [es:di+3], 0xCC	; red
	
	; Row 4 - Bottom with lights
	add di, SCREEN_WIDTH * 2
	mov byte [es:di-2], 0xDC	; upper half
	mov byte [es:di-1], 0xEE	; yellow (headlight)
	mov byte [es:di], 0xDF		; lower half
	mov byte [es:di+1], 0xCC	; red
	mov byte [es:di+2], 0xDC	; upper half
	mov byte [es:di+3], 0xEE	; yellow (headlight)
	
	pop es
	pop di
	pop cx
	pop bx
	pop ax
	ret

; Draw single obstacle car (blue) - improved design
; Input: AX = row, BX = col
draw_single_obstacle:
	push ax
	push bx
	push cx
	push di
	push es
	
	mov cx, 0xB800
	mov es, cx
	
	; Calculate position
	mov cx, SCREEN_WIDTH
	mul cx
	shl ax, 1
	mov di, ax
	mov ax, bx
	shl ax, 1
	add di, ax
	
	; Row 1 - Top lights
	mov byte [es:di-2], 0xDF	; lower half
	mov byte [es:di-1], 0xEE	; yellow
	mov byte [es:di], 0xDC		; upper half
	mov byte [es:di+1], 0x99	; blue
	mov byte [es:di+2], 0xDF	; lower half
	mov byte [es:di+3], 0xEE	; yellow
	
	; Row 2 - Body
	add di, SCREEN_WIDTH * 2
	mov byte [es:di-2], 0xDB
	mov byte [es:di-1], 0x99	; bright blue
	mov byte [es:di], 0xDB
	mov byte [es:di+1], 0x99
	mov byte [es:di+2], 0xDB
	mov byte [es:di+3], 0x99
	
	; Row 3 - Windows
	add di, SCREEN_WIDTH * 2
	mov byte [es:di-2], 0xDB
	mov byte [es:di-1], 0x99
	mov byte [es:di], ' '		; window
	mov byte [es:di+1], 0x00	; black window
	mov byte [es:di+2], 0xDB
	mov byte [es:di+3], 0x99
	
	; Row 4 - Bottom (roof when viewed from behind)
	add di, SCREEN_WIDTH * 2
	mov byte [es:di-2], ' '
	mov byte [es:di-1], 0x88
	mov byte [es:di], 0xDC
	mov byte [es:di+1], 0x99
	mov byte [es:di+2], ' '
	mov byte [es:di+3], 0x88
	
	pop es
	pop di
	pop cx
	pop bx
	pop ax
	ret

; Draw all active obstacles
draw_all_obstacles:
	push ax
	push bx
	push cx
	push si
	
	mov cx, MAX_OBSTACLES
	mov si, 0
	
draw_obs_loop:
	cmp byte [obstacle_active + si], 1
	jne skip_obs
	
	; Load position and draw
	mov bx, si
	shl bx, 1
	mov ax, [obstacle_row + bx]
	mov bx, [obstacle_col + bx]
	call draw_single_obstacle
	
skip_obs:
	inc si
	loop draw_obs_loop
	
	pop si
	pop cx
	pop bx
	pop ax
	ret

; Draw a coin at specified position
; Input: AX = row, BX = col
draw_single_coin:
	push ax
	push bx
	push cx
	push di
	push es
	
	mov cx, 0xB800
	mov es, cx
	
	; Calculate position
	mov cx, SCREEN_WIDTH
	mul cx
	shl ax, 1
	mov di, ax
	mov ax, bx
	shl ax, 1
	add di, ax
	
	; Draw coin (using $ character)
	mov byte [es:di], '$'
	mov byte [es:di+1], COLOR_COIN	; yellow on black
	
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
	
	; Load position and draw
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

; Draw a fuel item at specified position
; Input: AX = row, BX = col
draw_single_fuel:
	push ax
	push bx
	push cx
	push di
	push es
	
	mov cx, 0xB800
	mov es, cx
	
	; Calculate position
	mov cx, SCREEN_WIDTH
	mul cx
	shl ax, 1
	mov di, ax
	mov ax, bx
	shl ax, 1
	add di, ax
	
	; Draw fuel (using F character)
	mov byte [es:di], 'F'
	mov byte [es:di+1], COLOR_FUEL	; white on red
	
	pop es
	pop di
	pop cx
	pop bx
	pop ax
	ret

; Draw all active fuel items
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
	
	; Load position and draw
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

; Get random number using RTC
; Output: AX = random number (0-255)
get_random:
	push dx
	
	; Get current second
	mov al, 0x00
	out 0x70, al
	jmp delay1
delay1:	
	in al, 0x71
	mov ah, al
	
	; Get current minute  
	mov al, 0x02
	out 0x70, al
	jmp delay2
delay2:
	in al, 0x71
	
	; Combine them
	add al, ah
	mov ah, 0
	
	pop dx
	ret

; Get random lane position (1-4)
; Output: AX = lane column position
get_random_lane:
	push bx
	push dx
	
	call get_random
	
	; Modulo 4 to get lane 0-3
	mov dx, 0
	mov bx, 4
	div bx
	
	; Convert to column position
	cmp dx, 0
	je rand_lane1
	cmp dx, 1
	je rand_lane2
	cmp dx, 2
	je rand_lane3
	jmp rand_lane4
	
rand_lane1:
	mov ax, LANE1_COL
	jmp rand_lane_done
rand_lane2:
	mov ax, LANE2_COL
	jmp rand_lane_done
rand_lane3:
	mov ax, LANE3_COL
	jmp rand_lane_done
rand_lane4:
	mov ax, LANE4_COL
	
rand_lane_done:
	pop dx
	pop bx
	ret

; Spawn new obstacle at top of screen
spawn_obstacle:
	push ax
	push bx
	push cx
	push si
	
	; Find inactive obstacle slot
	mov cx, MAX_OBSTACLES
	mov si, 0
	
find_obs_slot:
	cmp byte [obstacle_active + si], 0
	je found_obs_slot
	inc si
	loop find_obs_slot
	jmp spawn_obs_done		; No slot available
	
found_obs_slot:
	; Activate obstacle
	mov byte [obstacle_active + si], 1
	
	; Set row to top
	mov bx, si
	shl bx, 1
	mov word [obstacle_row + bx], 2
	
	; Set random column (lane)
	call get_random_lane
	mov [obstacle_col + bx], ax
	
spawn_obs_done:
	pop si
	pop cx
	pop bx
	pop ax
	ret

; Spawn new coin at top of screen
spawn_coin:
	push ax
	push bx
	push cx
	push si
	
	; Find inactive coin slot
	mov cx, MAX_COINS
	mov si, 0
	
find_coin_slot:
	cmp byte [coin_active + si], 0
	je found_coin_slot
	inc si
	loop find_coin_slot
	jmp spawn_coin_done
	
found_coin_slot:
	; Activate coin
	mov byte [coin_active + si], 1
	
	; Set row to top
	mov bx, si
	shl bx, 1
	mov word [coin_row + bx], 3
	
	; Set random column (lane)
	call get_random_lane
	mov [coin_col + bx], ax
	
spawn_coin_done:
	pop si
	pop cx
	pop bx
	pop ax
	ret

; Spawn new fuel at top of screen
spawn_fuel:
	push ax
	push bx
	push cx
	push si
	
	; Find inactive fuel slot
	mov cx, MAX_FUEL
	mov si, 0
	
find_fuel_slot:
	cmp byte [fuel_active + si], 0
	je found_fuel_slot
	inc si
	loop find_fuel_slot
	jmp spawn_fuel_done
	
found_fuel_slot:
	; Activate fuel
	mov byte [fuel_active + si], 1
	
	; Set row to top
	mov bx, si
	shl bx, 1
	mov word [fuel_row + bx], 3
	
	; Set random column (lane)
	call get_random_lane
	mov [fuel_col + bx], ax
	
spawn_fuel_done:
	pop si
	pop cx
	pop bx
	pop ax
	ret

; Update all obstacle positions (move down)
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
	
	; Move down
	mov bx, si
	shl bx, 1
	inc word [obstacle_row + bx]
	
	; Check if off screen
	cmp word [obstacle_row + bx], 24
	jl skip_update_obs
	
	; Deactivate if off screen
	mov byte [obstacle_active + si], 0
	
skip_update_obs:
	inc si
	loop update_obs_loop
	
	pop si
	pop cx
	pop bx
	pop ax
	ret

; Update all coin positions (move down)
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
	
	; Move down
	mov bx, si
	shl bx, 1
	inc word [coin_row + bx]
	
	; Check if off screen
	cmp word [coin_row + bx], 24
	jl skip_update_coin
	
	; Deactivate if off screen
	mov byte [coin_active + si], 0
	
skip_update_coin:
	inc si
	loop update_coin_loop
	
	pop si
	pop cx
	pop bx
	pop ax
	ret

; Update all fuel positions (move down)
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
	
	; Move down
	mov bx, si
	shl bx, 1
	inc word [fuel_row + bx]
	
	; Check if off screen
	cmp word [fuel_row + bx], 24
	jl skip_update_fuel
	
	; Deactivate if off screen
	mov byte [fuel_active + si], 0
	
skip_update_fuel:
	inc si
	loop update_fuel_loop
	
	pop si
	pop cx
	pop bx
	pop ax
	ret

; Print a number at specified position
; Input: AX = number, BH = row, BL = col
print_number:
	push ax
	push bx
	push cx
	push dx
	push di
	push es
	
	; Save the number before we lose it
	push ax
	
	mov ax, 0xB800
	mov es, ax
	
	; Calculate screen position
	mov al, bh
	mov ah, 0
	mov cx, SCREEN_WIDTH
	mul cx
	mov di, ax
	mov al, bl
	mov ah, 0
	add di, ax
	shl di, 1
	
	; Restore the number
	pop ax
	
	; Convert number to string and print
	mov cx, 0
	mov bx, 10
	
convert_loop:
	mov dx, 0
	div bx
	add dl, '0'
	push dx
	inc cx
	cmp ax, 0
	jne convert_loop
	
print_digits:
	pop dx
	mov byte [es:di], dl
	mov byte [es:di+1], 0x0F	; white on black
	add di, 2
	loop print_digits
	
	pop es
	pop di
	pop dx
	pop cx
	pop bx
	pop ax
	ret

; Print string at position
; Input: SI = string address, BH = row, BL = col
print_string:
	push ax
	push bx
	push cx
	push di
	push es
	push si
	
	mov ax, 0xB800
	mov es, ax
	
	; Calculate position
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

; Display HUD (score and fuel) - simplified to avoid memory issues
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
	
	; Display "Score: " at position (0, 1)
	mov di, 2		; row 0, col 1
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
	; Print score number
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
	
	; Display "Fuel: " at position (0, 70)
	mov di, 140		; row 0, col 70
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
	; Print fuel number
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

; Delay function (adjusted for good animation speed)
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

; Flush keyboard buffer
flush_keyboard:
	push ax
flush_loop:
	mov ah, 0x01
	int 0x16
	jz flush_done
	; Read and discard key
	mov ah, 0x00
	int 0x16
	jmp flush_loop
flush_done:
	pop ax
	ret

; Check if key pressed (non-blocking)
; Output: CF=0 if key pressed (AH=scan code), CF=1 if no key
check_key:
	mov ah, 0x01
	int 0x16
	jnz key_available
	
	; No key pressed
	stc			; set carry flag
	ret
	
key_available:
	; Key is available, read it to clear buffer
	mov ah, 0x00
	int 0x16
	; AH = scan code, AL = ASCII
	clc			; clear carry flag
	ret

; Move player car up
move_player_up:
	push ax
	
	; Check if not at top limit (row 5 is minimum)
	cmp word [player_row], 5
	jle move_up_done
	
	; Move up by 1 row
	dec word [player_row]
	
move_up_done:
	pop ax
	ret

; Move player car down
move_player_down:
	push ax
	
	; Check if not at bottom limit (row 21 is maximum to keep car visible)
	cmp word [player_row], 21
	jge move_down_done
	
	; Move down by 1 row
	inc word [player_row]
	
move_down_done:
	pop ax
	ret

; Move

; ==================== MAIN GAME LOOP ====================
start:
	; Clear screen
	call clear_screen
	
	; Flush keyboard buffer
	call flush_keyboard
	
	; Hide cursor
	mov ah, 0x01
	mov ch, 0x20
	mov cl, 0x00
	int 0x10
	
game_loop:
	; Draw static background
	call draw_grass
	call draw_road
	call draw_lanes
	
	; Draw game objects
	call draw_all_obstacles
	call draw_all_coins
	call draw_all_fuel
	call draw_player_car
	
	; Display HUD
	call display_hud
	
	; Update lane scrolling
	inc word [lane_offset]
	cmp word [lane_offset], 4
	jl no_reset_offset
	mov word [lane_offset], 0
no_reset_offset:
	
	; Update positions
	call update_obstacles
	call update_coins
	call update_fuel
	
	; Spawn new objects based on frame count
	mov ax, [frame_count]
	mov dx, 0
	mov bx, SPAWN_TIME
	div bx
	
	cmp dx, 0
	jne skip_spawn_obstacle
	call spawn_obstacle
skip_spawn_obstacle:
	
	; Spawn coins less frequently
	cmp dx, 10
	jne skip_spawn_coin
	call spawn_coin
skip_spawn_coin:
	
	; Spawn fuel even less frequently
	cmp dx, 20
	jne skip_spawn_fuel
	call spawn_fuel
skip_spawn_fuel:
	
	; Increment frame counter
	inc word [frame_count]
	
	; Decrease fuel gradually
	mov ax, [frame_count]
	and ax, 0x001F		; every 32 frames
	cmp ax, 0
	jne skip_fuel_decrease
	cmp word [fuel_level], 0
	je game_over
	dec word [fuel_level]
skip_fuel_decrease:
	
	; Increase score
	inc word [score]
	
	; Direct ESC check for immediate exit (inline for speed)
	mov ah, 0x01
	int 0x16
	jz check_other_keys
	
	; Key available, read it
	mov ah, 0x00
	int 0x16
	
	; Immediate ESC exit
	cmp ah, 0x01
	je exit_game
	
	; Check for Up arrow (scan code 0x48)
	cmp ah, 0x48
	je key_up
	
	; Check for Down arrow (scan code 0x50)
	cmp ah, 0x50
	je key_down
	
	jmp no_key
	
check_other_keys:
	; No key pressed
	jmp no_key
	
key_up:
	call move_player_up
	jmp no_key
	
key_down:
	call move_player_down
	jmp no_key
	
no_key:
	; Delay for animation (reduced for responsiveness)
	call delay
	
	; Check game over condition
	cmp word [fuel_level], 0
	jg game_loop
	
game_over:
	; Display game over message
	mov si, gameover_msg
	mov bh, 12
	mov bl, 25
	call print_string
	
	; Wait for ESC
wait_exit:
	mov ah, 0x00
	int 0x16
	cmp ah, 0x01
	jne wait_exit
	
exit_game:
	; Show cursor
	mov ah, 0x01
	mov ch, 0x06
	mov cl, 0x07
	int 0x10
	
	; Clear screen
	call clear_screen
	
	; Exit to DOS
	mov ax, 0x4C00
	int 21h