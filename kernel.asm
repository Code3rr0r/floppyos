org 0x1000
bits 16

start:
    mov ah, 0x0E
    mov si, msg

.print:
    lodsb
    or al, al
    jz halt
    int 0x10
    jmp .print

halt:
    cli
    hlt

msg db "FloppyOS kernel running!", 0
