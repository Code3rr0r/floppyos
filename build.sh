#!/bin/bash
nasm boot.asm -f bin -o boot.bin
nasm kernel.asm -f bin -o kernel.bin
cat boot.bin kernel.bin > os.img
echo "FloppyOS v2.0 built!"
