ASTACK SEGMENT STACK
	DW 64 DUP (?)
ASTACK ENDS
;====================================================
DATA SEGMENT
	BlockParam dw ? ;сегментный адрес среды
	dd ? ;сегмент и смещение командной строки
	dd ? ;сегмент и смещение первого FCB
	dd ? ;сегмент и смещение второго FCB
	ErMem7     DB 10,13,'MCB destroyed',10,13,'$'
	ErMem8     DB 10,13,'Not enough memory for processing',10,13,'$'
	ErMem9     DB 10,13,'Wrong address',10,13,'$'
	ErCall1    DB 10,13,'Wrong number of function',10,13,'$'
	ErCall2    DB 10,13,'File not found',10,13,'$'
	ErCall5    DB 10,13,'Disk error',10,13,'$'
	Ercall8    DB 10,13,'Not enough memory',10,13,'$'
	ErCall10   DB 10,13,'Incorrect environment string',10,13,'$'
	ErCall11   DB 10,13,'Wrong format',10,13,'$'
	ResEnd0    DB 10,13,'Normal end',10,13,'$'
	ResEnd1    DB 10,13,'Ctrl-Break end',10,13,'$'
	ResEnd2    DB 10,13,'Device error end!',10,13,'$'
	ResEnd3    DB 10,13,'Function 31h end!',10,13,'$'
	Path 	   DB 50 dup(0)
	KeepSS     DW 0
	KeepSP     DW 0
DATA ENDS
;====================================================
CODE SEGMENT
	ASSUME CS:CODE, DS:DATA, ES:DATA, SS:ASTACK
	jmp MAIN
;----------------------------------------------------
PRINT_STR PROC NEAR
	push 	AX
	mov 	AH, 09h
	int 	21h
	pop 	AX
	ret
PRINT_STR ENDP
;----------------------------------------------------
FREE_MEMORY PROC 
	lea BX,MemSize
	mov AH,4AH 
	int 21h
	jnc EndFreeMem

	cmp 	AX,7
	lea 	DX, ErMem7
	je 		ErMemFound
	cmp 	AX,8
	lea 	DX, ErMem8
	je 		ErMemFound
	cmp 	AX,9
	lea 	DX, ErMem9
		
ErMemFound:
	call 	PRINT_STR
	xor 	AL,AL
	mov 	AH,4Ch
	int 	21H
EndFreeMem:
	ret
FREE_MEMORY ENDP
;----------------------------------------------------
;вызов загрузчика OS
CREATE_BLOCK_PARAM PROC
	mov	AX, ES
	mov BlockParam,0
	mov BlockParam+2, 80h
	mov BlockParam+4, AX
	mov BlockParam+6, 5Ch  
	mov BlockParam+8, AX
	mov BlockParam+10, 6Ch 
	mov BlockParam+12, AX
	ret
CREATE_BLOCK_PARAM ENDP
;----------------------------------------------------
CALL_L2 PROC
	lea DX, Path
	push DS
	pop ES 
	lea BX, BlockParam

	mov KeepSP, SP
	mov KeepSS, SS

	mov 	AX,4B00h
	int 	21h
	jnc 	NoErrcall 

	push 	AX
	mov 	AX,DATA
	mov 	DS,AX
	pop 	AX
	mov 	SS,KeepSS
	mov 	SP,KeepSP
	
	cmp 	AX,1
	lea 	DX, ErCall1
	je 		ErcallFound
	cmp 	AX,2
	lea 	DX, ErCall2
	je 		ErcallFound
	cmp 	AX,5
	lea 	DX, ErCall5
	je 		ErcallFound
	cmp 	AX,8 
	lea 	DX, Ercall8
	je 		ErcallFound
	cmp 	AX,10 
	lea 	DX, ErCall10
	je 		ErcallFound
	cmp 	AX,11 
	lea 	DX, ErCall11
	
ErcallFound:
	call 	PRINT_STR
	xor 	AL,AL
	mov 	AH,4Ch
	int 	21h
		
NoErrcall:
	mov 	AX,4d00h
	int 	21h

	cmp 	AH,0
	lea 	DX, ResEnd0
	je 		Exit
	cmp 	AH,1
	lea 	DX, ResEnd1
	je 		Exit
	cmp 	AH,2
	lea 	DX, ResEnd2
	je 		Exit
	cmp 	AH,3
	lea 	DX, ResEnd3

Exit:
	call 	PRINT_STR
	ret
CALL_L2 ENDP
;----------------------------------------------------
MAIN:
	mov 	AX,DATA
	mov		DS, AX
	call 	FREE_MEMORY 
	call 	CREATE_BLOCK_PARAM
	mov es, es:[2Ch]
	mov si, 0
Env:
	mov dl, es:[si]
	cmp dl, 00h
	je EOL_	
	inc si
	jmp Env
EOL_:
	inc si
	mov dl, es:[si]
	cmp dl, 00h
	jne Env
	
	add si, 03h
	push di
	lea di, PATH
FileName:
	mov dl, es:[si]
	cmp dl, 00h
	je EndFN	
	mov [di], dl	
	inc di			
	inc si			
	jmp FileName
EndFN:
	sub di, 6
	mov 	[DI], '2L'
	add 	DI, 2
	mov 	[DI], 'OM'
	add 	DI, 2
	mov 	[DI], '.D'
	add 	DI, 2
	mov 	[DI], 'OC'
	add 	DI, 2
	mov 	[DI], '$M'
	add		DI, 2
	pop 	DI
	call 	CALL_L2
	xor 	AL,AL
	mov 	AH,4Ch
	int 	21h
MemSize:
CODE ENDS
END MAIN