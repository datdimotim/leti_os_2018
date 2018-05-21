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
FREE_MEM PROC
		mov ax,STACK
		mov bx,es
		sub ax,bx 
		add ax,10h 
		mov bx,ax
		mov ah,4Ah
		int 21h
		jnc FREE_MEM_FINISH
	
		mov dx,offset STR_ERR_FREE_MEM
		call PRINT
		cmp ax,7
		mov dx,offset STR_ERR_MCB_DSTR
		je FREE_MEM_PRINT
		cmp ax,8
		mov dx,offset STR_ERR_NOT_ENGH_MEM
		je FREE_MEM_PRINT
		cmp ax,9
		mov dx,offset STR_ERR_MEM_ADR
		
FREE_MEM_PRINT:
		call PRINT
		mov dx,offset ENDL
		call PRINT
	
		xor AL,AL
		mov AH,4Ch
		int 21H
FREE_MEM_FINISH:
		ret
FREE_MEM ENDP
;--------------------------
PARMS_CREATE PROC
		mov ax, es:[2Ch]
		mov PARMS,ax 
		mov PARMS+2,es 
		mov PARMS+4,80h
		ret
PARMS_CREATE ENDP
;--------------------------
RUN_MODULE PROC
		mov dx,offset ENDL
		call PRINT
		mov dx,offset SET_MODULE_PATH
		xor ch,ch
		mov cl,es:[80h]
		cmp cx,0
		je RUN_MODULE_NO_TAIL
		mov si,cx
		push si 
RUN_MODULE_LOOP:
		mov al,es:[81h+si]
		mov [offset MODULE_PATH+si-1],al			
		dec si
		loop RUN_MODULE_LOOP
		pop si
		mov [MODULE_PATH+si-1],0 
		mov dx,offset MODULE_PATH 
RUN_MODULE_NO_TAIL:
		push ds
		pop es
		mov bx,offset PARMS
		mov KEEP_SP, SP
		mov KEEP_SS, SS
		mov ax,4b00h
		int 21h
		jnc RUN_MODULE_FINISH
		push ax
		mov ax,DATA
		mov ds,ax
		pop ax
		mov SS,KEEP_SS
		mov SP,KEEP_SP
		cmp ax,1
		mov dx,offset STR_ERR_FNCT_NMBR
		je RUN_MODULE_PRINT
		cmp ax,2
		mov dx,offset STR_ERR_FILE
		je RUN_MODULE_PRINT
		cmp ax,5
		mov dx,offset STR_ERR_DISK
		je RUN_MODULE_PRINT
		cmp ax,8
		mov dx,offset STR_ERR_NOT_ENGH_MEM_
		je RUN_MODULE_PRINT
		cmp ax,10
		mov dx,offset STR_ERR_ENV
		je RUN_MODULE_PRINT
		cmp ax,11
		mov dx,offset STR_ERR_FORM
RUN_MODULE_PRINT:
		call PRINT
		mov dx,offset ENDL
		call PRINT
		xor AL,AL
		mov AH,4Ch
		int 21H
RUN_MODULE_FINISH:
		mov dx,offset ENDL
		call PRINT
		mov ax,4d00h
		int 21h
		cmp ah,0
		mov dx,offset STR_END_NRML
		je RUN_MODULE_PRINT_END
		cmp ah,1
		mov dx,offset STR_END_CTRL_BREAK
		je RUN_MODULE_PRINT_END
		cmp ah,2
		mov dx,offset STR_END_DEVICE_ERR
		je RUN_MODULE_PRINT_END
		cmp ah,3
		mov dx,offset STR_END_RES
RUN_MODULE_PRINT_END:
		call PRINT
		mov dx,offset ENDL
		call PRINT
		mov dx,offset STR_END_CODE
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
		mov dx,offset ENDL
		call PRINT
	ret
RUN_MODULE ENDP
;--------------------------
BEGIN:
	mov ax,DATA
	mov ds,ax
	call FREE_MEM
	call PARMS_CREATE
	call RUN_MODULE
	xor AL,AL
	mov AH,4Ch
	int 21H
CODE ENDS
;--------------------------
DATA SEGMENT
	STR_ERR_FREE_MEM	 		db 'Error of freeing memory: $'
	STR_ERR_MCB_DSTR 			db 'MCB is destroyed$'
	STR_ERR_NOT_ENGH_MEM 		db 'Memory error$'
	STR_ERR_MEM_ADR 			db 'Wrong memory address$'
	STR_ERR_FNCT_NMBR			db 'Wrong function number$'
	STR_ERR_FILE				db 'File is not found$'
	STR_ERR_DISK				db 'Wrong disk$'
	STR_ERR_NOT_ENGH_MEM_		db 'Not enough memory$'
	STR_ERR_ENV					db 'Wrong environment$'
	STR_ERR_FORM				db 'Wrong format$'
	STR_END_NRML				db 'Normal ending$'
	STR_END_CTRL_BREAK			db 'Ended by Ctrl-Break$'
	STR_END_DEVICE_ERR			db 'Ended by device error$'
	STR_END_RES					db 'Ended by 31h function$'
	STR_END_CODE				db 'Code of ending: $'
	ENDL 						db 0DH,0AH,'$'
	PARMS 						dw 0 
								dd ? 
								dd 0 
								dd 0  
	MODULE_PATH  				db 50h dup ('$')
	SET_MODULE_PATH				db 'LAB2_M.COM',0
	KEEP_SS 					dw 0
	KEEP_SP 					dw 0
DATA ENDS
;--------------------------
STACK SEGMENT STACK
	dw 64h dup (?)
STACK ENDS
 END START