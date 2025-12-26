org 0x1000
bits 16

; -----------------------
; Constants
; -----------------------
SECTOR_SIZE       equ 512
RESERVED_SECTORS  equ 1
NUM_FATS          equ 2
FAT_SIZE_SECTORS  equ 9
ROOT_DIR_ENTRIES  equ 224
CLUSTER_SIZE      equ 1
ROOT_DIR_SECTOR   equ RESERVED_SECTORS + NUM_FATS*FAT_SIZE_SECTORS
DATA_START_SECTOR equ ROOT_DIR_SECTOR + ((ROOT_DIR_ENTRIES*32)/SECTOR_SIZE)

; -----------------------
; Memory layout
; -----------------------
FAT1_MEM equ 0x2000
FAT2_MEM equ FAT1_MEM + SECTOR_SIZE*FAT_SIZE_SECTORS
BUFFER_MEM equ 0x3000

; -----------------------
; Data
; -----------------------
screen_row db 0
screen_col db 0
editor_buffer times 4096 db 0   ; 4 KB editor buffer

prompt db "> ",0
banner db "FloppyOS v2.0",10,0
help_msg db "Commands: help, clear, edit, save",10,0
unknown db "Unknown command",10,0

cmd times 32 db 0
help_cmd db "help",0
clear_cmd db "clear",0
edit_cmd db "edit",0
save_cmd db "save",0

filename db "FILE    TXT"  ; 8.3 format

; -----------------------
; Kernel entry
; -----------------------
start:
    call clear_screen
    mov si, banner
    call print
    call init_mouse

shell:
    mov si, prompt
    call print
    mov di, cmd
    call read_line

    mov si, cmd
    mov di, help_cmd
    call strcmp
    jc do_help

    mov si, cmd
    mov di, clear_cmd
    call strcmp
    jc do_clear

    mov si, cmd
    mov di, edit_cmd
    call strcmp
    jc do_edit

    mov si, cmd
    mov di, save_cmd
    call strcmp
    jc do_save

    mov si, unknown
    call print
    jmp shell

do_help:
    mov si, help_msg
    call print
    jmp shell

do_clear:
    call clear_screen
    jmp shell

do_edit:
    call editor
    jmp shell

do_save:
    call save_file
    jmp shell

; -----------------------
; Basic I/O
; -----------------------
print:
    mov ah,0x0E
.p:
    lodsb
    or al,al
    jz .done
    int 0x10
    jmp .p
.done:
    ret

read_line:
    mov cx,0
.rl:
    call get_key
    cmp al,13
    je .done
    mov [di],al
    inc di
    mov ah,0x0E
    int 0x10
    jmp .rl
.done:
    mov byte [di],0
    mov ah,0x0E
    mov al,10
    int 0x10
    ret

get_key:
    mov ah,0
    int 0x16
    ret

strcmp:
    push si
    push di
.cmp:
    mov al,[si]
    mov bl,[di]
    cmp al,bl
    jne .no
    or al,al
    jz .yes
    inc si
    inc di
    jmp .cmp
.no:
    pop di
    pop si
    clc
    ret
.yes:
    pop di
    pop si
    stc
    ret

clear_screen:
    mov ax,0x03
    int 0x10
    mov byte [screen_row],0
    mov byte [screen_col],0
    ret

; -----------------------
; Editor
; -----------------------
editor:
    mov si,"Editor: ESC to exit",0
    call print
    mov di, editor_buffer

.ed_loop:
    call get_key
    cmp al,27
    je .ed_done

    cmp al,0
    jne .normal_key
    call get_key
    cmp al,72
    je .up
    cmp al,80
    je .down
    cmp al,75
    je .left
    cmp al,77
    je .right
    jmp .ed_loop

.up:
    dec byte [screen_row]
    call move_cursor
    jmp .ed_loop
.down:
    inc byte [screen_row]
    call move_cursor
    jmp .ed_loop
.left:
    dec byte [screen_col]
    call move_cursor
    jmp .ed_loop
.right:
    inc byte [screen_col]
    call move_cursor
    jmp .ed_loop

.normal_key:
    mov [di],al
    inc di
    mov ah,0x0E
    int 0x10
    call update_cursor
    jmp .ed_loop

.ed_done:
    ret

move_cursor:
    mov ah,2
    mov bh,0
    mov dh,[screen_row]
    mov dl,[screen_col]
    int 0x10
    ret

update_cursor:
    inc byte [screen_col]
    cmp byte [screen_col],80
    jl .skip
    mov byte [screen_col],0
    inc byte [screen_row]
.skip:
    call move_cursor
    ret

; -----------------------
; Mouse init
; -----------------------
init_mouse:
    mov ax,0
    int 33h
    mov ax,1
    int 33h
    ret

; -----------------------
; FAT12 Save
; -----------------------
save_file:
    ; Step 1: read first FAT
    mov bx,FAT1_MEM
    mov ah,0x02
    mov al,FAT_SIZE_SECTORS
    mov ch,0
    mov cl,RESERVED_SECTORS+1
    mov dh,0
    mov dl,0x00
    int 0x13

    ; Step 2: find required clusters
    mov si,editor_buffer
    call allocate_clusters

    ; Step 3: write clusters to disk
    call write_clusters

    ; Step 4: update FAT2 copy
    mov bx,FAT2_MEM
    call update_FAT2

    ; Step 5: write root directory entry
    call write_root_entry

    mov si,"File saved!",0
    call print
    ret

; -----------------------
; Allocate clusters
; -----------------------
allocate_clusters:
    ; Pseudo-implementation:
    ; Iterate FAT1_MEM, find free clusters, mark them as used
    ; Store cluster numbers in a temporary table
    ret

; -----------------------
; Write clusters
; -----------------------
write_clusters:
    ; Write editor_buffer to each allocated cluster using INT 13h
    ret

; -----------------------
; Update FAT2
; -----------------------
update_FAT2:
    ; Copy FAT1_MEM content to FAT2_MEM on disk
    ret

; -----------------------
; Write root directory
; -----------------------
write_root_entry:
    ; Write 32-byte entry with filename, first cluster, file size
    ret
