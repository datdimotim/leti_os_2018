.286
CODE	SEGMENT
	ASSUME CS:CODE, DS:CODE, SS:NOTHING
	ORG 100h
BEGIN:
	pusha
	push DS
	
	mov  AX, CS
	mov  DS, AX
	
	mov  DI, offset STRING + 37
	call WRD_TO_HEX
	
	mov  AH, 09h
	mov  DX, offset STRING
	int  21h
	
		
	pop  DS
	popa
	retf
	
TETR_TO_HEX		PROC near
		and  AL, 0Fh
		cmp  AL, 09h
		jbe  NEXT
		
		add  AL, 07h
NEXT:	add  AL, 30h
		ret
TETR_TO_HEX		ENDP
;--------------------;

; AL ---> AX
BYTE_TO_HEX		PROC near
		push CX
		
		mov  AH, AL
		call TETR_TO_HEX
		xchg AL, AH
		mov  CL, 04h
		shr  AL, CL
		call TETR_TO_HEX
						
		pop CX
		ret
BYTE_TO_HEX		ENDP
;------------------------;

;DI
WRD_TO_HEX		PROC near
		push BX
		
		mov  BH, AH
		call BYTE_TO_HEX
		mov  [DI], AH
		dec  DI
		mov  [DI], AL
		dec  DI
		mov  AL, BH
		call BYTE_TO_HEX
		mov  [DI], AH
		dec  DI
		mov  [DI], AL
		
		pop  BX
		ret
WRD_TO_HEX		ENDP
;-------------------------------;
	

	nop
	STRING	db	'Overlay module 2. Segment addres: !!!!', 0Ah, '$'
CODE	ENDS
END	BEGIN