STACK SEGMENT STACK
	DW 100 DUP (?)
STACK ENDS
;---------------------------------------------------------------
DATA SEGMENT
	wasloaded DB 'Interruption had been set earlier!',0DH,0AH,'$'
	unloaded DB 'Interruption has been unloaded!',0DH,0AH,'$'
	loading DB 'Interruption has been set!',0DH,0AH,'$'
DATA ENDS
;---------------------------------------------------------------
CODE SEGMENT
	ASSUME CS:CODE, DS:DATA, ES:DATA, SS:STACK
START: JMP BEGIN
;---------------------------------------------------------------
PRINT PROC NEAR ; interrupt handler
	push ax
	mov ah, 09h
	int 21h
	pop ax
	ret
PRINT ENDP
;---------------------------------------------------------------
ROUT PROC FAR
	jmp ROUT_
_DATA:
	STACK_ DW 64 DUP (?)
	SIGN DB '0000'
	KEEP_IP DW 0
	KEEP_CS DW 0
	KEEP_PSP DW 0 
	KEEP_SS DW 0
	KEEP_AX DW 0	
	KEEP_SP DW 0 
	
ROUT_:
	mov KEEP_SS, ss
	mov KEEP_AX, ax
	mov KEEP_SP, sp
	mov ax, seg STACK_
	mov ss, ax
	mov sp, 0
	mov ax, KEEP_AX

	push ax
	push dx
	push ds
	push es
	
	in al, 60H 
	cmp al, 29h 
	je DO_REQ 
	
	pushf
	call dword ptr CS:KEEP_IP
	jmp ROUT_END
	
DO_REQ:
	push ax
	in al, 61h 
	mov ah, al 
	or al, 80h 
	out 61h, al 
	xchg ah, al 
	out 61h, al 
	mov al, 20h 
	out 20h, al 
	pop ax
	
ADDSYMB: 
	mov ah, 05h 
	mov cl, '_'
	mov ch, 00h	
	int 16h
	or al, al 
	jz ROUT_END
	CLI 
	mov ax,es:[1Ah]
	mov es:[1Ch],ax
	STI
	jmp ADDSYMB

ROUT_END:
	pop es
	pop ds
	pop dx
	pop ax 
	mov AX, KEEP_SS
	mov SS, AX
	mov SP,KEEP_SP
	mov AX,KEEP_AX
	iret
ROUT ENDP
;---------------------------------------------------------------	
CHECKING PROC ; checking of interruption
	mov ah,35h 
	mov al,09h 
	int 21h
	mov si, offset SIGN 
	sub si, offset ROUT
	
	mov ax,'00'
	cmp ax,es:[bx+si]
	jne UNLOAD
	cmp ax,es:[bx+si+2] 
	je LOAD
	
UNLOAD:
	call SET_INTERRUPT
	mov dx,offset LAST_BYTE
	mov cl,4
	shr dx,cl
	inc dx
	add dx,CODE
	sub dx,CS:KEEP_PSP
	xor al,al
	mov ah,31h
	int 21h 
	
LOAD: 
	push es
	push ax
	mov ax,KEEP_PSP 
	mov es,ax
	cmp byte ptr es:[82h],'/' 
	jne BACK
	cmp byte ptr es:[83h],'u' 
	jne BACK
	cmp byte ptr es:[84h],'n'
	je UNLOAD_

BACK:
	pop ax
	pop es
	mov dx,offset wasloaded
	call PRINT
	ret

UNLOAD_:
	pop ax
	pop es
	call DELETE_INTERRUPT
	mov dx,offset unloaded
	call PRINT
	ret
CHECKING endp
;---------------------------------------------------------------
SET_INTERRUPT PROC ; adding a new interruption
	push dx
	push ds

	mov ah,35h
	mov al,09h
	int 21h
	mov CS:KEEP_IP,bx 
	mov CS:KEEP_CS,es

	mov dx,offset ROUT
	mov ax,seg ROUT
	mov ds,ax
	mov ah,25h
	mov al,09h
	int 21h

	pop ds
	mov dx,offset loading
	call PRINT
	pop dx
	ret
SET_INTERRUPT ENDP
;---------------------------------------------------------------
DELETE_INTERRUPT PROC ;delete an interrupt
	push ds
	CLI
	mov dx,ES:[BX+SI+4]
	mov ax,ES:[BX+SI+6]
	mov ds,ax	
	mov ax,2509h
	int 21h 
	push es
	mov ax,ES:[BX+SI+8] 
	mov es,ax 
	mov es,es:[2Ch]
	mov ah,49h         
	int 21h
	pop es
	mov es,ES:[BX+SI+8]
	mov ah, 49h
	int 21h	
	STI
	pop ds
	ret
DELETE_INTERRUPT ENDP 
;---------------------------------------------------------------
BEGIN:
	mov AX,DATA
	mov DS,AX
	mov KEEP_PSP,ES
	call CHECKING
	xor AL,AL
	mov AH,4Ch
	int 21H
LAST_BYTE:
	CODE ENDS	
	END START