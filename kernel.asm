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

FAT1_MEM equ 0x2000
FAT2_MEM equ FAT1_MEM + SECTOR_SIZE*FAT_SIZE_SECTORS
BUFFER_MEM equ 0x3000

; -----------------------
; Data
; -----------------------
screen_row db 0
screen_col db 0
editor_buffer times 4096 db 0

; GUI buttons
save_button db "[Save]",0
exit_button db "[Exit]",0

prompt db "> ",0
banner db "FloppyOS GUI Editor v3.0",10,0

; -----------------------
; Kernel entry
; -----------------------
start:
    call clear_screen
    mov si,banner
    call print
    call draw_gui
    call editor_gui
    jmp $

; -----------------------
; Print string
; -----------------------
print:
    mov ah,0x0E
.print_loop:
    lodsb
    or al,al
    jz .done
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
; Draw GUI
; -----------------------
draw_gui:
    ; Draw top banner
    mov si,banner
    call print
    ; Draw buttons
    mov si,save_button
    call print
    mov si,exit_button
    call print
    ret

; -----------------------
; Editor GUI
; -----------------------
editor_gui:
    mov di,editor_buffer
.editor_loop:
    call get_key
    cmp al,27
    je .exit_editor
    ; Insert printable characters
    mov [di],al
    inc di
    mov ah,0x0E
    int 0x10
    jmp .editor_loop
.exit_editor:
    ret

get_key:
    mov ah,0
    int 0x16
    ret
