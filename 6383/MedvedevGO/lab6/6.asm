CODE SEGMENT
 ASSUME CS:CODE, DS:DATA, ES:DATA, SS:STACK
START: JMP BEGIN
;--------------------------
PRINT PROC near
	mov AH,09h
	int 21h
	ret
PRINT ENDP
;--------------------------
TETR_TO_HEX		PROC	near
		and		al,0fh
		cmp		al,09
		jbe		NEXT
		add		al,07
NEXT:	add		al,30h
		ret
TETR_TO_HEX		ENDP
;--------------------------
BYTE_TO_HEX		PROC near
		push	cx
		mov		ah,al
		call	TETR_TO_HEX
		xchg	al,ah
		mov		cl,4
		shr		al,cl
		call	TETR_TO_HEX ; 
		pop		cx 			
		ret
BYTE_TO_HEX		ENDP
;--------------------------
MEMORY_ PROC
		mov ax,STACK
		mov bx,es
		sub ax,bx 
		add ax,10h 
		mov bx,ax
		mov ah,4Ah
		int 21h
		jnc FIN
	
		mov dx,offset ERRMEM
		call PRINT
		cmp ax,7
		mov dx,offset MCB_
		je MEM_PRINT
		cmp ax,8
		mov dx,offset NOTMEM
		je MEM_PRINT
		cmp ax,9
		mov dx,offset ERRADR
		
		MEM_PRINT:
		call PRINT
		mov dx,offset STRING
		call PRINT
	
		xor AL,AL
		mov AH,4Ch
		int 21H
	FIN:
	ret
MEMORY_ ENDP
;--------------------------
PAR_BL PROC
	mov ax, es:[2Ch]
	mov PARAM_S,ax 
	mov PARAM_S+2,es 
	mov PARAM_S+4,80h
	ret
PAR_BL ENDP
;--------------------------
DEAL PROC
	mov dx,offset STRING
	call PRINT
		mov dx,offset STD_PATH
		xor ch,ch
		mov cl,es:[80h]
		cmp cx,0
		je UNTAIL
		mov si,cx
		push si 
			METOCHKA:
				mov al,es:[81h+si]
				mov [offset _PATH+si-1],al			
				dec si
		loop METOCHKA
		pop si
		mov [_PATH+si-1],0 
		mov dx,offset _PATH 
		UNTAIL:
		push ds
		pop es
		mov bx,offset PARAM_S
		mov KEEP_SP, SP
		mov KEEP_SS, SS
		mov ax,4b00h
		int 21h
		jnc FIN_
		push ax
		mov ax,DATA
		mov ds,ax
		pop ax
		mov SS,KEEP_SS
		mov SP,KEEP_SP
		cmp ax,1
		mov dx,offset ERRFUNCT
		je DEAL_PRINT
		cmp ax,2
		mov dx,offset ERRFILE
		je DEAL_PRINT
		cmp ax,5
		mov dx,offset ERRDISK
		je DEAL_PRINT
		cmp ax,8
		mov dx,offset NOTMEM_
		je DEAL_PRINT
		cmp ax,10
		mov dx,offset ERRENV
		je DEAL_PRINT
		cmp ax,11
		mov dx,offset ERRFORM
		DEAL_PRINT:
		call PRINT
		mov dx,offset STRING
		call PRINT
		xor AL,AL
		mov AH,4Ch
		int 21H
	FIN_:
		mov dx,offset STRING
		call PRINT
		mov ax,4d00h
		int 21h
		cmp ah,0
		mov dx,offset GOOD
		je REASONS
		cmp ah,1
		mov dx,offset END_CTRL
		je REASONS
		cmp ah,2
		mov dx,offset ERRDEVICE
		je REASONS
		cmp ah,3
		mov dx,offset ERRRES
		REASONS:
			call PRINT
			mov dx,offset STRING
			call PRINT
		mov dx,offset CODEELEM
		call PRINT
		call BYTE_TO_HEX
		push ax
		mov ah,02h
		mov dl,al
		int 21h
		pop ax
		xchg ah,al
		mov ah,02h
		mov dl,al
		int 21h
		mov dx,offset STRING
		call PRINT
	ret
DEAL ENDP
;--------------------------
BEGIN:
	mov ax,DATA
	mov ds,ax
	call MEMORY_
	call PAR_BL
	call DEAL
	xor AL,AL
	mov AH,4Ch
	int 21H
CODE ENDS
;--------------------------
DATA SEGMENT
	ERRMEM	 		db 'Error of clear memory: $'
	MCB_ 			db 'MCB is destroyed$'
	NOTMEM 			db 'Not enough memory$'
	ERRADR 			db 'Error of the addres$'
	ERRFUNCT		db 'Error of function number$'
	ERRFILE			db 'Error of the file$'
	ERRDISK			db 'Error of the disk$'
	NOTMEM_			db 'Not enough memory$'
	ERRENV			db 'Error of env$'
	ERRFORM			db 'Error of format$'
	GOOD			db 'All is good$'
	END_CTRL		db 'End ctrl$'
	ERRDEVICE		db 'Error of device$'
	ERRRES			db 'End 31h$'
	CODEELEM		db 'Code of finish: $'
	STRING 			db 0DH,0AH,'$'
	PARAM_S 		dw 0 
					dd ? 
					dd 0 
					dd 0  
	_PATH  			db 50h dup ('$')
	STD_PATH		db '2.COM',0
	KEEP_SS 		dw 0
	KEEP_SP 		dw 0
DATA ENDS
;--------------------------
STACK SEGMENT STACK
	dw 64h dup (?)
STACK ENDS
 END START