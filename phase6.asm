[org 0x0100]
jmp start

; ==================== DATA SECTION ====================
; Screen dimensions
SCREEN_WIDTH	equ 80
SCREEN_HEIGHT	equ 25

; Road layout
GRASS_WIDTH	equ 15
ROAD_START	equ 15
ROAD_WIDTH	equ 50
ROAD_END	equ 65

; Lane positions
LANE_LEFT	equ 27
LANE_CENTER	equ 40
LANE_RIGHT	equ 53

; Lane numbers
LANE_NUM_LEFT	equ 0
LANE_NUM_CENTER	equ 1
LANE_NUM_RIGHT	equ 2

; Lane dividers
LANE_DIV1	equ 33
LANE_DIV2	equ 47

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
FUEL_DECREASE_RATE	equ 8	
MIN_ITEM_SPACING	equ 8

; Delay timing
DELAY_HIGH	equ 0x0001
DELAY_LOW	equ 0x8000

; Car dimensions
CAR_HEIGHT	equ 4

; Player limits
PLAYER_MIN_ROW	equ 5
PLAYER_MAX_ROW	equ 21
PLAYER_START_ROW	equ 20

; Car positions
player_row:	dw 20
player_lane:	db 1

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
player_name:		times 30 db 0
player_name_len:	db 0
player_rollno:		times 15 db 0
player_rollno_len:	db 0

; Game state
frame_count:		dw 0
score:			dw 0
fuel_level:		dw 100
lane_offset:		dw 0
last_spawn_row:		dw 100
game_started:		db 0
game_paused:		db 0		; 0 = running, 1 = paused, 2 = quit
show_quit_confirm:	db 0
confirm_drawn:		db 0
intro_shown:		db 0
name_entered:		db 0
rollno_entered:		db 0
instructions_shown:	db 0
in_game:		db 0
isr_hooked:		db 0
collision_occurred:	db 0
coins_collected:	dw 0
lane_move_timer:	db 0
lane_move_delay:	equ 5

; Keyboard state
key_pressed:		db 0
key_released_flag:	db 1

; Interrupt storage
oldkb:			dd 0
oldtimer:		dd 0    ; Storage for old timer interrupt

; Messages
title_msg:		db 'Last And Furious', 0
developer1_msg:		db 'Developed by:', 0
developer2_msg:		db 'Muhammad Saad - Roll No: 24L-0794', 0
developer3_msg:		db 'Usman Tahir - Roll No: 24L-0567', 0
press_key_msg:		db 'Press any key to continue...', 0
input_title:		db 'PLAYER INFORMATION', 0
name_prompt:		db 'Enter your name: ', 0
roll_prompt:		db 'Enter your roll number: ', 0
input_done_msg:		db 'Press ENTER to continue...', 0
instructions_title:	db 'INSTRUCTIONS', 0
inst_line1:		db 'Arrow Keys: Move car left/right/up/down', 0
inst_line2:		db 'Objective: Avoid blue cars and collect items', 0
inst_line3:		db 'Coins ($): Collect to increase score', 0
inst_line4:		db 'Fuel (F): Collect to refill fuel tank', 0
inst_line5:		db 'ESC Key: Pause game and show quit menu', 0
inst_line6:		db 'Fuel decreases over time - collect fuel!', 0
inst_line7:		db 'Game ends when fuel reaches zero', 0
press_start_msg:	db 'Press any key to start the game...', 0
score_msg:		db 'Score: ', 0
fuel_msg:		db 'Fuel: ', 0
gameover_msg:		db 'GAME OVER! Press ESC to exit', 0
quit_confirm_msg:	db 'Do you want to quit? (Y/N)', 0
paused_msg:		db 'PAUSED', 0

; ==================== MUSIC DATA SECTION ====================
; Note Frequencies (1193180 / Freq)
NOTE_A2 equ 10927
NOTE_B2 equ 9735
NOTE_C3 equ 9187
NOTE_D3 equ 8185
NOTE_E3 equ 7292
NOTE_F3 equ 6882
NOTE_G3 equ 6131
NOTE_A3 equ 5463
NOTE_B3 equ 4867
NOTE_C4 equ 4593
NOTE_D4 equ 4092
NOTE_E4 equ 3646
NOTE_F4 equ 3441
NOTE_G4 equ 3065
NOTE_A4 equ 2731

; Music State
music_enabled:      db 0    ; 1 = Play, 0 = Stop
current_note_idx:   dw 0    ; Pointer to current note
note_delay:         db 0    ; Ticks remaining for current note

; The Song (Format: Frequency, Duration in ticks)
; A fast paced "Racing" bassline loop
music_data:
    dw NOTE_A2, 2
    dw NOTE_A3, 2
    dw NOTE_A2, 2
    dw NOTE_E3, 2
    dw NOTE_A2, 2
    dw NOTE_A3, 2
    dw NOTE_G3, 2
    dw NOTE_E3, 2
    
    dw NOTE_A2, 2
    dw NOTE_A3, 2
    dw NOTE_A2, 2
    dw NOTE_C3, 2
    dw NOTE_D3, 2
    dw NOTE_E3, 2
    dw NOTE_C3, 4
    dw NOTE_C3, 2
    dw NOTE_C4, 2
    dw NOTE_C3, 2
    dw NOTE_G3, 2
    dw NOTE_C3, 2
    dw NOTE_C4, 2
    dw NOTE_E3, 2
    dw NOTE_G3, 2
    ;dw NOTE_G2, 2
    dw NOTE_G3, 2
    dw NOTE_B2, 2
    dw NOTE_D3, 2
    ;dw NOTE_E2, 2
    dw NOTE_E3, 2
    dw NOTE_G3, 4 
    dw 0, 0 

; ==================== TIMER ISR (BACKGROUND MUSIC) ====================
timer_isr:
    push ax
    push bx
    push ds
    push si

    ; Set DS to CS because we don't know where DS is pointing when interrupt fires
    push cs
    pop ds

    ; Check if music should play
    cmp byte [game_started], 1
    jne stop_sound_logic      ; If game not started, ensure silent
    cmp byte [game_paused], 0
    jne stop_sound_logic      ; If paused, silence
    
    ; Music logic
    cmp byte [note_delay], 0
    ja dec_delay              ; If delay > 0, just decrement
    
    ; Load next note
    mov si, [current_note_idx]
    mov bx, music_data
    add bx, si
    
    mov ax, [bx]        ; Get Frequency
    mov cx, [bx+2]      ; Get Duration
    
    ; Check for end of song (0,0)
    cmp ax, 0
    jne play_note
    cmp cx, 0
    jne play_note
    
    ; Reset to beginning
    mov word [current_note_idx], 0
    mov byte [note_delay], 0
    jmp timer_done
    
play_note:
    ; Update index for next time (4 bytes per entry)
    add word [current_note_idx], 4
    
    ; Set delay
    mov byte [note_delay], cl
    
    ; Play the sound (AX = Frequency)
    push ax
    
    ; Initialize PIT Channel 2
    mov al, 0xB6
    out 0x43, al
    
    pop ax          ; Restore frequency
    out 0x42, al    ; Lower byte
    mov al, ah
    out 0x42, al    ; Upper byte
    
    ; Turn Speaker ON
    in al, 0x61
    or al, 3
    out 0x61, al
    
    jmp timer_done

dec_delay:
    dec byte [note_delay]
    jmp timer_done

stop_sound_logic:
    ; Turn Speaker OFF
    in al, 0x61
    and al, 0xFC
    out 0x61, al

timer_done:
    ; Send EOI is NOT needed for 0x1C (it is software interrupt triggered by 0x08)
    ; But we MUST chain to the original handler to keep system time
    pop si
    pop ds
    pop bx
    pop ax
    jmp far [cs:oldtimer]

; ==================== KEYBOARD ISR ====================
kbisr:
	push ax
	push bx
	push ds
	
	push cs
	pop ds
	
	in al, 0x60
	
	cmp byte [in_game], 1
	je handle_game_isr
	jmp chain_old
	
handle_game_isr:
	cmp byte [game_started], 0
	je start_game_check
	
	cmp byte [show_quit_confirm], 1
	je handle_quit_confirm
	
	jmp handle_game_keys
	
start_game_check:
	test al, 0x80
	jz start_the_game
	jmp chain_old
	
start_the_game:
	mov byte [game_started], 1
    mov word [current_note_idx], 0 ; Reset music
	jmp chain_old

handle_quit_confirm:
	cmp al, 0x15
	je quit_yes
	cmp al, 0x31
	je quit_no
	cmp al, 0x01
	je quit_no
	jmp chain_old
	
quit_yes:
	mov byte [show_quit_confirm], 0
	mov byte [game_started], 0
	mov byte [game_paused], 2
	mov byte [confirm_drawn], 0
	jmp chain_old
	
quit_no:
	mov byte [show_quit_confirm], 0
	mov byte [game_paused], 0
	mov byte [confirm_drawn], 0
	jmp chain_old

handle_game_keys:
	test al, 0x80
	jnz key_release
	
	cmp byte [key_released_flag], 0
	jne new_key_press
	jmp chain_old
	
new_key_press:
	mov byte [key_released_flag], 0
	cmp al, 0x01
	jne check_left_key
	jmp handle_esc
	
check_left_key:
	cmp al, 0x4B
	jne check_right_key
	jmp handle_left
	
check_right_key:
	cmp al, 0x4D
	jne check_up_key
	jmp handle_right
	
check_up_key:
	cmp al, 0x48
	jne check_down_key
	jmp handle_up
	
check_down_key:
	cmp al, 0x50
	jne no_key_match
	jmp handle_down
	
no_key_match:
	jmp chain_old

key_release:
	and al, 0x7F
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
	cmp byte [game_paused], 0
	jne resume_game
	
	mov byte [game_paused], 1
	mov byte [show_quit_confirm], 1
	mov byte [confirm_drawn], 0
	jmp chain_old
	
resume_game:
	mov byte [game_paused], 0
	mov byte [show_quit_confirm], 0
	mov byte [confirm_drawn], 0
	jmp chain_old

handle_left:
	cmp byte [lane_move_timer], 0
	jne cannot_move_left
	cmp byte [player_lane], LANE_NUM_LEFT
	jg can_move_left
	jmp chain_old
can_move_left:
	dec byte [player_lane]
	mov byte [lane_move_timer], lane_move_delay
	jmp chain_old
cannot_move_left:
	jmp chain_old

handle_right:
	cmp byte [lane_move_timer], 0
	jne cannot_move_right
	cmp byte [player_lane], LANE_NUM_RIGHT
	jl can_move_right
	jmp chain_old
can_move_right:
	inc byte [player_lane]
	mov byte [lane_move_timer], lane_move_delay
	jmp chain_old
cannot_move_right:
	jmp chain_old

handle_up:
	mov ax, [player_row]
	cmp ax, PLAYER_MIN_ROW
	jg do_move_up
	jmp chain_old
do_move_up:
	dec word [player_row]
	jmp chain_old

handle_down:
	mov ax, [player_row]
	cmp ax, PLAYER_MAX_ROW
	jl do_move_down
	jmp chain_old
do_move_down:
	inc word [player_row]
	jmp chain_old

chain_old:
	mov al, 0x20
	out 0x20, al
	pop ds
	pop bx
	pop ax
	jmp far [cs:oldkb]

; ==================== INTERRUPT MANAGEMENT ====================

; Hook Interrupts (Keyboard and Timer)
hook_interrupts:
    push ax
    push bx
    push es
    
    xor ax, ax
    mov es, ax
    
    ; Hook Keyboard (0x09)
    mov ax, [es:9*4]
    mov [oldkb], ax
    mov ax, [es:9*4+2]
    mov [oldkb+2], ax
    
    cli
    mov word [es:9*4], kbisr
    mov [es:9*4+2], cs
    sti
    
    ; Hook Timer (0x1C - System Timer Tick User Routine)
    mov ax, [es:0x1C*4]
    mov [oldtimer], ax
    mov ax, [es:0x1C*4+2]
    mov [oldtimer+2], ax
    
    cli
    mov word [es:0x1C*4], timer_isr
    mov [es:0x1C*4+2], cs
    sti
    
    pop es
    pop bx
    pop ax
    ret

; Unhook Interrupts
unhook_interrupts:
    push ax
    push es
    
    xor ax, ax
    mov es, ax
    
    cli
    ; Restore Keyboard
    mov ax, [oldkb]
    mov [es:9*4], ax
    mov ax, [oldkb+2]
    mov [es:9*4+2], ax
    
    ; Restore Timer
    mov ax, [oldtimer]
    mov [es:0x1C*4], ax
    mov ax, [oldtimer+2]
    mov [es:0x1C*4+2], ax
    
    ; Ensure speaker is off
    in al, 0x61
    and al, 0xFC
    out 0x61, al
    
    sti
    
    pop es
    pop ax
    ret

; ==================== INITIALIZATION SUBROUTINES ====================

init_game:
	call clear_screen
	call flush_keyboard
	call hide_cursor
	
	cmp byte [isr_hooked], 1
	je skip_hook
	call hook_interrupts
	mov byte [isr_hooked], 1
	
skip_hook:
	ret

reset_game_state:
	push ax
	push bx
	push cx
	push si
	
	; Reset music
    mov word [current_note_idx], 0
    mov byte [note_delay], 0

	; Reset all obstacles
	mov cx, MAX_OBSTACLES
	mov si, 0
reset_obs_loop:
	mov byte [obstacle_active + si], 0
	mov bx, si
	shl bx, 1
	mov word [obstacle_row + bx], 0
	inc si
	loop reset_obs_loop
	
	; Reset all coins
	mov cx, MAX_COINS
	mov si, 0
reset_coin_loop:
	mov byte [coin_active + si], 0
	mov bx, si
	shl bx, 1
	mov word [coin_row + bx], 0
	inc si
	loop reset_coin_loop
	
	; Reset all fuel
	mov cx, MAX_FUEL
	mov si, 0
reset_fuel_loop:
	mov byte [fuel_active + si], 0
	mov bx, si
	shl bx, 1
	mov word [fuel_row + bx], 0
	inc si
	loop reset_fuel_loop
	
	; Reset game variables
	mov word [frame_count], 0
	mov word [score], 0
	mov word [fuel_level], 100
	mov word [lane_offset], 0
	mov word [last_spawn_row], 100
	mov byte [game_started], 0
	mov byte [game_paused], 0
	mov byte [show_quit_confirm], 0
	mov byte [confirm_drawn], 0
	mov byte [collision_occurred], 0
	mov word [coins_collected], 0
	mov byte [lane_move_timer], 0
	
	; Reset player position
	mov byte [player_lane], LANE_NUM_CENTER
	mov word [player_row], PLAYER_START_ROW
	
	; Reset screen flags (but keep name/roll)
	mov byte [intro_shown], 0
	mov byte [instructions_shown], 0
	mov byte [in_game], 0
	
	pop si
	pop cx
	pop bx
	pop ax
	ret

cleanup_game:
	call unhook_interrupts
	mov byte [isr_hooked], 0
	call show_cursor
	call clear_screen
	ret

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

draw_background:
	call draw_grass
	call draw_road
	call draw_lanes
	ret

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

draw_lanes:
	push bx
	mov bx, LANE_DIV1
	call draw_single_lane
	mov bx, LANE_DIV2
	call draw_single_lane
	pop bx
	ret

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

draw_player_car:
	push ax
	push bx
	push cx
	push di
	push es
	
	mov ax, 0xB800
	mov es, ax
	
	mov al, [player_lane]
	call get_lane_column
	mov bx, ax
	
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
	
	; Row 1
	sub di, SCREEN_WIDTH * 2
	mov byte [es:di-2], ' '
	mov byte [es:di-1], COLOR_ROAD
	mov byte [es:di], 0xDC
	mov byte [es:di+1], COLOR_RED_CAR
	mov byte [es:di+2], ' '
	mov byte [es:di+3], COLOR_ROAD
	
	; Row 2
	add di, SCREEN_WIDTH * 2
	mov byte [es:di-2], 0xDB
	mov byte [es:di-1], COLOR_RED_CAR
	mov byte [es:di], ' '
	mov byte [es:di+1], COLOR_BLACK
	mov byte [es:di+2], 0xDB
	mov byte [es:di+3], COLOR_RED_CAR
	
	; Row 3
	add di, SCREEN_WIDTH * 2
	mov byte [es:di-2], 0xDB
	mov byte [es:di-1], COLOR_RED_CAR
	mov byte [es:di], 0xDB
	mov byte [es:di+1], COLOR_RED_CAR
	mov byte [es:di+2], 0xDB
	mov byte [es:di+3], COLOR_RED_CAR
	
	; Row 4
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
	
	mov bx, si
	shl bx, 1
	mov ax, [obstacle_row + bx]
	mov dx, [obstacle_col + bx]
	
	push si
	push ax
	push dx
	
	mov cx, ax
	inc cx
	cmp cx, CAR_HEIGHT
	jle rows_ok
	mov cx, CAR_HEIGHT
rows_ok:
	mov si, 0
draw_partial_car:
	cmp si, cx
	jge done_partial_car
	push ax
	push bx
	push cx
	push si
	mov bx, dx
	mov cx, si
	call draw_obstacle_car_row
	pop si
	pop cx
	pop bx
	pop ax
	inc ax
	inc si
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

draw_all_objects:
	call draw_all_obstacles
	call draw_all_coins
	call draw_all_fuel
	call draw_player_car
	ret

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
	
	; Score
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
	
	; Coins
	mov di, 40
	mov byte [es:di], 'C'
	mov byte [es:di+1], 0x0E
	add di, 2
	mov byte [es:di], 'o'
	mov byte [es:di+1], 0x0E
	add di, 2
	mov byte [es:di], 'i'
	mov byte [es:di+1], 0x0E
	add di, 2
	mov byte [es:di], 'n'
	mov byte [es:di+1], 0x0E
	add di, 2
	mov byte [es:di], 's'
	mov byte [es:di+1], 0x0E
	add di, 2
	mov byte [es:di], ':'
	mov byte [es:di+1], 0x0E
	add di, 2
	mov ax, [coins_collected]
	mov bx, 10
	mov cx, 0
hud_coins_conv:
	mov dx, 0
	div bx
	push dx
	inc cx
	cmp ax, 0
	jne hud_coins_conv
hud_coins_print:
	pop dx
	add dl, '0'
	mov byte [es:di], dl
	mov byte [es:di+1], 0x0E
	add di, 2
	loop hud_coins_print
	
	pop si
	pop es
	pop di
	pop dx
	pop cx
	pop bx
	pop ax
	
	call draw_fuel_bar
	ret

; ==================== SCREEN DISPLAYS ====================

show_intro_screen:
	push ax
	push bx
	push si
	call clear_screen
	mov si, title_msg
	mov bh, 8
	mov bl, 28 
	call print_string_large
	mov si, developer1_msg
	mov bh, 12
	mov bl, 30
	call print_string
	mov si, developer2_msg
	mov bh, 14
	mov bl, 20
	call print_string
	mov si, developer3_msg
	mov bh, 15
	mov bl, 20
	call print_string
	mov si, press_key_msg
	mov bh, 20
	mov bl, 25
	call print_string
	pop si
	pop bx
	pop ax
	ret

show_input_screen:
	push ax
	push bx
	push si
	call clear_screen
	mov si, input_title
	mov bh, 6
	mov bl, 28
	call print_string_large
	mov si, name_prompt
	mov bh, 10
	mov bl, 20
	call print_string
	mov bh, 10
	mov bl, 37
	mov di, player_name
	mov cl, 29
	call get_text_input
	mov [player_name_len], al
	mov si, roll_prompt
	mov bh, 12
	mov bl, 20
	call print_string
	mov bh, 12
	mov bl, 45
	mov di, player_rollno
	mov cl, 14
	call get_text_input
	mov [player_rollno_len], al
	mov si, input_done_msg
	mov bh, 16
	mov bl, 25
	call print_string
wait_input_enter:
	mov ah, 0x00
	int 0x16
	cmp al, 0x0D
	jne wait_input_enter
	pop si
	pop bx
	pop ax
	ret

get_text_input:
	push bx
	push cx
	push dx
	push di
	push si
	mov byte [di], 0
	xor si, si
input_loop:
	mov ah, 0x00
	int 0x16
	cmp al, 0x0D
	je input_done
	cmp al, 0x08
	je input_backspace
	cmp al, 32
	jl input_loop
	cmp al, 126
	jg input_loop
	cmp si, cx
	jge input_loop
	push bp
	mov bp, di
	add bp, si
	mov [bp], al
	pop bp
	inc si
	push ax
	call print_char_at
	pop ax
	inc bl
	jmp input_loop
input_backspace:
	cmp si, 0
	je input_loop
	dec si
	dec bl
	push bp
	mov bp, di
	add bp, si
	mov byte [bp], 0
	pop bp
	push ax
	mov al, ' '
	call print_char_at
	pop ax
	jmp input_loop
input_done:
	push bp
	mov bp, di
	add bp, si
	mov byte [bp], 0
	pop bp
	mov ax, si
	pop si
	pop di
	pop dx
	pop cx
	pop bx
	ret

print_char_at:
	push ax
	push bx
	push cx
	push di
	push es
	mov cx, 0xB800
	mov es, cx
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
	mov byte [es:di], al
	mov byte [es:di+1], 0x0F
	pop es
	pop di
	pop cx
	pop bx
	pop ax
	ret

show_instruction_screen:
	push ax
	push bx
	push si
	call clear_screen
	mov si, instructions_title
	mov bh, 5
	mov bl, 32
	call print_string_large
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
	mov si, press_start_msg
	mov bh, 22
	mov bl, 23
	call print_string
	pop si
	pop bx
	pop ax
	ret

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
	mov byte [es:di+1], 0x0E
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
	mov bx, 10
	mov cx, 20
	call draw_box_line_top
	mov bx, 11
	mov cx, 20
	call draw_box_line_middle
	mov bx, 12
	mov cx, 20
	call draw_box_line_middle
	mov bx, 13
	mov cx, 20
	call draw_box_line_middle
	mov bx, 14
	mov cx, 20
	call draw_box_line_bottom
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
	mov byte [es:di], 0xDA
	mov byte [es:di+1], 0x1F
	add di, 2
	mov cx, 38
draw_top_loop:
	mov byte [es:di], 0xC4
	mov byte [es:di+1], 0x1F
	add di, 2
	loop draw_top_loop
	mov byte [es:di], 0xBF
	mov byte [es:di+1], 0x1F
	pop di
	pop cx
	pop ax
	ret

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
	mov byte [es:di], 0xB3
	mov byte [es:di+1], 0x1F
	add di, 2
	mov cx, 38
draw_middle_loop:
	mov byte [es:di], ' '
	mov byte [es:di+1], 0x1F
	add di, 2
	loop draw_middle_loop
	mov byte [es:di], 0xB3
	mov byte [es:di+1], 0x1F
	pop di
	pop cx
	pop ax
	ret

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
	mov byte [es:di], 0xC0
	mov byte [es:di+1], 0x1F
	add di, 2
	mov cx, 38
draw_bottom_loop:
	mov byte [es:di], 0xC4
	mov byte [es:di+1], 0x1F
	add di, 2
	loop draw_bottom_loop
	mov byte [es:di], 0xD9
	mov byte [es:di+1], 0x1F
	pop di
	pop cx
	pop ax
	ret

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

get_random_lane_except:
	push bx
	push cx
	push dx
	mov cx, dx
retry_lane_except:
	call get_random
	mov dx, 0
	mov bx, 3
	div bx
	cmp dx, 0
	je try_lane1_except
	cmp dx, 1
	je try_lane2_except
	jmp try_lane3_except
try_lane1_except:
	mov ax, LANE_LEFT
	cmp ax, cx
	je retry_lane_except
	jmp lane_except_done
try_lane2_except:
	mov ax, LANE_CENTER
	cmp ax, cx
	je retry_lane_except
	jmp lane_except_done
try_lane3_except:
	mov ax, LANE_RIGHT
	cmp ax, cx
	je retry_lane_except
lane_except_done:
	pop dx
	pop cx
	pop bx
	ret

; ==================== SPAWN SUBROUTINES ====================

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

spawn_obstacle:
	push ax
	push bx
	push cx
	push si
	mov cx, MAX_OBSTACLES
	mov si, 0
	mov al, 0
count_active_obs:
	cmp byte [obstacle_active + si], 1
	jne skip_count_obs
	inc al
skip_count_obs:
	inc si
	dec cx
	cmp cx, 0
	jne count_active_obs
	cmp al, 2
	jge spawn_obs_done
	cmp al, 1
	jne find_obs_slot
	call check_spawn_spacing
	jc spawn_obs_done
find_obs_slot:
	mov cx, MAX_OBSTACLES
	mov si, 0
find_obs_slot_loop:
	cmp byte [obstacle_active + si], 0
	je found_obs_slot
	inc si
	loop find_obs_slot_loop
	jmp spawn_obs_done
found_obs_slot:
	cmp al, 1
	jne spawn_any_lane
	push si
	mov cx, MAX_OBSTACLES
	mov si, 0
find_occupied_lane:
	cmp byte [obstacle_active + si], 1
	jne check_next_obs
	mov bx, si
	shl bx, 1
	mov dx, [obstacle_col + bx]
	jmp spawn_different_lane
check_next_obs:
	inc si
	loop find_occupied_lane
spawn_different_lane:
	pop si
	call get_random_lane_except
	jmp set_obstacle_pos
spawn_any_lane:
	call get_random_lane
set_obstacle_pos:
	mov byte [obstacle_active + si], 1
	mov byte [obstacle_fade_state + si], 0
	mov bx, si
	shl bx, 1
	mov word [obstacle_row + bx], 0
	mov [obstacle_col + bx], ax
	mov word [last_spawn_row], 0
spawn_obs_done:
	pop si
	pop cx
	pop bx
	pop ax
	ret

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
	mov word [coin_row + bx], 1
	call get_random_lane
	mov [coin_col + bx], ax
	mov word [last_spawn_row], 1
spawn_coin_done:
	pop si
	pop cx
	pop bx
	pop ax
	ret

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
	mov word [fuel_row + bx], 1
	call get_random_lane
	mov [fuel_col + bx], ax
	mov word [last_spawn_row], 1
spawn_fuel_done:
	pop si
	pop cx
	pop bx
	pop ax
	ret

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

; ==================== COLLISION AND COLLECTION ====================

check_current_collision:
	push bx
	push cx
	push dx
	push si
	mov al, [player_lane]
	call get_lane_column
	mov dx, ax
	mov bx, [player_row]
	mov cx, MAX_OBSTACLES
	mov si, 0
check_curr_collision_loop:
	cmp byte [obstacle_active + si], 0
	je skip_curr_collision
	push bx
	mov bx, si
	shl bx, 1
	mov ax, [obstacle_col + bx]
	cmp ax, dx
	jne skip_curr_collision_pop
	mov ax, [obstacle_row + bx]
	pop bx
	push bx
	push ax
	add ax, 3
	push bx
	sub bx, 2
	cmp ax, bx
	pop bx
	pop ax
	jl skip_curr_collision_pop
	push bx
	inc bx
	cmp ax, bx
	pop bx
	jg skip_curr_collision_pop
	pop bx
	pop si
	pop dx
	pop cx
	pop bx
	mov al, 1
	ret
skip_curr_collision_pop:
	pop bx
skip_curr_collision:
	inc si
	dec cx
	cmp cx, 0
	jne check_curr_collision_loop
	pop si
	pop dx
	pop cx
	pop bx
	mov al, 0
	ret

check_coin_collection:
	push ax
	push bx
	push cx
	push dx
	push si
	mov al, [player_lane]
	call get_lane_column
	mov dx, ax
	mov bx, [player_row]
	mov cx, MAX_COINS
	mov si, 0
check_coin_loop:
	cmp byte [coin_active + si], 0
	je skip_coin_collect
	push bx
	mov bx, si
	shl bx, 1
	mov ax, [coin_col + bx]
	cmp ax, dx
	jne skip_coin_collect_pop
	mov ax, [coin_row + bx]
	pop bx
	push bx
	sub ax, bx
	cmp ax, -2
	jl skip_coin_collect_pop
	cmp ax, 2
	jg skip_coin_collect_pop
	pop bx
	mov byte [coin_active + si], 0
	inc word [coins_collected]
	add word [score], 10
	jmp coin_collect_next
skip_coin_collect_pop:
	pop bx
skip_coin_collect:
coin_collect_next:
	inc si
	dec cx
	cmp cx, 0
	jne check_coin_loop
	pop si
	pop dx
	pop cx
	pop bx
	pop ax
	ret

check_fuel_collection:
	push ax
	push bx
	push cx
	push dx
	push si
	mov al, [player_lane]
	call get_lane_column
	mov dx, ax
	mov bx, [player_row]
	mov cx, MAX_FUEL
	mov si, 0
check_fuel_loop:
	cmp byte [fuel_active + si], 0
	je skip_fuel_collect
	push bx
	mov bx, si
	shl bx, 1
	mov ax, [fuel_col + bx]
	cmp ax, dx
	jne skip_fuel_collect_pop
	mov ax, [fuel_row + bx]
	pop bx
	push bx
	sub ax, bx
	cmp ax, -2
	jl skip_fuel_collect_pop
	cmp ax, 2
	jg skip_fuel_collect_pop
	pop bx
	mov byte [fuel_active + si], 0
	add word [fuel_level], 30
	cmp word [fuel_level], 100
	jle fuel_collect_next
	mov word [fuel_level], 100
	jmp fuel_collect_next
skip_fuel_collect_pop:
	pop bx
skip_fuel_collect:
fuel_collect_next:
	inc si
	dec cx
	cmp cx, 0
	jne check_fuel_loop
	pop si
	pop dx
	pop cx
	pop bx
	pop ax
	ret

draw_collision_spark:
	push ax
	push bx
	push cx
	push dx
	push di
	push es
	push si
	mov ax, 0xB800
	mov es, ax
	mov al, [player_lane]
	call get_lane_column
	mov bx, ax
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
	mov byte [es:di-4], 0xB0
	mov byte [es:di-3], 0xEE
	mov byte [es:di+6], 0xB0
	mov byte [es:di+7], 0xEE
	sub di, SCREEN_WIDTH * 2
	mov byte [es:di-2], 0xFE
	mov byte [es:di-1], 0xCC
	mov byte [es:di+4], 0xFE
	mov byte [es:di+5], 0xCC
	add di, SCREEN_WIDTH * 4
	mov byte [es:di-2], 0xB0
	mov byte [es:di-1], 0xEE
	mov byte [es:di+4], 0xB0
	mov byte [es:di+5], 0xEE
	mov al, [player_lane]
	call get_lane_column
	mov dx, ax
	mov bx, [player_row]
	mov cx, MAX_OBSTACLES
	mov si, 0
find_colliding_obs:
	cmp byte [obstacle_active + si], 0
	je skip_spark_obs
	push bx
	mov bx, si
	shl bx, 1
	mov ax, [obstacle_col + bx]
	cmp ax, dx
	jne skip_spark_obs_pop
	mov ax, [obstacle_row + bx]
	mov bx, [obstacle_col + bx]
	pop bx
	push bx
	push dx
	mov dx, SCREEN_WIDTH
	mul dx
	pop dx
	shl ax, 1
	mov di, ax
	mov ax, bx
	shl ax, 1
	add di, ax
	mov byte [es:di-4], 0xB0
	mov byte [es:di-3], 0xEE
	mov byte [es:di+6], 0xB0
	mov byte [es:di+7], 0xEE
	add di, SCREEN_WIDTH * 2
	mov byte [es:di-2], 0xFE
	mov byte [es:di-1], 0xCC
	mov byte [es:di+4], 0xFE
	mov byte [es:di+5], 0xCC
	add di, SCREEN_WIDTH * 4
	mov byte [es:di-2], 0xB0
	mov byte [es:di-1], 0xEE
	mov byte [es:di+4], 0xB0
	mov byte [es:di+5], 0xEE
	pop bx
	jmp done_spark_obs
skip_spark_obs_pop:
	pop bx
skip_spark_obs:
	inc si
	dec cx
	cmp cx, 0
	jne find_colliding_obs
done_spark_obs:
	pop si
	pop es
	pop di
	pop dx
	pop cx
	pop bx
	pop ax
	ret

draw_fuel_bar:
	push ax
	push bx
	push cx
	push dx
	push di
	push es
	mov ax, 0xB800
	mov es, ax
	mov di, (3 * SCREEN_WIDTH + 72) * 2
	mov byte [es:di], 'F'
	mov byte [es:di+1], 0x0F
	add di, SCREEN_WIDTH * 2
	mov byte [es:di], 'U'
	mov byte [es:di+1], 0x0F
	add di, SCREEN_WIDTH * 2
	mov byte [es:di], 'E'
	mov byte [es:di+1], 0x0F
	add di, SCREEN_WIDTH * 2
	mov byte [es:di], 'L'
	mov byte [es:di+1], 0x0F
	mov ax, [fuel_level]
	mov bx, 16
	mul bx
	mov bx, 100
	div bx
	mov cx, ax
	mov bh, 0x44
	cmp word [fuel_level], 30
	jl fuel_color_set_vert
	mov bh, 0xEE
	cmp word [fuel_level], 60
	jl fuel_color_set_vert
	mov bh, 0x20
fuel_color_set_vert:
	mov dx, 1
	mov di, (9 * SCREEN_WIDTH + 72) * 2
fuel_bar_draw_vert:
	cmp dx, 17
	jg fuel_bar_done_vert
	mov ax, 17
	sub ax, dx
	cmp ax, cx
	jg draw_empty_block_vert
	mov byte [es:di], 0xDB
	mov byte [es:di+1], bh
	jmp next_fuel_block_vert
draw_empty_block_vert:
	mov byte [es:di], 0xB0
	mov byte [es:di+1], 0x07
next_fuel_block_vert:
	add di, SCREEN_WIDTH * 2
	inc dx
	jmp fuel_bar_draw_vert
fuel_bar_done_vert:
	pop es
	pop di
	pop dx
	pop cx
	pop bx
	pop ax
	ret

; ==================== UPDATE SUBROUTINES ====================

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

update_all_positions:
	call update_obstacles
	call update_coins
	call update_fuel
	call update_last_spawn_row
	ret

update_lane_scrolling:
	push ax
	inc word [lane_offset]
	cmp word [lane_offset], 4
	jl lane_scroll_done
	mov word [lane_offset], 0
lane_scroll_done:
	pop ax
	ret

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

update_score:
	inc word [score]
	ret

update_frame_counter:
	inc word [frame_count]
	ret

update_game_state:
	call update_lane_scrolling
	call update_fuel_level
	call update_score
	call update_frame_counter
	call update_lane_timer
	call check_coin_collection
	call check_fuel_collection
	call check_continuous_collision
	ret

check_continuous_collision:
	push ax
	cmp byte [collision_occurred], 1
	je collision_skip
	call check_current_collision
	cmp al, 1
	jne collision_skip
	mov byte [collision_occurred], 1
collision_skip:
	pop ax
	ret

update_lane_timer:
	push ax
	cmp byte [lane_move_timer], 0
	je timer_zero
	dec byte [lane_move_timer]
timer_zero:
	pop ax
	ret

; ==================== GAME CHECKS ====================

check_game_over:
	push ax
	cmp byte [collision_occurred], 1
	je game_over_collision
	cmp word [fuel_level], 0
	jg not_game_over
game_over_fuel:
	pop ax
	stc
	ret
game_over_collision:
	call draw_collision_spark
	push cx
	push dx
	mov cx, 5
collision_pause:
	call delay
	loop collision_pause
	pop dx
	pop cx
	pop ax
	stc
	ret
not_game_over:
	pop ax
	clc
	ret

show_game_over:
	push ax
	push bx
	push si
	call clear_screen
	cmp byte [collision_occurred], 1
	jne out_of_fuel_msg
	jmp show_crash_msg
out_of_fuel_msg:
	mov si, gameover_msg
	mov bh, 6
	mov bl, 26
	call print_string_large
	push es
	mov ax, 0xB800
	mov es, ax
	mov di, (8 * SCREEN_WIDTH + 31) * 2
	mov byte [es:di], 'O'
	mov byte [es:di+1], 0x0C
	add di, 2
	mov byte [es:di], 'U'
	mov byte [es:di+1], 0x0C
	add di, 2
	mov byte [es:di], 'T'
	mov byte [es:di+1], 0x0C
	add di, 2
	mov byte [es:di], ' '
	mov byte [es:di+1], 0x0C
	add di, 2
	mov byte [es:di], 'O'
	mov byte [es:di+1], 0x0C
	add di, 2
	mov byte [es:di], 'F'
	mov byte [es:di+1], 0x0C
	add di, 2
	mov byte [es:di], ' '
	mov byte [es:di+1], 0x0C
	add di, 2
	mov byte [es:di], 'F'
	mov byte [es:di+1], 0x0C
	add di, 2
	mov byte [es:di], 'U'
	mov byte [es:di+1], 0x0C
	add di, 2
	mov byte [es:di], 'E'
	mov byte [es:di+1], 0x0C
	add di, 2
	mov byte [es:di], 'L'
	mov byte [es:di+1], 0x0C
	add di, 2
	mov byte [es:di], '!'
	mov byte [es:di+1], 0x0C
	pop es
	jmp show_player_info	
show_crash_msg:
	mov si, gameover_msg
	mov bh, 6
	mov bl, 24
	call print_string_large
	push es
	mov ax, 0xB800
	mov es, ax
	mov di, (8 * SCREEN_WIDTH + 33) * 2
	mov byte [es:di], 'C'
	mov byte [es:di+1], 0x0C
	add di, 2
	mov byte [es:di], 'R'
	mov byte [es:di+1], 0x0C
	add di, 2
	mov byte [es:di], 'A'
	mov byte [es:di+1], 0x0C
	add di, 2
	mov byte [es:di], 'S'
	mov byte [es:di+1], 0x0C
	add di, 2
	mov byte [es:di], 'H'
	mov byte [es:di+1], 0x0C
	add di, 2
	mov byte [es:di], '!'
	mov byte [es:di+1], 0x0C
	pop es
show_player_info:
	push es
	mov ax, 0xB800
	mov es, ax
	mov di, (11 * SCREEN_WIDTH + 28) * 2
	mov byte [es:di], 'P'
	mov byte [es:di+1], 0x0B
	add di, 2
	mov byte [es:di], 'l'
	mov byte [es:di+1], 0x0B
	add di, 2
	mov byte [es:di], 'a'
	mov byte [es:di+1], 0x0B
	add di, 2
	mov byte [es:di], 'y'
	mov byte [es:di+1], 0x0B
	add di, 2
	mov byte [es:di], 'e'
	mov byte [es:di+1], 0x0B
	add di, 2
	mov byte [es:di], 'r'
	mov byte [es:di+1], 0x0B
	add di, 2
	mov byte [es:di], ':'
	mov byte [es:di+1], 0x0B
	add di, 2
	mov byte [es:di], ' '
	mov byte [es:di+1], 0x0B
	add di, 2
	mov si, player_name
display_name_loop:
	lodsb
	cmp al, 0
	je display_roll_label
	mov byte [es:di], al
	mov byte [es:di+1], 0x0F
	add di, 2
	jmp display_name_loop
display_roll_label:
	mov di, (12 * SCREEN_WIDTH + 28) * 2
	mov byte [es:di], 'R'
	mov byte [es:di+1], 0x0B
	add di, 2
	mov byte [es:di], 'o'
	mov byte [es:di+1], 0x0B
	add di, 2
	mov byte [es:di], 'l'
	mov byte [es:di+1], 0x0B
	add di, 2
	mov byte [es:di], 'l'
	mov byte [es:di+1], 0x0B
	add di, 2
	mov byte [es:di], ' '
	mov byte [es:di+1], 0x0B
	add di, 2
	mov byte [es:di], 'N'
	mov byte [es:di+1], 0x0B
	add di, 2
	mov byte [es:di], 'o'
	mov byte [es:di+1], 0x0B
	add di, 2
	mov byte [es:di], ':'
	mov byte [es:di+1], 0x0B
	add di, 2
	mov byte [es:di], ' '
	mov byte [es:di+1], 0x0B
	add di, 2
	mov si, player_rollno
display_roll_loop:
	lodsb
	cmp al, 0
	je display_stats
	mov byte [es:di], al
	mov byte [es:di+1], 0x0F
	add di, 2
	jmp display_roll_loop
display_stats:
	mov di, (14 * SCREEN_WIDTH + 30) * 2
	mov byte [es:di], 'S'
	mov byte [es:di+1], 0x0E
	add di, 2
	mov byte [es:di], 'c'
	mov byte [es:di+1], 0x0E
	add di, 2
	mov byte [es:di], 'o'
	mov byte [es:di+1], 0x0E
	add di, 2
	mov byte [es:di], 'r'
	mov byte [es:di+1], 0x0E
	add di, 2
	mov byte [es:di], 'e'
	mov byte [es:di+1], 0x0E
	add di, 2
	mov byte [es:di], ':'
	mov byte [es:di+1], 0x0E
	add di, 2
	mov byte [es:di], ' '
	mov byte [es:di+1], 0x0E
	add di, 2
	mov ax, [score]
	call print_number_at_di
	mov di, (15 * SCREEN_WIDTH + 30) * 2
	mov byte [es:di], 'C'
	mov byte [es:di+1], 0x0E
	add di, 2
	mov byte [es:di], 'o'
	mov byte [es:di+1], 0x0E
	add di, 2
	mov byte [es:di], 'i'
	mov byte [es:di+1], 0x0E
	add di, 2
	mov byte [es:di], 'n'
	mov byte [es:di+1], 0x0E
	add di, 2
	mov byte [es:di], 's'
	mov byte [es:di+1], 0x0E
	add di, 2
	mov byte [es:di], ':'
	mov byte [es:di+1], 0x0E
	add di, 2
	mov byte [es:di], ' '
	mov byte [es:di+1], 0x0E
	add di, 2
	mov ax, [coins_collected]
	call print_number_at_di
	mov di, (18 * SCREEN_WIDTH + 25) * 2
	mov byte [es:di], 'P'
	mov byte [es:di+1], 0x0A
	add di, 2
	mov byte [es:di], 'r'
	mov byte [es:di+1], 0x0A
	add di, 2
	mov byte [es:di], 'e'
	mov byte [es:di+1], 0x0A
	add di, 2
	mov byte [es:di], 's'
	mov byte [es:di+1], 0x0A
	add di, 2
	mov byte [es:di], 's'
	mov byte [es:di+1], 0x0A
	add di, 2
	mov byte [es:di], ' '
	mov byte [es:di+1], 0x0A
	add di, 2
	mov byte [es:di], 'S'
	mov byte [es:di+1], 0x0A
	add di, 2
	mov byte [es:di], 'P'
	mov byte [es:di+1], 0x0A
	add di, 2
	mov byte [es:di], 'A'
	mov byte [es:di+1], 0x0A
	add di, 2
	mov byte [es:di], 'C'
	mov byte [es:di+1], 0x0A
	add di, 2
	mov byte [es:di], 'E'
	mov byte [es:di+1], 0x0A
	add di, 2
	mov byte [es:di], ' '
	mov byte [es:di+1], 0x0A
	add di, 2
	mov byte [es:di], 't'
	mov byte [es:di+1], 0x0A
	add di, 2
	mov byte [es:di], 'o'
	mov byte [es:di+1], 0x0A
	add di, 2
	mov byte [es:di], ' '
	mov byte [es:di+1], 0x0A
	add di, 2
	mov byte [es:di], 'r'
	mov byte [es:di+1], 0x0A
	add di, 2
	mov byte [es:di], 'e'
	mov byte [es:di+1], 0x0A
	add di, 2
	mov byte [es:di], 's'
	mov byte [es:di+1], 0x0A
	add di, 2
	mov byte [es:di], 't'
	mov byte [es:di+1], 0x0A
	add di, 2
	mov byte [es:di], 'a'
	mov byte [es:di+1], 0x0A
	add di, 2
	mov byte [es:di], 'r'
	mov byte [es:di+1], 0x0A
	add di, 2
	mov byte [es:di], 't'
	mov byte [es:di+1], 0x0A
	mov di, (19 * SCREEN_WIDTH + 27) * 2
	mov byte [es:di], 'P'
	mov byte [es:di+1], 0x07
	add di, 2
	mov byte [es:di], 'r'
	mov byte [es:di+1], 0x07
	add di, 2
	mov byte [es:di], 'e'
	mov byte [es:di+1], 0x07
	add di, 2
	mov byte [es:di], 's'
	mov byte [es:di+1], 0x07
	add di, 2
	mov byte [es:di], 's'
	mov byte [es:di+1], 0x07
	add di, 2
	mov byte [es:di], ' '
	mov byte [es:di+1], 0x07
	add di, 2
	mov byte [es:di], 'E'
	mov byte [es:di+1], 0x07
	add di, 2
	mov byte [es:di], 'S'
	mov byte [es:di+1], 0x07
	add di, 2
	mov byte [es:di], 'C'
	mov byte [es:di+1], 0x07
	add di, 2
	mov byte [es:di], ' '
	mov byte [es:di+1], 0x07
	add di, 2
	mov byte [es:di], 't'
	mov byte [es:di+1], 0x07
	add di, 2
	mov byte [es:di], 'o'
	mov byte [es:di+1], 0x07
	add di, 2
	mov byte [es:di], ' '
	mov byte [es:di+1], 0x07
	add di, 2
	mov byte [es:di], 'e'
	mov byte [es:di+1], 0x07
	add di, 2
	mov byte [es:di], 'x'
	mov byte [es:di+1], 0x07
	add di, 2
	mov byte [es:di], 'i'
	mov byte [es:di+1], 0x07
	add di, 2
	mov byte [es:di], 't'
	mov byte [es:di+1], 0x07
	pop es
wait_exit:
	mov ah, 0x00
	int 0x16
	cmp ah, 0x01
	je do_exit
	cmp ah, 0x39
	je do_restart
	jmp wait_exit
do_restart:
	call reset_game_state
	pop si
	pop bx
	pop ax
	jmp start
do_exit:
	pop si
	pop bx
	pop ax
	ret

print_number_at_di:
	push ax
	push bx
	push cx
	push dx
	mov bx, 10
	mov cx, 0
convert_loop:
	mov dx, 0
	div bx
	push dx
	inc cx
	cmp ax, 0
	jne convert_loop
print_loop:
	pop dx
	add dl, '0'
	mov byte [es:di], dl
	mov byte [es:di+1], 0x0E
	add di, 2
	loop print_loop
	pop dx
	pop cx
	pop bx
	pop ax
	ret

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
	call show_intro_screen
wait_intro:
	mov ah, 0x00
	int 0x16
	call show_input_screen
	call show_instruction_screen
wait_instructions:
	mov ah, 0x00
	int 0x16
	mov byte [in_game], 1
	call clear_screen
wait_game_start:
	cmp byte [game_started], 0
	je wait_game_start
game_loop:
	cmp byte [game_paused], 0
	je game_running
	cmp byte [game_paused], 2
	je exit_game
	cmp byte [show_quit_confirm], 1
	jne pause_wait
	cmp byte [confirm_drawn], 1
	je pause_wait
	call show_quit_confirmation
	mov byte [confirm_drawn], 1
pause_wait:
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