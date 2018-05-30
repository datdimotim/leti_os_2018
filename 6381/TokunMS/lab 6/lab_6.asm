DATA 	SEGMENT
		MEMORY_ERROR_7   db 13, 10,'MCB destroyed!', 13, 10,'$'
		MEMORY_ERROR_8   db 13, 10,'Not enough memory!', 13, 10,'$'
		MEMORY_ERROR_9   db 13, 10,'Wrong address of memory block!', 13, 10,'$'		

		CALL_ERROR_1		db 13, 10,'Wrong number of function!', 13, 10,'$'
		CALL_ERROR_2    	db 13, 10,'File not found!', 13, 10,'$'
		CALL_ERROR_5    	db 13, 10,'Disk error!', 13, 10,'$'
		
		RESULT_0 		db 13, 10,'Program has ended normally!', 13, 10, '$'
		RESULT_1   		db 13, 10,'Program has ended with Ctrl+C!', 13, 10,'$'
		RESULT_2   		db 13, 10,'Device error end!', 13, 10,'$'
		RESULT_3   		db 13, 10,'Function 31h end!', 13, 10,'$'
		
		PATH 			dw 20 dup(0)
		PARAMS 			dw 7 dup(0)
		MEM_FREE_FLAG 	db 0
		KEEP_SS 		dw 0
		KEEP_SP 		dw 0
DATA 	ENDS


CODE SEGMENT
	ASSUME CS:CODE, DS:DATA, ES:DATA, SS:STACK

	
STACK 	SEGMENT STACK
		DW 		100h DUP (?)
STACK 	ENDS


FREE_MEMORY PROC 	NEAR
		lea 	bx, LAST_BYTE
		mov 	ax, es 
		sub 	bx, ax
		mov 	cl, 4h
		shr 	bx, cl 

		mov 	ah, 4Ah 
		int 	21h
		jnc 	MemoryFound 
		
		mov 	MEM_FREE_FLAG, 1
		cmp 	ax, 7
		lea 	dx, MEMORY_ERROR_7
		je 		FoundError
		cmp 	ax, 8
		lea 	dx, MEMORY_ERROR_8
		je 		FoundError
		cmp 	ax, 9
		lea 	dx, MEMORY_ERROR_9
		
	FoundError:
		call 	WRITE
		xor 	al, al
		mov 	ah, 4Ch
		int 	21H
	MemoryFound:
		ret	
FREE_MEMORY ENDP
;-----------------------------------------------------------
END_OF_PROGRAM 	PROC	NEAR
		mov 	ax, 4d00h
		int 	21h
		cmp 	ah, 01h
		je  	Err1
		cmp 	al, 03h
		je  	Err1
		cmp 	ah, 02h
		je  	Err2
		cmp 	ah, 03h
		je  	Err3
	
		mov 	dx, offset RESULT_0	
		call 	WRITE		
		jmp 	ForExit
	Err1:
		mov 	dx, offset RESULT_1
		call	WRITE
		jmp		ForExit
	Err2:
		mov 	dx, offset RESULT_2
		call	WRITE
		jmp 	ForExit
	Err3:
		mov 	dx, offset RESULT_3
		call	WRITE

	ForExit:
		ret	
END_OF_PROGRAM 	ENDP
;-----------------------------------------------------------
WRITE	PROC	NEAR
		push 	ax
		mov		ah, 09h
		int		21h
		pop		ax
		ret
WRITE	ENDP
;-----------------------------------------------------------
CREATE_ENV PROC		;заполнение блока параметров
		push 	ax
		mov 	ax, es
		mov 	PARAMS, 0
		mov 	PARAMS + 2, 80h
		mov 	PARAMS + 4, ax
		mov 	PARAMS + 6, 5Ch  
		mov 	PARAMS + 8, ax
		mov 	PARAMS + 10, 6Ch 
		mov 	PARAMS + 12, ax
		pop 	ax
		ret
CREATE_ENV ENDP
;-----------------------------------------------------------
MAIN 	PROC	NEAR
		mov 	ax, DATA
		mov 	ds, ax
		
		push 	si
		push 	di
		push 	es
		push 	dx
		
		mov 	es, es:[2Ch]
		xor 	si, si
		mov 	di, offset PATH	
	FindChar: 
		cmp 	byte ptr es:[si], 00h
		je 		Skip
		inc 	SI
		jmp 	CheckPath	
	Skip:   
		inc 	si	
	CheckPath:       
		cmp 	word ptr es:[si], 0000h
		jne 	FindChar
		add 	si, 4	
	Getch:
		cmp 	byte ptr es:[si], 00h
		je 		GoBack
		mov 	dl, es:[si]
		mov 	[di], dl
		inc 	si
		inc 	di
		jmp 	Getch	
	GoBack:
		cmp 	byte ptr [di], 5ch
		je  	AddFileName
		dec 	di
		jmp 	GoBack	
	AddFileName:
		inc 	di
		mov 	dl, 'l'
		mov 	[di], dl
		
		inc 	di
		mov 	dl, 'a'
		mov 	[di], dl
		
		inc 	di
		mov 	dl, 'b'
		mov 	[di], dl
		
		inc 	di
		mov 	dl, '_'
		mov 	[di], dl
		
		inc 	di
		mov 	dl, '2'
		mov 	[di], dl
		
		inc 	di
		mov 	dl, '.'
		mov 	[di], dl
		
		inc 	di
		mov 	dl, 'c'
		mov 	[di], dl
		
		inc 	di
		mov 	dl, 'o'
		mov 	[di], dl
		
		inc 	di
		mov 	dl, 'm'
		mov 	[di], dl
		
		inc 	di
		mov 	dl, 0h
		mov 	[di], dl
		
		inc 	di
		mov 	dl, '$'
		mov 	[di], dl
		
		pop 	dx
		pop 	es
		pop 	di
		pop 	si
		
		call 	FREE_MEMORY
		cmp 	MEM_FREE_FLAG, 0
		jne 	Exit
		
		
		push 	ds
		pop 	es
		call 	CREATE_ENV
		mov 	dx, offset PATH
		mov 	bx, offset PARAMS
		
		mov 	KEEP_SS, ss
		mov 	KEEP_SP, sp
		
		mov 	ax, 4b00h
		int 	21h
		
		mov 	ss, KEEP_SS
		mov 	sp, KEEP_SP	
		
		
		jc 		NotLoaded
		jmp 	LoadingSuccess
	NotLoaded:
		lea 	dx, CALL_ERROR_1
		cmp 	ax, 1
		je 		DisplayError
		
		lea 	dx, CALL_ERROR_2
		cmp 	ax, 2		
		je 		DisplayError
		
		lea 	dx, CALL_ERROR_5
		cmp 	ax, 5		
		je 		DisplayError
			
	DisplayError:
		call	WRITE
		lea 	dx, PATH
		call 	WRITE
		jmp 	Exit	
	LoadingSuccess:
		call 	END_OF_PROGRAM	
	Exit:
		mov 	ah, 4ch
		int 	21h	
MAIN 	ENDP

LAST_BYTE:

CODE 	ENDS
		END MAIN