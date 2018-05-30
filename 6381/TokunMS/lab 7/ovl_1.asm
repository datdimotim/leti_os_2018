OVL1 SEGMENT
	ASSUME CS:OVL1, DS:nothing, SS:nothing, ES:nothing

MAIN PROC FAR
	push DS
	push AX
	push DI
	push DX
	push BX
	
	mov DS, AX	
	lea BX, Adr
	add BX, 25			
	mov DI, BX			
	mov AX, CS			
	call WRD_TO_HEX
	lea DX, Adr	
	call WRITE	
	
	pop BX
	pop DX
	pop DI
	pop AX
	pop DS
	retf
MAIN ENDP
;----------------------------------------------------------------------
Adr 	db 	0DH, 0AH,'Its segment adress:              ', 0DH, 0AH, '$'
;----------------------------------------------------------------------
WRITE	PROC
	push AX
	mov AH, 09h
	int 21h
	pop AX
	ret
WRITE	ENDP
;----------------------------------------------------------------------
TETR_TO_HEX PROC near
	and AL,0Fh 
	cmp AL,09 
	jbe NEXT 
	add AL,07 
NEXT: 
	add AL,30h 
	ret 
TETR_TO_HEX ENDP 
;-----------------------------------------------------------
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
;-----------------------------------------------------------
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

OVL1 ENDS
END MAIN