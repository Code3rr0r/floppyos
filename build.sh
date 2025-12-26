# Build
nasm boot.asm -f bin -o boot.bin
nasm kernel.asm -f bin -o kernel.bin
cat boot.bin kernel.bin > os.img

# Write to floppy
sudo dd if=os.img of=/dev/fd0 bs=512 conv=notrunc
