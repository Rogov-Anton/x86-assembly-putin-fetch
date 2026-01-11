; 
; Putin fetch - program for displaying system information.
; Copyright (c) Rogov Anton 2026. 
;
; Sponsored by Gaika Kombat (c) 2024-2026.
;


%include "macros.inc"				; PCALL and KERNEL macros

global _start


section .bss
uname_buffer	resb 390			; 6 parts of 65 bytes = 390
os_type		resb 64
hostname	resb 64
kernel		resb 64
uptime_buffer	resb 16				;      buffer size 16, because 
						;   we don't need all the data
						; that `uname` syscall outputs
cpuinfo_buffer	resb 256
cpuinfo		resb 64

meminfo_buffer	resb 64
meminfo		resb 64

arch_buffer	resb 16
; statfs_buffer	resb 64

; number_buffer	resb 20				; max number is 2^64 = 
						; 18446744073709551616
						;         length is 20

buffer		resb 2048

section .text

; white color
first_line	db 10,     " ⣿⣿⣿⣿⣻⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿  PUTIN",             10
		db         " ⣿⣿⣿⣿⣻⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿  -----",             10, 0
username_line	db         " ⣿⣿⣿⣵⣿⣿⣿⠿⡟⣛⣧⣿⣯⣿⣝⡻⢿⣿⣿⣿⣿⣿⣿⣿  Username: soon...", 10, 0
hostname_line	db         " ⣿⣿⣿⣿⣿⠋⠁⣴⣶⣿⣿⣿⣿⣿⣿⣿⣦⣍⢿⣿⣿⣿⣿⣿  Hostname: ",            0
os_line		db         " ⣿⣿⣿⣿⢷⠄⣾⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣏⢼⣿⣿⣿⣿  OS: ",                  0
kernel_line	db         " ⢹⣿⣿⢻⠎⠔⣛⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⡏⣿⣿⣿⣿  Kernel: ",              0
; blue color
first_b_line	db 27, "[34m ⠐⣿⣿⠇⡶⠄⣿⣿⠿⠟⡛⠛⠻⣿⡿⠿⠿⣿⣗⢣⣿⣿⣿⣿",           27, "[00m",  10, 0
uptime_line	db 27, "[34m ⠐⣿⣿⡿⣷⣾⣿⣿⣿⣾⣶⣶⣶⣿⣁⣔⣤⣀⣼⢲⣿⣿⣿⣿  Uptime: ", 27, "[00m",  0
cpu_line	db 27, "[34m ⠄⣿⣿⣿⣿⣾⣟⣿⣿⣿⣿⣿⣿⣿⡿⣿⣿⣿⢟⣾⣿⣿⣿⣿  CPU: ",    27, "[00m",  0
memory_line	db 27, "[34m ⠄⣟⣿⣿⣿⡷⣿⣿⣿⣿⣿⣮⣽⠛⢻⣽⣿⡇⣾⣿⣿⣿⣿⣿  Memory: ", 27, "[00m",  0
disk_line	db 27, "[34m ⠄⢻⣿⣿⣿⡷⠻⢻⡻⣯⣝⢿⣟⣛⣛⣛⠝⢻⣿⣿⣿⣿⣿⣿  Disk: ",   27, "[00m", "soon...", 10, 0

last_b_line	db 27, "[34m ⠄⠸⣿⣿⡟⣹⣦⠄⠋⠻⢿⣶⣶⣶⡾⠃⡂⢾⣿⣿⣿⣿⣿⣿",           27, "[00m",  10, 0
; red color
first_r_line	db 27, "[31m ⠄⠄⠟⠋⠄⢻⣿⣧⣲⡀⡀⠄⠉⠱⣠⣾⡇⠄⠉⠛⢿⣿⣿⣿",                 27, "[00m",         10, 0
arch_line	db 27, "[31m ⠄⠄⠄⠄⠄⠈⣿⣿⣿⣷⣿⣿⢾⣾⣿⣿⣇⠄⠄⠄⠄⠄⠉⠉  Architecture: ", 27, "[00m",         0
							; а зачем проверять, путин форевeр
last_line	db 27, "[31m ⠄⠄⠄⠄⠄⠄⠸⣿⣿⠟⠃⠄⠄⢈⣻⣿⣿⠄⠄⠄⠄⠄⠄⠄  President: ",    27, "[00mPutin",    10
		db 27, "[31m ⠄⠄⠄⠄⠄⠄⠄⢿⣿⣾⣷⡄⠄⢾⣿⣿⣿⡄⠄⠄⠄⠄⠄⠄  Договорнячок: ", 27, "[00mподписан", 10
		db 27, "[31m ⠄⠄⠄⠄⠄⠄⠄⠸⣿⣿⣿⠃⠄⠈⢿⣿⣿⠄⠄⠄⠄⠄⠄⠄  Гойда: ",        27, "[00mесть",     10, 10,  0

m_seconds	db " secs", 10, 0

uptime_file	db "/proc/uptime", 0
cpuinfo_file	db "/proc/cpuinfo", 0
meminfo_file	db "/proc/meminfo", 0
arch_file	db "/proc/sys/kernel/arch", 0	; path to file 
root		db "/", 0
newline		db 10



;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; MOVE PARTS ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;
; Places a given part of one buffer into another buffer,
; and writes a new line (char with code 10) to the end of the data
; Parameters:
;   * [ebp+8] - source buffer
;   * [ebp+12] - another buffer
;

move_parts:	push	ebp
		mov	ebp, esp
		push	esi
		push	edi

		mov	esi, [ebp+8]
		mov	edi, [ebp+12]

.loop:		lodsb
		test	al, al			; if end of data in source
		jz	.end			;                   buffer
		stosb
		jmp short .loop

.end:		mov	[edi], byte 10

		pop	edi
		pop	esi
		mov	ebp, esp
		pop	ebp
		ret


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; READ FILE ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;
; Reads the file and writes it to the buffer
; Parameters:
;   * [ebp+8] - file name
;   * [ebp+12] - buffer address
;   * [ebp+16] - buffer size
;

read_file:	push	ebp
		mov	ebp, esp
		sub	esp, 4

		; open file
		KERNEL	5, [ebp+8], 0

		mov	[ebp-4], eax		; discriptor in [ebp-4]
		
		; read file
		KERNEL	3, [ebp-4], [ebp+12], [ebp+16]
		; close file
		KERNEL	6, [ebp-4]

		mov	esp, ebp
		pop	ebp
		ret


;;;;;;;;;;;;;;;;;;;;;;;;;;;;; READ UPTIME ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

get_uptime:	push	ebp
		mov	ebp, esp
		sub	esp, 4
		push	esi

		PCALL	read_file, uptime_file,  uptime_buffer, 16

		mov	esi, uptime_buffer
		cld

.loop:		lodsb
		cmp	al, 46			; data from /proc/uptime
						;  separated by dot (46)
		jz	.end

		mov	[ebp-4], eax

		sub	ebp, 4			; to get EBP-4, where we
						;              save char
		add	ebp, 4
		jmp short .loop

.end:		mov	byte [esi - 1], 0
		pop	esi
		mov	esp, ebp
		pop	ebp
		ret


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; CPU INFO ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

get_cpuinfo:	push	ebp
		mov	ebp, esp
		sub	esp, 4
		push	esi
		push	edi

		PCALL	read_file, cpuinfo_file, cpuinfo_buffer, 256

		mov	esi, cpuinfo_buffer
		mov	byte [ebp-4], 5		;    we need to read 5 lines,
						;     because the information 
						; we need about the processor
						;          is in the 5th line
		cld

.loop:		cmp	byte [ebp-4], 0
		jz	.end_loop
		dec	byte [ebp-4]

.check_char:	lodsb
		cmp	al, ":"
		jz	.loop
		jmp short .check_char

.end_loop:	mov	edi, cpuinfo
.move_char:	
		lodsb
		cmp	al, 10
		jz	.end
		stosb
		jmp short .move_char

.end:		mov	byte [edi], 10		; newline
		pop	edi
		pop	esi
		mov	esp, ebp
		pop	ebp
		ret


;;;;;;;;;;;;;;;;;;;;;;;;;;;;; MEMORY INFO ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

get_meminfo:	push	ebp
		mov	ebp, esp
		push	esi
		push	edi

		PCALL	read_file, meminfo_file, meminfo_buffer, 64

		mov	esi, meminfo_buffer

		; /proc/meminfo (first line): 
		; [letters, spaces, number]
		; [MemTotal:        12345 kB]
		cld

.letter:	lodsb
		cmp	al, " "
		jz	.space
		jmp short .letter

.space:		lodsb
		cmp	al, " "
		jnz	.end_of_spaces
		jmp short .space

.end_of_spaces:	mov	edi, meminfo
.digit:		stosb				; AL -> [EDI]
		cmp	al, 10			; if end of line
		jz	.end
		lodsb				; AL <- [ESI]
		jmp short .digit

.end:		mov	[edi], byte 0		; record a limiting zero
		pop	edi
		pop	esi
		mov	esp, ebp
		pop	ebp
		ret


;;;;;;;;;;;;;;;;;;;;;;;;;;;;; WRITE BUFFER ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;
; Writes the contents of one buffer to another
; Parameters:
;   * [ebp+8] - source buffer
;   * edi - another buffer

write_buffer:	push	ebp
		mov	ebp, esp
		push	esi

		mov	esi, [ebp+8]

.read_byte:	lodsb				; AL <- [ESI]
		test	al, al
		jz	.end
		stosb				; AL -> [EDI]
		jmp short .read_byte

.end:		pop	esi
		mov	esp, ebp
		pop	ebp
		ret


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; BUFFER UNION ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

buffers_union:	push	ebp
		mov	ebp, esp

		mov	edi, buffer

		; white
		PCALL	write_buffer, first_line
		PCALL	write_buffer, username_line
		PCALL	write_buffer, hostname_line
		PCALL	write_buffer, hostname
		PCALL	write_buffer, os_line
		PCALL	write_buffer, os_type
		PCALL	write_buffer, kernel_line
		PCALL	write_buffer, kernel
		; blue
		PCALL	write_buffer, first_b_line
		PCALL	write_buffer, uptime_line
		PCALL	write_buffer, uptime_buffer
		PCALL	write_buffer, m_seconds
		PCALL	write_buffer, cpu_line
		PCALL	write_buffer, cpuinfo
		PCALL	write_buffer, memory_line
		PCALL	write_buffer, meminfo
		PCALL	write_buffer, disk_line
		PCALL	write_buffer, last_b_line

		PCALL	write_buffer, first_r_line
		PCALL	write_buffer, arch_line
		PCALL	write_buffer, arch_buffer
		PCALL	write_buffer, last_line

		mov	esp, ebp
		pop	ebp
		ret


;;;;;;;;;;;;;;;;;;;;;;;;;;;;; MAIN PROGRAM ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

_start:		KERNEL	122, uname_buffer, 390
		; Takes all the necessary information from uname_buffer 
		; and places it in os_type, hostname, kernel
		PCALL	move_parts, uname_buffer, os_type	; OS
		PCALL	move_parts, uname_buffer + 65, hostname	; hostname
		PCALL	move_parts, uname_buffer + 130, kernel	; kernel

		call	get_uptime
		call	get_cpuinfo
		call	get_meminfo
		PCALL	read_file, arch_file, arch_buffer, 16

		mov	esi, arch_buffer	; write 10 (new line) to end
						; data in arch_buffer
arch_loop:	lodsb
		cmp	al, 0
		jz	end
		jmp short arch_loop
end:		mov	byte [esi], 10

		call	buffers_union
		KERNEL	4, 1, buffer, 2048

		KERNEL	1, 0

;;;;;;;;;;;;;;;;;;;
;;not working yet;;
;;;;;;;;;;;;;;;;;;;

; ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; DISK INFO ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; 
; get_disk_info:	push	ebp
; 		mov	ebp, esp
; 		push	ebx
; 		push	esi
; 
; 		KERNEL	99, root, statfs_buffer
; 
; 		; extract data from the buffer:
; 		; offset 4:  size of one block in bytes
; 		; offset 8:  total number of blocks
; 		; offset 12: free blocks
; 		mov	eax, [statfs_buffer + 4]
; 		mov	ebx, [statfs_buffer + 8]
; 		mov	ecx, [statfs_buffer + 12]
; 
; 		sub	ebx, ecx		; how many blocks are in use
; 		mul	ebx			; EAX * EBX = EDX:EAX
; 
; 		PCALL	convert_number, ebx, number_buffer
; 
; 		mov	esi, number_buffer
; 		mov	ecx, 20
; 
; .add_digit:	cmp	ecx, 20
; 		jz	.end
; 		lodsb				; AL <- [ESI]
; 		mov	byte [number_buffer + ecx], al
; 		jmp short .add_digit
; 
; 		;; PCALL print_number, number_buffer
; 		
; .end:		mov	byte [number_buffer + ecx], 0
; 		pop	esi
; 		pop	ebx
; 		mov	esp, ebp
; 		pop	ebp
; 		ret

; ;;;;;;;;;;;;;;;;;;;;;;;;;;;; CONVERT NUMBER ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; 
; ;
; ; Converts a number to a string
; ; Parameters:
; ;   * [ebp+8] - number
; ;   * [ebp+12] - buffer for result
; ;
; 
; convert_number:	push	ebp			; buffer structure: 
; 						; [0, 0, ... 0, <number>]
; 		mov	ebp, esp
; 		sub	esp, 4
; 		push	edi
; 
; 		mov	dword [ebp-4], 10	; 32-bit divisor
; 		mov	edi, [ebp+12]
; 		add	edi, 19			; 20(buffer_size) - 1
; 		std
; 		mov	eax, [ebp+8]
; 
; .add_digit:	test	eax, eax
; 		jz	.end
; 		xor	edx, edx		; EDX = 0
; 		div	dword [ebp-4]		; EAX / 10 -> EAX:EDX
; 		
; 		add	edx, "0"
; 		
; 		mov	[edi], dl
; 		dec	edi
; 
; 		jmp short .add_digit
; 
; .end:		pop	edi
; 		mov	esp, ebp
; 		pop	ebp
; 		ret


; ; procedure to print number, that `convert_number` write to buffer
; print_number:	push	ebp
; 		mov	ebp, esp
; 		push	esi
; 		
; 		mov	cl, 0			; number length
; 		mov	esi, [ebp+8]		; [ebp+8] - number buffer
; 		cld
; .loop:		lodsb
; 		test	al, al
; 		jnz	.dec_esi
; 		inc	cl
; 		jmp short .loop
; 
; .dec_esi:	dec	esi
; .print_digit:	KERNEL	4, 1, esi, 1
; 		inc	cl
; 		cmp	cl, 20
; 		jz	.end
; 		lodsb
; 		jmp short .print_digit
; 
; .end:		; KERNEL	4, 1, newline, 1
; 		pop	esi
; 		mov	esp, ebp
; 		pop	ebp
; 		ret
