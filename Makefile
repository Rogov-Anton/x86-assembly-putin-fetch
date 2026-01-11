putin: putin.o
	ld -m elf_i386 putin.o -o putin

putin.o: putin.asm
	nasm -f elf putin.asm -o putin.o
