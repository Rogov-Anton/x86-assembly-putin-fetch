%macro PCALL 1-*
	%rep %0 - 1
		%rotate -1
			push dword %1
	%endrep
	%rotate -1
		call	%1
		add	esp, (%0 - 1) * 4
%endmacro


%macro PROC_START 1-*
	push	ebp
	mov	ebp, esp
	sub	esp, %1
	%rep %0 - 1
		%rotate -1
			push %1
	%endrep
%endmacro


%macro PROC_END 1-*
	%rep %0 - 1
		%rotate 1
			pop %1
	%endrep
	mov	esp, ebp
	pop	ebp
	ret
%endmacro


%macro	KERNEL 1-*

%if %0 > 1
		push ebx
	%if %0 > 4
		push esi
		push edi
		push ebp
	%endif
%endif

%rep %0
	%rotate -1
		push dword %1
%endrep

		pop eax
%if %0 > 1
		pop ebx
	%if %0 > 2
		pop ecx
		%if %0 > 3
		pop edx
			%if %0 > 4
		pop esi
				%if %0 > 5
		pop edi
					%if %0 > 6
		pop ebp
						%if %0 > 7
						%error "Can't handle Linux"
						       "syscalls for 7+ params"
						%endif
					%endif
				%endif
			%endif
		%endif
	%endif
%endif
		int 	80h

%if %0 > 1
	%if %0 > 4
		pop	 ebp
		pop	 edi
		pop	 esi
	%endif
		pop	 ebx
%endif

%endmacro
