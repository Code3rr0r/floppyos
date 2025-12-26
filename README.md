# FloppyOS

FloppyOS is a tiny, non-Linux operating system written in x86 assembly.
It is designed to fit easily within a 1 MB floppy disk.

## Features
- Custom bootloader
- Custom kernel
- No Linux
- No libc
- No POSIX
- Boots via BIOS
- <10 KB total size

## Requirements
- NASM
- QEMU

## Build
```bash
./build.sh
