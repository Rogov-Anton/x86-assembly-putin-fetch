# x86-assembly-putin-fetch

Program for displaying system information for x86 architecture (can also be run for x86-64)

To compile this program, you need to install the NASM assembler.

### Build:
  ```
  make
  ```
or
  ```
  nasm -f elf putin.asm -o putin.o
  ld -m elf_i386 putin.o -o putin
  ```

### Run:
  ```
  ./putin
  ```
