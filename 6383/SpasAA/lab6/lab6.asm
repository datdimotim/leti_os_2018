CODE SEGMENT
 ASSUME CS:CODE, DS:DATA, ES:DATA, SS:ASTACK
START: JMP BEGIN
; ���������
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
PRINT PROC
	push ax
	mov AH,09h
	int 21h
	pop ax
	ret
PRINT ENDP
;---------------------------------------
PODG PROC
	; �᢮������� ���㦭�� ������(es - ᥣ���� psp, bx - ��ꥬ �㦭�� �����):
	mov ax,ASTACK
	sub ax,CODE
	add ax,100h
	mov bx,ax
	mov ah,4ah
	int 21h
	jnc podg_skip1
		call OBR_OSH
	podg_skip1:
	
	; �����⠢������ ���� ��ࠬ��஢:
	call PODG_PAR
	
	; ��।��塞 ���� �� �ணࠬ��:
	push es
	push bx
	push si
	push ax
	mov es,es:[2ch] ; � es ᥣ����� ���� �।�
	mov bx,-1
	SREDA_ZIKL:
		add bx,1
		cmp word ptr es:[bx],0000h
		jne SREDA_ZIKL
	add bx,4
	mov si,-1
	PUT_ZIKL:
		add si,1
		mov al,es:[bx+si]
		mov PROGR[si],al
		cmp byte ptr es:[bx+si],00h
		jne PUT_ZIKL
	
	; ������塞�� �� �������� �ணࠬ�� � ���
	add si,1
	PUT_ZIKL2:
		mov PROGR[si],0
		sub si,1
		cmp byte ptr es:[bx+si],'\'
		jne PUT_ZIKL2
	; ������塞 ��� ����᪠�� �ணࠬ��
	add si,1
	mov PROGR[si],'l'
	add si,1
	mov PROGR[si],'a'
	add si,1
	mov PROGR[si],'b'
	add si,1
	mov PROGR[si],'2'
	add si,1
	mov PROGR[si],'.'
	add si,1
	mov PROGR[si],'e'
	add si,1
	mov PROGR[si],'x'
	add si,1
	mov PROGR[si],'e'
	pop ax
	pop si
	pop bx
	pop es	
	
	ret
PODG ENDP
;---------------------------------------
PODG_PAR PROC
	mov ax, es:[2ch]
	mov PARAM, ax
	mov PARAM+2,es ; �������� ���� ��ࠬ��஢ ��������� ��ப�(PSP)
	mov PARAM+4,80h ; ���饭�� ��ࠬ��஢ ��������� ��ப�
	ret
PODG_PAR ENDP
;---------------------------------------
ZAP_MOD PROC
	; ��⠭�������� ES:BX �� ���� ��ࠬ��஢
	mov ax,ds
	mov es,ax
	mov bx,offset PARAM
	
	; ��⠭�������� DS:DX �� ���� � ��� ��뢠���� �ணࠬ��
	mov dx,offset PROGR
	
	; ��࠭塞 SS � SP:
	mov KEEP_SS, SS
	mov KEEP_SP, SP
	
	; ����᪠�� �ணࠬ��:
	mov ax,4B00h
	int 21h
	
	; ����⠭�������� DS, SS, SP:
	push ax
	mov ax,DATA
	mov ds,ax
	pop ax
	mov SS,KEEP_SS
	mov SP,KEEP_SP
	; ��ࠡ��뢠�� �訡��:
	jnc zap_mod_skip1
		call OBR_OSH
		jmp zap_mod_konec
	zap_mod_skip1:
	
	; ��ࠡ�⪠ �����襭�� �ணࠬ��:
	call PROV_ZAV
	
	zap_mod_konec:

	ret
ZAP_MOD ENDP
;---------------------------------------
OBR_OSH PROC
	mov dx,offset o
	call PRINT

	mov dx,offset o1
	cmp ax,1
	je osh_pechat
	mov dx,offset o2
	cmp ax,2
	je osh_pechat
	mov dx,offset o7
	cmp ax,7
	je osh_pechat
	mov dx,offset o8
	cmp ax,8
	je osh_pechat
	mov dx,offset o9
	cmp ax,9
	je osh_pechat
	mov dx,offset o10
	cmp ax,10
	je osh_pechat
	mov dx,offset o11
	cmp ax,11
	je osh_pechat
	
	osh_pechat:
	call PRINT
	mov dx,offset STRENDL
	call PRINT
	
	ret
OBR_OSH ENDP
;---------------------------------------
PROV_ZAV PROC
	; ����砥� � al ��� �����襭��, � ah - ��稭�:
	mov al,00h
	mov ah,4dh
	int 21h

	mov dx, offset z0
	cmp ah, 0
	je prov_zav_pech_1
	mov dx,offset z1
	cmp ah,1
	je prov_zav_pech
	mov dx,offset z2
	cmp ah,2
	je prov_zav_pech
	mov dx,offset z3
	cmp ah,3
	je prov_zav_pech
	
	prov_zav_pech_1:
	call PRINT
	mov dx,offset STRENDL
	call PRINT
	mov dx, offset z
	
	prov_zav_pech:
	call PRINT

	cmp ah,0
	jne prov_zav_skip

	; ����� ���� �����襭��:
	call BYTE_TO_HEX
	push ax
	mov ah,02h
	mov dl,al
	int 21h
	pop ax
	mov dl,ah
	mov ah,02h
	int 21h
	mov dx,offset STRENDL
	call PRINT
	prov_zav_skip:
	
	ret
PROV_ZAV ENDP
;---------------------------------------
BEGIN:
	mov ax,data
	mov ds,ax
	call PODG
	call ZAP_MOD
	xor AL,AL
	mov AH,4Ch
	int 21H
CODE ENDS
; ������
DATA SEGMENT	
	; �訡��
	o db '�訡��: $'
	o1 db '����� �㭪樨 ����७$'
	o2 db '���� �� ������$'
	o7 db '�����襭 �ࠢ���騩 ���� �����$'
	o8 db '��������� ��ꥬ �����$'
	o9 db '������ ���� ����� �����$'
	o10 db '���ࠢ��쭠� ��ப� �।�$'
	o11 db '���ࠢ���� �ଠ�$'
	
	; ��稭� �����襭��
	z0 db '��ଠ�쭮� �����襭��$'
	z1 db '�����襭�� �� Ctrl-Break$'
	z2 db '�����襭�� �� �訡�� ���ன�⢠$'
	z3 db '�����襭�� �� �㭪樨 31h$'
	z db '��� �����襭��: $'
		
	STRENDL db 0DH,0AH,'$'
	
	; ���� ��ࠬ��஢
	PARAM 	dw 0 ; ᥣ����� ���� �।�
			dd 0 ; ᥣ���� � ᬥ饭�� ��������� ��ப�
			dd 0 ; ᥣ���� � ᬥ饭�� ��ࢮ�� FCB
			dd 0 ; ᥣ���� � ᬥ饭�� ��ண� FCB
	
	; ���� � ��� ��뢠���� �ணࠬ��	
	PROGR db 40h dup (0)
	; ��६���� ��� �࠭���� SS � SP
	KEEP_SS dw 0
	KEEP_SP dw 0
DATA ENDS
; ����
ASTACK SEGMENT STACK
	dw 100h dup (?)
ASTACK ENDS
 END START