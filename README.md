# x86-assembly-putin-fetch

### Build:
  ```
  nasm -f elf putin.asm -o putin.o
  ld -m elf_i386 putin.o -o putin
  ```

### Run:
  ```
  ./putin
  ```
