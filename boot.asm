org 0x7C00
bits 16

start:
    cli
    xor ax,ax
    mov ds,ax
    mov es,ax

    ; Load kernel: sectors 2-11 (adjust if kernel bigger)
    mov bx,0x1000       ; load address
    mov ah,0x02         ; BIOS read sector
    mov al,10           ; number of sectors
    mov ch,0
    mov cl,2
    mov dh,0
    mov dl,0x00         ; floppy A:
    int 0x13

    jmp 0x1000:0

times 510-($-$$) db 0
dw 0xAA55
