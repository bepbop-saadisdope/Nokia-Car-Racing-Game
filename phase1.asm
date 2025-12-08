[org 0x0100]
jmp start

; ==================== DATA SECTION ====================
; Screen dimensions
SCREEN_WIDTH	equ 80
SCREEN_HEIGHT	equ 25

; Road layout
GRASS_WIDTH	equ 5
ROAD_START	equ 5
ROAD_WIDTH	equ 70
ROAD_END	equ 75

; Lane positions 
LANE1_COL	equ 20
LANE2_COL	equ 35
LANE3_COL	equ 50
LANE4_COL	equ 65

; Colors - 
COLOR_GRASS	equ 0xAA	; bright green on bright green
COLOR_BORDER	equ 0x22	; dark green border
COLOR_ROAD	equ 0x88	; dark gray road
COLOR_LANE	equ 0x8F	; white on dark gray
COLOR_RED_CAR	equ 0xCC	; bright red
COLOR_BLUE_CAR	equ 0x99	; bright blue
COLOR_YELLOW	equ 0xEE	; yellow (for car details)
COLOR_BLACK	equ 0x00	; black (for windows)

; Car positions
player_row:	dw 20
player_col:	dw 35		; center lane
obstacle_row:	dw 5
obstacle_col:	dw 20		; will be randomized to lane position

; ==================== SUBROUTINES ====================

; Clear screen 
clear_screen:
	push ax
	push cx
	push di
	push es
	
	; BIOS clear
	mov ah, 0x00
	mov al, 0x03
	int 10h
	
	; Manual clear 
	mov ax, 0xB800
	mov es, ax
	mov di, 0
	mov cx, SCREEN_WIDTH * SCREEN_HEIGHT
	mov ax, 0x0720		
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

; Draw lane markers - 3 lanes (4 sections)
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
	; Draw marker every 2 rows, skip 2 rows
	mov ax, cx
	mov dx, 0
	push cx
	mov cx, 4
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

; Draw obstacle car (blue) - improved design
draw_obstacle_car:
	push ax
	push bx
	push cx
	push di
	push es
	
	mov ax, 0xB800
	mov es, ax
	
	; Calculate position
	mov ax, [obstacle_row]
	mov bx, SCREEN_WIDTH
	mul bx
	shl ax, 1
	mov di, ax
	mov ax, [obstacle_col]
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

; Randomize obstacle to one of 4 lanes
randomize_obstacle:
	push ax
	push bx
	push cx
	push dx
	
	; Get system time
	mov ah, 0x00
	int 0x1A
	
	; Random row: 3 to 12
	mov ax, dx
	mov dx, 0
	mov bx, 10
	div bx
	add dx, 3
	mov [obstacle_row], dx
	
	; Get new random for lane
	mov ah, 0x00
	int 0x1A
	mov ax, dx
	
	; Random lane: 0 to 3
	mov dx, 0
	mov bx, 4
	div bx
	
	; Set column based on lane
	cmp dx, 0
	je set_lane1
	cmp dx, 1
	je set_lane2
	cmp dx, 2
	je set_lane3
	jmp set_lane4
	
set_lane1:
	mov word [obstacle_col], LANE1_COL
	jmp done_lane
set_lane2:
	mov word [obstacle_col], LANE2_COL
	jmp done_lane
set_lane3:
	mov word [obstacle_col], LANE3_COL
	jmp done_lane
set_lane4:
	mov word [obstacle_col], LANE4_COL
	
done_lane:
	pop dx
	pop cx
	pop bx
	pop ax
	ret

wait_for_key:
	push ax
	
wait_loop:
	; Check if key is available
	mov ah, 0x01
	int 0x16
	jz wait_loop		; no key pressed, keep waiting
	
	; Get the key
	mov ah, 0x00
	int 0x16
	
	; Check if ESC key (scan code in AH = 0x01, ASCII in AL = 0x1B)
	cmp ah, 0x01		; ESC scan code
	je exit_program
	
	; If not ESC, keep waiting
	jmp wait_loop
	
exit_program:
	pop ax
	ret

; ==================== MAIN PROGRAM ====================
start:
	call clear_screen
	
	call randomize_obstacle
	
	call draw_grass
	call draw_road
	call draw_lanes
	call draw_player_car
	call draw_obstacle_car
	
	call wait_for_key
	
	call clear_screen
	
	mov ax, 0x4C00
	int 21h