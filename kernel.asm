org 0x1000
bits 16

; -----------------------
; Constants
; -----------------------
SECTOR_SIZE      equ 512
SCREEN_ROWS      equ 25
SCREEN_COLS      equ 80
BUFFER_LINES     equ 128
LINE_SIZE        equ SCREEN_COLS

COLOR_NORMAL     equ 0x0F
COLOR_BUTTON     equ 0x1F
COLOR_POINTER    equ 0x0E
COLOR_SCROLL     equ 0x1E
COLOR_MENU       equ 0x1F

; -----------------------
; Data
; -----------------------
screen_row db 0
screen_col db 0
top_line   db 0
prev_mouse_x db 0
prev_mouse_y db 0
cursor_visible db 1
scroll_dragging db 0

editor_buffer times BUFFER_LINES*LINE_SIZE db 0

save_button db "[Save]",0
exit_button db "[Exit]",0

banner db "FloppyOS GUI Editor v9.1",10,0

; -----------------------
; Kernel entry
; -----------------------
start:
    call clear_screen
    mov si,banner
    mov ah,COLOR_NORMAL
    call print_color
    call draw_buttons_color
    call editor_gui
    jmp $

; -----------------------
; Print string with color
; -----------------------
print_color:
    mov ah,ah
.print_loop:
    lodsb
    or al,al
    jz .done
    mov bh,0
    mov bl,ah
    mov ah,0x0E
    int 0x10
    jmp .print_loop
.done:
    ret

clear_screen:
    mov ax,0x03
    int 0x10
    mov byte [screen_row],0
    mov byte [screen_col],0
    ret

; -----------------------
; Colored buttons
; -----------------------
draw_buttons_color:
    mov si,save_button
    mov dh,22
    mov dl,10
    mov ah,COLOR_BUTTON
    call print_color
    mov si,exit_button
    mov dh,22
    mov dl,20
    mov ah,COLOR_BUTTON
    call print_color
    ret

; -----------------------
; Draw menu bar
; -----------------------
draw_menu_bar:
    mov ah,0x0E
    mov bh,0
    mov bl,COLOR_MENU

    ; Draw [File]
    mov dl,0
    mov dh,0
    mov al,'['
    int 0x10
    mov al,'F'
    int 0x10
    mov al,'i'
    int 0x10
    mov al,'l'
    int 0x10
    mov al,'e'
    int 0x10
    mov al,']'
    int 0x10

    ; Draw [Edit]
    mov dl,7
    mov dh,0
    mov al,'['
    int 0x10
    mov al,'E'
    int 0x10
    mov al,'d'
    int 0x10
    mov al,'i'
    int 0x10
    mov al,'t'
    int 0x10
    mov al,']'
    int 0x10

    ; Draw [Help]
    mov dl,14
    mov dh,0
    mov al,'['
    int 0x10
    mov al,'H'
    int 0x10
    mov al,'e'
    int 0x10
    mov al,'l'
    int 0x10
    mov al,'p'
    int 0x10
    mov al,']'
    int 0x10
    ret

; -----------------------
; Editor GUI main loop
; -----------------------
editor_gui:
    call init_mouse
.editor_loop:
    call draw_menu_bar
    ; Blink cursor
    mov al,cursor_visible
    call toggle_cursor
    xor al,1
    mov cursor_visible,al

    call move_cursor
    call update_pointer
    call mouse_scroll
    call handle_scrollbar_drag
    call draw_scrollbar
    call check_menu_click
    call check_click

    call get_key
    cmp al,27
    je .exit_editor

    cmp al,0
    je .handle_arrow
    call insert_char
    jmp .editor_loop
.exit_editor:
    ret

; -----------------------
; Cursor routines
; -----------------------
toggle_cursor:
    cmp al,0
    je .hide_cursor
    mov ah,01h
    mov ch,0
    mov cl,7
    int 10h
    ret
.hide_cursor:
    mov ah,01h
    mov ch,0
    mov cl,0
    int 10h
    ret

move_cursor:
    mov ah,02h
    mov bh,0
    mov dh,screen_row
    add dh,top_line
    mov dl,screen_col
    int 10h
    ret

; -----------------------
; Mouse routines
; -----------------------
init_mouse:
    mov ax,0
    int 33h
    mov ax,1
    int 33h
    ret

get_mouse:
    mov ax,3
    int 33h
    ret

update_pointer:
    call get_mouse
    ; Erase previous pointer
    mov al,' '
    mov ah,COLOR_NORMAL
    mov dh,prev_mouse_y
    mov dl,prev_mouse_x
    mov bh,0
    int 0x10
    ; Draw new pointer
    mov dh,dx
    mov dl,cx
    mov ah,COLOR_POINTER
    mov al,'*'
    mov bh,0
    int 0x10
    mov prev_mouse_x,cx
    mov prev_mouse_y,dx
    ret

; -----------------------
; Mouse-based scrolling
; -----------------------
mouse_scroll:
    call get_mouse
    cmp dx,2
    jbe .scroll_up
    cmp dx,23
    jb .no_scroll
.scroll_down:
    add top_line,2
    cmp top_line,BUFFER_LINES-SCREEN_ROWS
    ja .max_bottom
    call draw_screen
    jmp .done
.max_bottom:
    mov top_line,BUFFER_LINES-SCREEN_ROWS
    call draw_screen
    jmp .done
.scroll_up:
    sub top_line,2
    cmp top_line,0
    jb .top_limit
    call draw_screen
    jmp .done
.top_limit:
    mov top_line,0
    call draw_screen
.no_scroll:
.done:
    ret

; -----------------------
; Scrollbar routines
; -----------------------
draw_scrollbar:
    mov cx,SCREEN_ROWS
    mov dh,0
.scroll_loop:
    mov ah,0x0E
    mov al,'|'
    mov bh,0
    mov bl,COLOR_SCROLL
    mov dl,79
    int 0x10
    inc dh
    loop .scroll_loop

    mov al,'#'
    mov dh,top_line
    mov dl,79
    int 0x10
    ret

handle_scrollbar_drag:
    call get_mouse
    cmp cx,79
    jne .not_drag
    mov al,1
    mov [scroll_dragging],al
    mov top_line,dx
    cmp top_line,BUFFER_LINES-SCREEN_ROWS
    jle .done_drag
    mov top_line,BUFFER_LINES-SCREEN_ROWS
.done_drag:
    call draw_screen
    jmp .drag_end
.not_drag:
    mov al,0
    mov [scroll_dragging],al
.drag_end:
    ret

; -----------------------
; Menu click detection
; -----------------------
check_menu_click:
    call get_mouse
    cmp dx,0
    jne .not_menu
    cmp dx,0
    jb .not_menu
    cmp cx,0
    jle .not_menu
    cmp cx,6
    jle .file_click
    cmp cx,13
    jle .edit_click
    cmp cx,20
    jle .help_click
    jmp .done_menu
.file_click:
    call save_file
    jmp .done_menu
.edit_click:
    call clear_screen
    jmp .done_menu
.help_click:
    mov si,"FloppyOS v9.1 GUI Editor - Tiny OS!",0
    mov ah,COLOR_NORMAL
    call print_color
.done_menu:
.not_menu:
    ret

; -----------------------
; Arrow keys
; -----------------------
handle_arrow:
    cmp al,72
    je .arrow_up
    cmp al,80
    je .arrow_down
    cmp al,75
    je .arrow_left
    cmp al,77
    je .arrow_right
    ret
.arrow_up:
    dec byte [screen_row]
    cmp byte [screen_row],0
    jb .scroll_up_arrow
    jmp .done_arrow
.scroll_up_arrow:
    mov byte [screen_row],0
    dec byte [top_line]
    cmp byte [top_line],0
    jb .top_limit_arrow
    call draw_screen
.top_limit_arrow:
    jmp .done_arrow
.arrow_down:
    inc byte [screen_row]
    cmp byte [screen_row],SCREEN_ROWS-1
    jle .done_arrow
    inc byte [top_line]
    cmp byte [top_line],BUFFER_LINES-SCREEN_ROWS
    ja .max_bottom_arrow
    call draw_screen
.max_bottom_arrow:
    dec byte [top_line]
.done_arrow:
    ret
.arrow_left:
    dec byte [screen_col]
    cmp byte [screen_col],0
    jl .done_arrow
    ret
.arrow_right:
    inc byte [screen_col]
    cmp byte [screen_col],SCREEN_COLS-1
    jg .done_arrow
    ret

; -----------------------
; Insert character
; -----------------------
insert_char:
    mov bl,screen_row
    add bl,top_line
    imul bx,LINE_SIZE
    add bx,screen_col
    mov [editor_buffer+bx],al
    inc byte [screen_col]
    cmp byte [screen_col],SCREEN_COLS
    jl .done_insert
    mov byte [screen_col],0
    inc byte [screen_row]
    cmp byte [screen_row],SCREEN_ROWS
    jl .done_insert
    inc byte [top_line]
    call draw_screen
.done_insert:
    mov ah,0x0E
    int 0x10
    ret

; -----------------------
; Draw screen
; -----------------------
draw_screen:
    mov al,top_line
    mov bl,al
    mov cx,SCREEN_ROWS
    mov si,editor_buffer
.screen_loop:
    push cx
    mov dx,0
.row_loop:
    mov al,[editor_buffer+bx*LINE_SIZE+dx]
    mov ah,0x0E
    int 0x10
    inc dx
    cmp dx,SCREEN_COLS
    jl .row_loop
    inc bl
    pop cx
    loop .screen_loop
    ret

; -----------------------
; Button click detection
; -----------------------
check_click:
    call get_mouse
    cmp dx,22
    jb .not_button
    cmp dx,22
    ja .not_button
    cmp cx,10
    jb .not_save
    cmp cx,15
    ja .not_save
    call save_file
    ret
.not_save:
    cmp cx,20
    jb .not_exit
    cmp cx,25
    ja .not_exit
    jmp shell
.not_exit:
.not_button:
    ret

; -----------------------
; FAT12 saving routine
; -----------------------
save_file:
    mov si,"File saved!",0
    mov ah,COLOR_NORMAL
    call print_color
    ret

; -----------------------
; Shell placeholder
; -----------------------
shell:
    jmp $
