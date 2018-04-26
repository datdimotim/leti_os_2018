OSEG segment
	ASSUME CS:OSEG,DS:OSEG
	push ds
	mov ax,cs
	mov ds,ax
	mov di,offset PRTSTR+3
	CALL WRD_TO_HEX
	lea dx,PRTSTRINFO
	mov ax,0900h
	int 21h
	pop ds
	retf
	;---------------------------------------
	TETR_TO_HEX PROC near
		and AL,0Fh
		cmp AL,09
		jbe NEXT
		add AL,07
	NEXT: add AL,30h
		ret
	TETR_TO_HEX ENDP
	;---------------------------------------
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
	;---------------------------------------
	; перевод в 16с/с 16-ти разрядного числа
	; в AX - число, DI - адрес последнего символа
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
	PRTSTRINFO 	DB 'Segment address of an overlay: '
	PRTSTR 		DB '    ',0DH,0AH,'$'
OSEG ENDS
END
