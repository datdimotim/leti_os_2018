; ������ ⥪�� �ணࠬ�� ��� ����� ⨯� .COM
TESTPC SEGMENT
 ASSUME CS:TESTPC, DS:TESTPC, ES:NOTHING, SS:NOTHING
 ORG 100H
 START: JMP BEGIN
; ������
NUM_DOST_MEM_ db '������⢮ ����㯭�� �����: '
NUM_DOST_MEM db '       ����',0DH,0AH,'$'
SIZE_RASSCH_MEM_ db '������ ���७��� ����� : '
SIZE_RASSCH_MEM db '      �����',0DH,0AH,'$'
BLOCK_UPR_MEM_ 	db '����窠 ������ �ࠢ����� �������: ',0DH,0AH
					db ' ����� | �������� | ������ |   ���',0DH,0AH,'$'
BLOCK_UPR_MEM		db '                             $'
ERROR_STR	db '�訡��',0DH,0AH,'$'
STRENDL db 0DH,0AH,'$'
; ���������
;---------------------------------------
PRINT PROC
	push ax
	mov ah,09h
	int 21h
	pop ax
	ret
PRINT ENDP
;---------------------------------------
DOST_PAM PROC
	mov ax,0
	mov ah,4Ah
	mov bx,0FFFFh ; �������� ������ ������
	int 21h
	mov ax,bx 
	mov bx,16
	mul bx ; dx:ax=bx*ax
	mov si,offset NUM_DOST_MEM+5
	call TO_DEC
	mov dx,offset NUM_DOST_MEM_
	call PRINT
	ret
DOST_PAM ENDP
;--------------------------------------
RASSCH_PAM PROC
	; ����稫� � bx ࠧ��� ���७��� �����:
	mov  AL,30h
    out 70h,AL
    in AL,71h
    mov BL,AL
    mov AL,31h
    out 70h,AL
    in AL,71h
	mov bh,al
	
	mov ax,bx
	mov dx,0
	mov si,offset SIZE_RASSCH_MEM+4
	call TO_DEC
	mov dx,offset SIZE_RASSCH_MEM_
	call PRINT
	
	ret
RASSCH_PAM ENDP
;--------------------------------------
MCB PROC
	mov bx,0A000h
	mov ax,offset KONEC ; �ਡ���塞 ࠧ��� ᥣ���� TESTPC
	mov bl,10h
	div bl
	xor ah,ah
	add ax,1
	
	mov bx,cs
	add ax,bx ; �ਡ���塞 cs
	mov bx,es
	sub ax,bx ; ���⠥� PSP
	mov al,0
	mov ah,4Ah
	int 21h
	jnc OSHIBKA
		mov dx,offset ERROR_STR
		call PRINT
	OSHIBKA:
	mov dx,offset BLOCK_UPR_MEM_
	call PRINT
	push es
	; ����砥� ���� ��ࢮ�� MCB:
	mov ah,52h
	int 21h
	mov bx,es:[bx-2]
	mov es,bx
	; �뢮��� 楯��� ������ �ࠢ����� �������:
	CYCLE:
		; ���� MCB:
		mov ax,es
		mov di,offset BLOCK_UPR_MEM+4
		call WRD_TO_HEX
		; PSP �������� ���⪠ �����:
		mov ax,es:[01h]
		mov di,offset BLOCK_UPR_MEM+14
		call WRD_TO_HEX
		; ࠧ��� ���⪠:
		mov ax,es:[03h]
		mov si,offset BLOCK_UPR_MEM+26
		mov dx, 0
		mov bx, 10h
		mul bx
		call TO_DEC
		mov dx,offset BLOCK_UPR_MEM
		call PRINT
		; ��� MCB:
		mov cx,8
		mov bx,8
		mov ah,02h
		CYCLE2:
			mov dl,es:[bx]
			add bx,1
			int 21h
		loop CYCLE2
		mov dx,offset STRENDL
		call PRINT
		mov ax,es
		add ax,1
		add ax,es:[03h]
		mov bl,es:[00h]
		mov es,ax
		
		push bx
		mov ax,'  '
		mov bx,offset BLOCK_UPR_MEM
		mov [bx+19],ax
		mov [bx+21],ax
		mov [bx+23],ax
		pop bx

		cmp bl,4Dh
		je CYCLE
	pop es
	ret
MCB ENDP
;--------------------------------------
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
; ��ॢ�� � 16�/� 16-� ࠧ�來��� �᫠
; � AX - �᫮, DI - ���� ��᫥����� ᨬ����
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
;---------------------------------------
; ��ॢ�� � 10�/�, SI - ���� ���� ����襩 ����
BYTE_TO_DEC PROC near
	push CX
	push DX
	xor AH,AH
	xor DX,DX
	mov CX,10
loop_bd: div CX
	or DL,30h
	mov [SI],DL
	dec SI
	xor DX,DX
	cmp AX,10
	jae loop_bd
	cmp AL,00h
	je end_l
	or AL,30h
	mov [SI],AL
end_l: pop DX
	pop CX
	ret
BYTE_TO_DEC ENDP
;---------------------------------------
; ��ॢ�� dx:ax � 10�/�, SI - ���� ���� ����襩 ����
TO_DEC PROC near
	push CX
	push DX
	;xor AH,AH
	;xor DX,DX
	mov CX,10
loop_bd2: div CX
	or DL,30h
	mov [SI],DL
	dec SI
	xor DX,DX
	cmp AX,10
	jae loop_bd2
	cmp AL,00h
	je end_l2
	or AL,30h
	mov [SI],AL
end_l2: pop DX
	pop CX
	ret
TO_DEC ENDP
;---------------------------------------
	
BEGIN:	
	call DOST_PAM
	call RASSCH_PAM
	call MCB
	xor AL,AL
	mov AH,4Ch
	int 21H
KONEC:
TESTPC ENDS
 END START 