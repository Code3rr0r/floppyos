org 0x7C00
bits 16

start:
    cli                 ; Disable interrupts
    xor ax, ax          ; Clear AX register
    mov ds, ax          ; Set DS to 0
    mov es, ax          ; Set ES to 0

    ; Load kernel: sectors 2-11
    mov bx, 0x1000      ; Kernel load address
    mov ah, 0x02        ; BIOS read sector function
    mov al, 10          ; Read 10 sectors
    mov ch, 0           ; Cylinder 0
    mov cl, 2           ; Starting sector
    mov dh, 0           ; Head 0
    mov dl, 0x00        ; Floppy A:
    int 0x13            ; BIOS interrupt to read sectors

    ; Check if disk read was successful
    jc disk_error       ; Jump if carry flag is set (error)

    ; Jump to the loaded kernel
    jmp 0x1000:0

disk_error:
    ; Handle disk read error (could print error or retry)
    mov ah, 0x0E        ; BIOS teletype function (for text output)
    mov al, 'E'         ; Character 'E'
    int 0x10            ; Call BIOS video interrupt (prints 'E')
    hlt                 ; Halt the system

times 510-($-$$) db 0  ; Fill remaining space with zeroes
dw 0xAA55              ; Bootloader signature
