CODE segment
	ASSUME CS:CODE, DS:CODE
    START:
	push ds
    push cs
    pop ds
	mov di,offset ADDR_STRING+39
    mov ax, cs
	CALL WRD_TO_HEX
	mov dx, offset ADDR_STRING 
	mov ah,09h
	int 21h
	pop ds
	retf
	
	TETR_TO_HEX PROC near
		and AL,0Fh
		cmp AL,09
		jbe NEXT
		add AL,07
	NEXT: add AL,30h
		ret
	TETR_TO_HEX ENDP
	
	BYTE_TO_HEX PROC near
		push CX
		mov AH,AL
		call TETR_TO_HEX
		xchg AL,AH
		mov CL,4
		shr AL,CL
		call TETR_TO_HEX
		pop CX
		ret
	BYTE_TO_HEX ENDP
	
	WRD_TO_HEX PROC near
		push BX
		mov BH,AH
		call BYTE_TO_HEX
		mov [DI],AH
		dec DI
		mov [DI],AL
		dec DI
		mov AL,BH
		call BYTE_TO_HEX
		mov [DI],AH
		dec DI
		mov [DI],AL
		pop BX
		ret
	WRD_TO_HEX ENDP
	ADDR_STRING 	DB 'First ovl: Segment address of CODE:     ',0DH,0AH,'$'
CODE ENDS
END START
