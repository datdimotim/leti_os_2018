CODE SEGMENT
 ASSUME CS:CODE, DS:DATA, ES:DATA, SS:ASTACK

RStack db 64 dup (0) 

MY_INT	PROC	FAR              ;Пользовательское прерывание
	
		jmp IntCode
	IntData:
		SIGNATURE	db '999999'
		KEEP_IP 	dw 0
		KEEP_CS 	dw 0		
		KEEP_ES 	dw 0
		KEEP_SP  	dw 0
		KEEP_SS  	dw 0
	IntCode:
	
		mov		KEEP_SP, sp
		mov 	KEEP_SS, ss
		mov		dx, cs
		mov 	ss, dx
		mov		sp, 40h
		
		push	ax
		push	dx
		push	ds
		push	es
	
		in 		al, 60h
		cmp 	al, 18 ; клавиша 'e'
		je 		DoReq
		pushf
		call 	dword ptr CS:[KEEP_IP]
		jmp 	IntEndp
	DoReq:
		mov 	ax, 0040h
		mov 	es, ax
		in 		al, 61h
		mov 	ah, al
		or 		al, 80h
		out 	61h, al
		xchg 	ah, al
		out 	61h, al

	Run:
		mov 	ah, 05h
		mov 	cl, 'R'
		mov 	ch, 00h
		int 	16h
		or 		al,  al
		je 		IntEndp
		CLI
		mov 	ax, es:[1Ah]
		mov 	es:[1Ch],ax
		STI
		jmp Run	
				
	IntEndp:
		pop 	es 
		pop 	ds
		pop 	dx
		pop 	ax
		mov 	sp, KEEP_SP
		mov 	ss, KEEP_SS
		mov 	al, 20h
		out 	20h, al
		iret
		
MY_INT 	ENDP
;-----------------------------------------------------------
CHECK	PROC                     ; Проверяет установлено ли пользовательское прерывание и задан ли параметр /un 
		mov 	KEEP_ES, es 	
		mov 	ah, 35h
		mov 	al, 09h
		int		21h
		lea 	si, SIGNATURE
		sub 	si, offset MY_INT
		
		;проверка ключа
		mov 	ax, '99'
		cmp 	ax, es:[bx + si]
		jne 	NotCustom
		cmp 	ax, es:[bx + si + 2]
		jne 	NotCustom
		cmp		ax, es:[bx + si + 4]
		jne		NotCustom
		jmp 	AlreadySet
		
	NotCustom: 
		call 	SET_MY_INT 
		lea 	dx, Last_byte
		mov 	cl, 4 
		shr 	dx, cl
		inc 	dx	
		add 	dx, CODE 
		sub 	dx, KEEP_ES 
		xor 	al, al
		mov 	ah, 31h 
		int 	21h 
		
	AlreadySet: 
		push 	es
		push 	ax
		mov 	ax, KEEP_ES 
		mov 	es, ax
		;проверка параметра /un 
		cmp 	byte ptr es:[82h], '/' 
		jne 	NotUnloaded
		cmp 	byte ptr es:[83h], 'u' 
		jne 	NotUnloaded 
		cmp 	byte ptr es:[84h], 'n' 
		jne 	NotUnloaded 
		
		pop 	ax
		pop 	es
		call 	SET_DEFAULT_INT
		lea 	dx, UNLOADED
		call 	Write
		ret
	NotUnloaded: 
		pop 	ax
		pop 	es
		lea 	dx, LOADED_BEFORE
		call 	WRITE
		ret	
		
CHECK	ENDP
;-----------------------------------------------------------
SET_MY_INT PROC                  ; Устанавливает пользовательское прерывание	
		push 	dx
		push	ds
		mov 	ah, 35h
		mov 	al, 09h
		int		21h
		mov 	KEEP_CS, es
		mov		KEEP_IP, bx
		lea		dx, MY_INT
		mov		ax, seg MY_INT
		mov 	ds, ax
		mov 	ah, 25h
		mov 	al, 09h
		int		21h	
		pop		ds
		lea 	dx, LOADED
		call 	WRITE
		pop		dx
		ret
SET_MY_INT ENDP
;-----------------------------------------------------------
WRITE	PROC 	NEAR             ; Вывод сообщения, записанного в dx	
		push	ax
		mov		ah, 09h
		int 	21h
		pop 	ax
		ret
WRITE	ENDP
;-----------------------------------------------------------
SET_DEFAULT_INT		PROC NEAR        ; Восстановить исходное прерывание	
		CLI 
		push 	ds
		mov 	dx, es:[bx + si + 6]
		mov 	ax, es:[bx + si + 8]
		mov 	ds, AX 
		mov 	ah, 25h 
		mov 	al, 09h
		int 	21h 
		mov		es, es:[bx + si + 10]
		mov 	es, ES:[2Ch] 
		mov 	ah, 49h 
		int 	21h 
		mov		es, es:[bx + si + 10]
		mov 	ah, 49h
		int 	21h
		pop 	ds
		STI
		ret
SET_DEFAULT_INT		ENDP



ASTACK SEGMENT STACK
		DW 512 DUP (?)
ASTACK ENDS

DATA	SEGMENT
		LOADED  		db 'Custom interruption has been loaded!',0dh,0ah,'$'
		UNLOADED  		db 'Custom interruption has been unloaded!',0dh,0ah,'$'
		LOADED_BEFORE 	db 'Custom interruption has already been loaded!',0dh,0ah,'$'
DATA	ENDS

MAIN	PROC	FAR
		push 	ds
		sub 	ax, ax
		push 	ax
		mov 	ax, DATA
		mov 	ds, ax
		
		call 	CHECK 
		sub 	al, al
		mov 	ah, 4ch 
		int 	21h
		ret
	Last_byte:
MAIN 	ENDP
CODE 	ENDS
		END MAIN