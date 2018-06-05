ASSUME CS:OVL2,DS:OVL2,SS:NOTHING,ES:NOTHING
OVL2 SEGMENT
;---------------------------------------------------------------
MAIN2 PROC FAR 
	push ds
	push dx
	push di
	push ax
	mov ax,cs
	mov ds,ax
	mov bx, offset ForPrint
	add bx, 47h			
	mov di, bx		
	mov ax, cs			
	call WRD_TO_HEX
	mov dx, offset ForPrint	
	call PRINT
	pop ax
	pop di
	pop dx	
	pop ds
	retf
MAIN2 ENDP
;---------------------------------------------------------------
PRINT PROC NEAR ;������ �� ����� 
	push ax
	mov ah, 09h
	int 21h
	pop ax
	ret
PRINT ENDP
;--------------------------------------------------------------------------------
TETR_TO_HEX		PROC near ;�������� ���� AL ����������� � ������ ������������������ ����� � AL
		and		al, 0Fh ;and 00001111 - ��������� ������ ������ �������� al
		cmp		al, 09 ;���� ������ 9, �� ���� ���������� � �����
		jbe		NEXT ;��������� �������� �������, ���� ������ ������� ������ ��� ����� ������� ��������
		add		al, 07 ;��������� ��� �� �����
	NEXT:	add		al, 30h ;16-������ ��� ����� ��� ����� � al
		ret
TETR_TO_HEX		ENDP
;--------------------------------------------------------------------------------
BYTE_TO_HEX		PROC near ;���� AL ����������� � ��� ������� ������������������ ����� � AX
		push	cx
		mov		ah, al ;�������� al � ah
		call	TETR_TO_HEX ;��������� al � ������ 16-���.
		xchg	al, ah ;������ ������� al �  ah
		mov		cl, 4 
		shr		al, cl ;c���� ���� ����� al ������ �� 4
		call	TETR_TO_HEX ;��������� al � ������ 16-���.
		pop		cx 			
		ret
BYTE_TO_HEX		ENDP
;--------------------------------------------------------------------------------
WRD_TO_HEX		PROC	near ;������� AX ����������� � ����������������� �������, DI - ����� ���������� �������
		push	bx
		mov		bh, ah ;�������� ah � bh, �.�. ah ���������� ��� ��������
		call	BYTE_TO_HEX ;��������� al � ��� ������� ������������������ ����� � AX
		mov		[di], ah ;��������� ����������� �������� ah �� ������, �������� � �������� DI
		dec		di 
		mov		[di], al ;��������� ����������� �������� al �� ������, �������� � �������� DI
		dec		di
		mov		al, bh ;�������� bh � al, ��������������� �������� ah
		xor		ah, ah ;������� ah
		call	BYTE_TO_HEX ;��������� al � ��� ������� ������������������ ����� � AX
		mov		[di], ah ;��������� ����������� �������� al �� ������, �������� � �������� DI
		dec		di
		mov		[di], al ;��������� ����������� �������� al �� ������, �������� � �������� DI
		pop		bx
		ret
WRD_TO_HEX		ENDP
;--------------------------------------------------------------------------------
ForPrint  DB 0DH,0AH, 'The address of the segment to which the second overlay is loaded:                 ',0DH,0AH,'$'
;--------------------------------------------------------------------------------
OVL2 ENDS
END