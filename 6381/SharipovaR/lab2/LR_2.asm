TESTPC	SEGMENT
		ASSUME	CS:TESTPC,	DS:TESTPC,	ES:NOTHING,	SS:NOTHING
		ORG		100H
START:	JMP		BEGIN

; ������
ADD_N			db		'Address not available memory:     ',0dh,0ah,'$'
ASP_N			db		'Address of environment:     ',0dh,0ah,'$'
TAIL			db		'Tail:',0dh,0ah,'$'
SOD_SRED		db		'Content of the environment: ' , '$'
PATH			db		'Way to module: ' , '$'
ENDL			db		0dh,0ah,'$'

NEW_LINE		PROC	near
		lea		dx,ENDL
		call	Write_msg
		ret
NEW_LINE		ENDP

Write_msg		PROC	near
		mov		ah,09h
		int		21h
		ret
Write_msg		ENDP

TETR_TO_HEX		PROC	near
		and		al,0fh
		cmp		al,09
		jbe		NEXT
		add		al,07
NEXT:	add		al,30h
		ret
TETR_TO_HEX		ENDP
;---------------------------
BYTE_TO_HEX		PROC near
; ���� � AL ����������� � ��� ������� �����. ����� � AX
		push	cx
		mov		ah,al
		call	TETR_TO_HEX
		xchg	al,ah
		mov		cl,4
		shr		al,cl
		call	TETR_TO_HEX ; � AL ������� �����
		pop		cx 			; � AH �������
		ret
BYTE_TO_HEX		ENDP
;--------------------------
WRD_TO_HEX		PROC	near
; ������ � 16 �/� 16-�� ���������� �����
; � AX - �����, DI - ����� ���������� �������
		push	bx
		mov		bh,ah
		call	BYTE_TO_HEX
		mov		[di],ah
		dec		di
		mov		[di],al
		dec		di
		mov		al,bh
		call	BYTE_TO_HEX
		mov		[di],ah
		dec		di
		mov		[di],al
		pop		bx
		ret
WRD_TO_HEX		ENDP
;----------------------------
; ���������� ������ ���� ����������� ������
DEFINE_AND		PROC	near
		push	ax
		mov 	ax,es:[2]
		lea		di,ADD_N
		add 	di,33
		call	WRD_TO_HEX
		pop		ax
		ret
DEFINE_AND		ENDP
;----------------------------
; ���������� ���������� ����� ����� ������������ ���������
DEFINE_SAS		PROC	near
		push	ax
		mov 	ax,es:[2Ch]
		lea		di,ASP_N
		add 	di,27
		call	WRD_TO_HEX
		pop		ax
		ret
DEFINE_SAS		ENDP
;----------------------------
; ���������� ����� ��������� ������ � ���������� ����
DEFINE_TAIL		PROC	near
		push	ax
		push	cx
    	xor 	ax, ax
    	mov 	al, es:[80h]
    	add 	al, 81h
    	mov 	si, ax
    	push 	es:[si]
    	mov 	byte ptr es:[si+1], '$'
    	push 	ds
    	mov 	cx, es
    	mov 	ds, cx
    	mov 	dx, 81h
    	call	Write_msg
   	 	pop 	ds
    	pop 	es:[si]
    	pop		cx
    	pop		ax
		ret
DEFINE_TAIL		ENDP
;----------------------------
; ���������� ���������� ������� ����� � ���� � ������
DEFINE_SODOS	PROC	near
		push 	es ; ���������
		push	ax ; ����������
		push	bx ; ������
		push	cx ; � �����.
		mov		bx,1 ; ������ ������������ ��������, �� ������� ������ ���� �� ������, �������� 1
		mov		es,es:[2ch] ; ������� � es ������ ����������� ������� �����
		mov		si,0 ; ���������������� �������� ������ �������� 0
	RE1:
		call	NEW_LINE ; ������� �� ����� �������
		mov		ax,si ; ��������� ����� ������ ����� �������� ������� �����
	RE:
		cmp 	byte ptr es:[si], 0 ; ��������� �� 0 �� ���� �������
		je 		NEXT2 ; ��� ������ ������� �� ����� �������� ������� ����� ��������� � ����� NEXT2
		inc		si ; ����������� si �� 1
		jmp 	RE ; ������� � ����� RE
	NEXT2:
		push	es:[si] ; ��������� �������� ������� ������ � ����
		mov		byte ptr es:[si], '$' ; ����������� ���� ������ ���� ��������� ������
		push	ds ; ��������� �������� �������� ds � ����
		mov		cx,es ; ������� � ������� cx �������� �������� es
		mov		ds,cx ; ������ �������� ds �������� �������� cx
		mov		dx,ax ; ������� � ������� dx �������� ����� ������ ������
		call	Write_msg ; ������� ������� ������� �� �����
		pop		ds ; ���������� �������� ds
		pop		es:[si] ; ���������� �������� ������� ������
		cmp		bx,0 ; �������� ������� � ������ ���� �� ������
		jz 		LAST ; ���� bx = 0 �� ��������� � ����� ���������
		inc		si ; ����������� si �� 1
		cmp 	byte ptr es:[si], 01h ; �������� �� ��, ���� �� ������ ���������� � ���� �� ������
    	jne 	RE1 ; ������������ � ����� RE1
    	call	NEW_LINE ; ������� ������
    	lea		dx,PATH ; ������� �������� ���������� PATH � dx
    	call	Write_msg ; ������� ��������� �� �����
    	mov		bx,0 ; ������ ���������� bx �� ����, ����� ��� �����, ��� ������ ���� ����� ���� �� ������
    	add 	si,2 ; ���������� �� ������ �������
    	jmp 	RE1 ; ������� � ����� RE1
    LAST:
    	call	NEW_LINE ; ������� ������
		pop		cx ; ����������
		pop		bx ; ������
		pop		ax ; �� 
		pop		es ; �����.
		ret
DEFINE_SODOS	ENDP
;----------------------------
BEGIN:
		call	DEFINE_AND ;���������� ������ ���� ����������� ������
		call	DEFINE_SAS ;� ��������� ����� ������������ ������
		lea		dx,ADD_N   
		call	Write_msg  ;������� 
		call	NEW_LINE   ;�� �����
		lea		dx,ASP_N   ;���
		call	Write_msg  ;������ 
		call	NEW_LINE 
		lea 	dx, TAIL   
    	call 	Write_msg  ;������� ����� "Tail:"
    	call	DEFINE_TAIL ;���������� � ������� ����� ��������� ������ � ���������� ����
    	call	NEW_LINE 
		lea		dx,SOD_SRED 
		call	Write_msg   ;������� ������ Content of the environment:"
		call	DEFINE_SODOS ;���������� � ������� ���������� ������� ����� � ���� � ������
		
		; ����� � DOS
		xor		al,al
		mov 	ah, 01h
		int		21h
		mov 	ah, 04Ch
		int 	21h
		ret
TESTPC	ENDS
		END 	START