print macro
	push ax
	mov ax,0900h
	int 21h
	pop ax
endm
printl macro a
	push ax
	push dx
	lea dx,a
	mov ax,0900h
	int 21h
	lea dx,STRENDL
	int 21h
	pop dx
	pop ax
endm
debug macro r
	pushf
	push ax
	push di
	mov ax,r
	lea di,STRTEST+3
	call WRD_TO_HEX
	printl STRTEST
	pop di
	pop ax
	popf
endm
CODE SEGMENT
 ASSUME CS:CODE, DS:DATA, ES:DATA, SS:STACKSEG
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
; ��ॢ�� � 16�/� 16-� ࠧ�來��� �᫠
; � AX - �᫮, DI - ���� ��᫥����� ᨬ����
WRD_TO_HEX PROC far
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
; �㭪�� �᢮�������� ��譥� ����� �
FREE_MEM PROC
	push ax
	push bx
	push dx
	; �뢮��� �஬����筮� ᮮ�饭��:
		printl STR_FREE_MEM
	; ����塞 � BX ����室���� ������⢮ ����� ��� �⮩ �ணࠬ�� � ��ࠣ���
		mov ax,STACKSEG ; � ax ᥣ����� ���� �⥪�
		mov bx,es
		sub ax,bx ; ���⠥� ᥣ����� ���� PSP
		add ax,10h ; �ਡ���塞 ࠧ��� �⥪� � ��ࠣ���
		mov bx,ax
	; �஡㥬 �᢮������ ����� ������
		mov ah,4Ah
		int 21h
		jnc FREE_MEM_SUCCESS

	; ��ࠡ�⪠ �訡��
		mov dx,offset STR_ERR_FREE_MEM
		print
		cmp ax,7
		mov dx,offset STR_ERR_MCB_DESTROYED
		je FREE_MEM_PRINT_ERROR
		cmp ax,8
		mov dx,offset STR_ERR_NOT_ENOUGH_MEM
		je FREE_MEM_PRINT_ERROR
		cmp ax,9
		mov dx,offset STR_ERR_WRNG_MEM_BL_ADDR

		FREE_MEM_PRINT_ERROR:
		print
		mov dx,offset STRENDL
		print

	; ��室 � DOS
		xor AL,AL
		mov AH,4Ch
		int 21H

	FREE_MEM_SUCCESS:
	printl STR_PROC_DONE
	pop dx
	pop bx
	pop ax
	ret
FREE_MEM ENDP
;---------------------------------------
; ��楤�� �뤥����� ����� ��� ���૥����� ᥣ����.
; �����塞�� ���祭�� - ax - ���� ᥣ���� �뤥������ �����
ALLOC_MEM PROC
	push ds
	push dx
	; �뢮��� �஬����筮� ᮮ�饭��:
		printl STR_ALLOC_MEM

	; ��⠥� ࠧ��� 䠩�� ���૥�:
		xor cx,cx
		mov ax,4E00h
		int 21h
		jnc ALLOC_MEM_FILE_FOUND
			printl STR_ERR_FL_NOT_FND
			pop dx
			pop ds
			jmp ALLOC_MEM_ERR_EXIT
		ALLOC_MEM_FILE_FOUND:
		push es
		push bx
		; ����砥� � ES:BX ���� DTA
		mov ah,2fh
		int 21h
		; ����� ࠧ��� 䠩�� � DX:AX
		add bx,1ah
		mov ax,word ptr ES:[BX]
		mov dx,word ptr ES:[BX+2]
		mov bx,10h
		div bx ; ����砥� � ax ࠧ��� 䠩�� � ��ࠣ���
		inc ax

	; ����訢��� ��ꥬ �����:
		mov ah,48h
		int 21h
		jnc ALLOC_MEM_DONE
			printl STR_ERR_ALLOC_MEM
			call PROCESS_LOADER_ERRORS
			mov ax,4c00h
			int 21h
		ALLOC_MEM_DONE:
		pop es
		pop bx
	pop dx
	pop ds
	printl STR_PROC_DONE
	mov word ptr OVERLAY_ADDR+2,ax
	mov PARAMBLOCK,ax
	ret
	
	ALLOC_MEM_ERR_EXIT:
	
	ret
ALLOC_MEM ENDP
;---------------------------------------
; ��楤�� ���᪠ 䠩�� ���૥� �
; � ॣ���� bp - �������� 䠩�� ���૥�, ����饣� � ⮩ �� �����
; �����塞�� ���祭�� - DS:DX 㪠�뢠�� �� ��ப� � ����� ������ ����᪠����� ���૥�
FIND_OVERLAY_PATH PROC
	; �뢮��� �஬����筮� ᮮ�饭��:
		printl STR_FIND_OVERLAY_PATH

	push es ; ���࠭塞 PSP
	push ax
	push si
	push di
	push cx
	
	; ���室�� � ������� �।�
	mov ax, es:[2ch]
	mov es, ax
	; �ய�᪠�� ��६���� �।�:
	; ������㥬 ��ப� es:di, ���� ���� �� ࠢ�� 0
	mov al, 0 ; ����� ���� �饬
	mov di, 0 ; �����⥫� �� ������� ������ � ������ �।�
	FIND_OVERLAY_SKIP_BEGIN:
	mov cx, 512 ; ���ᨬ���� ࠧ��� ����� ���᪠
repne scasb ; �����塞, ���� ��������㥬� ���� �� ࠢ�� al(0)
	cmp es:[di],al ; �᫨ ��ன ���� - �� ����, �த������ �ய�᪠��
	jne FIND_OVERLAY_SKIP_BEGIN
	
	add di, 3 ; �ய�᪠�� 001
	
	; ��⠥� ����� ��ப�, ᮤ�ঠ饩 ����� ���� � �ணࠬ��
	push di
	mov cx,100 ; ���ᨬ��쭠� ����� ��ப�
repne scasb
	mov ax,di ; ������ � ax ���� ᨬ����, ᫥���騬 �� ��ப��
	pop di ; ������ � di ��砫� ��ப�
	sub ax,di 
	dec ax ; ����砥� � ax ������⢮ ᨬ����� � ��ப� ��� � �ணࠬ��
	mov cx,ax ; ����� � cx ������⢮ �����㥬�� ᨬ�����
	
	; �����㥬 ��ப�
	push ds
	push es
	pop ds
	pop es ; �����﫨 ���⠬� es(������� �।�) � ds(ᥣ���� ������)
	mov si,di ; ������ � ds:si ��砫� �����㥬�� ��ப�
	lea di,OVERLAY_PATH ; ������ � es:di ��砫� ��ப�, � ������ �����㥬
rep movsb ; �����㥬 cx ���� �� ds:si � es:di
	mov byte ptr es:[di],0 ; �����蠥� ᪮��஢����� ��ப� �㫥�
		
	; �����塞 �������� ⥪�饩 �ணࠬ�� ��������� ���૥�
	mov cx,100
	mov al,'\' ; �饬 ᨬ��� '\'
	std ; ���� � ������ ��஭�, es:di - ����� ᪮��஢����� ��ப�
repne scasb
	cld ; �����頥� �⠭���⭮� ���ࠢ����� ��室�
	add di,2 ; ���室�� �� ᨬ��� �� ᨬ����� '\'
	mov cx,13 ; ��� ���૥� - 13 ���⮢, ������ 0
	mov ax,data
	mov ds,ax
	mov si,bp
	; ��⠭����� ds:si �� �����㥬�� ��ப�, es:di - �� �, �㤠 �����㥬
rep movsb ; �믮��塞 ����஢����
	
	pop cx
	pop di
	pop si
	pop ax
	pop es ; ����⠭�������� PSP
	
	lea dx,OVERLAY_PATH ; ����� 㪠��⥫� �� ������ ��� �ணࠬ�� � dx
	
	printl STR_PROC_DONE
	ret
FIND_OVERLAY_PATH ENDP
;---------------------------------------
; ��楤�� ����᪠ ���૥�
; �ਭ����� � bp 㪠��⥫� �� ��� ����᪠����� ���૥� �� ⮣� �� ��⠫���, �� � ᠬ� �ணࠬ��
RUN_OVERLAY PROC
	push ds
	push es
	push ax
	push bx
	push cx
	push dx
	
	
	; �饬 䠩� � ���૥��, ��⠭�������� DS:DX �� ��ப�, ᮤ�ঠ��� ��� 䠩�� � ���૥��
	call FIND_OVERLAY_PATH
	
	; �뤥�塞 ������ ��� ���૥� � ����砥� ᥣ����� ���� �뤥������ ����� � ax
	call ALLOC_MEM
	jnc OVERLAY_FOUND
		jmp OVERLAY_ERR
	OVERLAY_FOUND:
	mov CS:KEEP_SP, SP
	mov CS:KEEP_SS, SS
	mov CS:KEEP_DS, DS
	mov CS:KEEP_ES, ES

	; ������㥬 ���� ��ࠬ��஢
	mov PARAMBLOCK,ax 
	push ds
	pop es ; � ES ����� DS
	lea bx, PARAMBLOCK ; ES:BX 㪠�뢠�� �� ���� ��ࠬ��஢
	; �뢮��� �஬����筮� ᮮ�饭��:
	printl STR_RUN_OVERLAY
	; ����᪠�� ���૥�
		mov ax,4b03h
		int 21h
		jnc OVL_LOADED
			call PROCESS_LOADER_ERRORS
		OVL_LOADED:
	; ���室�� � ���૥�
		printl STRENDL
		call dword ptr OVERLAY_ADDR
		printl STRENDL
	mov SP,CS:KEEP_SP
	mov SS,CS:KEEP_SS
	mov DS,CS:KEEP_DS
	mov ES,CS:KEEP_ES
	jnc OVERLAY_SUCCESS

	; ��ࠡ�⪠ �訡��
		call PROCESS_LOADER_ERRORS

	; �訡�� ���
	OVERLAY_SUCCESS:
	printl STR_PROC_DONE
	; �᢮������� ������
	printl STR_RMV_OVERLAY
	push es
	mov ax,PARAMBLOCK
	mov es,ax
	mov ax,4900h
	int 21h
	pop es
	jnc OVERLAY_DELETE_SUCCESS
	call PROCESS_LOADER_ERRORS
	OVERLAY_DELETE_SUCCESS:
	printl STR_PROC_DONE
	OVERLAY_ERR:
	pop dx
	pop cx
	pop bx
	pop ax
	pop es
	pop ds
	ret
	; ��६���� ��� �࠭���� ॣ���஢
	KEEP_SP dw 0
	KEEP_SS dw 0
	KEEP_DS dw 0
	KEEP_ES dw 0
RUN_OVERLAY ENDP
;---------------------------------------
; ��楤�� ��ࠡ�⪨ �訡�� �����稪� �� �
PROCESS_LOADER_ERRORS PROC
	cmp ax,1
	lea dx,STR_ERR_WRNG_FNCT_NUMB
	je PROCESS_LOADER_ERRORS_PRINT
	cmp ax,2
	lea dx,STR_ERR_FL_NOT_FND
	je PROCESS_LOADER_ERRORS_PRINT
	cmp ax,3
	lea dx,STR_ERR_PATH_NOT_FOUND
	je PROCESS_LOADER_ERRORS_PRINT
	cmp ax,4
	lea dx,STR_ERR_TOO_MANY_FILES
	je PROCESS_LOADER_ERRORS_PRINT
	cmp ax,5
	lea dx,STR_ERR_NO_ACCESS
	je PROCESS_LOADER_ERRORS_PRINT
	cmp ax,6
	lea dx,STR_ERR_INVLD_HNDL
	je PROCESS_LOADER_ERRORS_PRINT
	cmp ax,7
	lea dx,STR_ERR_MCB_DESTROYED
	je PROCESS_LOADER_ERRORS_PRINT
	cmp ax,8
	lea dx,STR_ERR_NOT_ENOUGH_MEM
	je PROCESS_LOADER_ERRORS_PRINT
	cmp ax,9
	lea dx,STR_ERR_WRNG_MEM_BL_ADDR
	je PROCESS_LOADER_ERRORS_PRINT
	cmp ax,10
	lea dx,STR_ERR_WRONG_ENV
	je PROCESS_LOADER_ERRORS_PRINT
	cmp ax,11
	lea dx,STR_ERR_WRONG_FORMAT
	je PROCESS_LOADER_ERRORS_PRINT
	cmp ax,12
	lea dx,STR_ERR_INV_ACCSS_MODE
	je PROCESS_LOADER_ERRORS_PRINT
	lea dx,STR_ERR_UNKNWN
	PROCESS_LOADER_ERRORS_PRINT:
	print
	mov ax,4c00h
	int 21h
PROCESS_LOADER_ERRORS ENDP
;---------------------------------------
BEGIN:
	mov ax,data
	mov ds,ax
	; �᢮������� ����� ������
	call FREE_MEM

	push dx
	lea dx,STRENDL
	print
	pop dx
	printl STR_FIRST_OVERLAY
	
	; ����᪠�� ���૥� Overlay1.com
	lea bp, STR_OVL1
	call RUN_OVERLAY
	
	push dx
	lea dx,STRENDL
	print
	pop dx
	printl STR_SECOND_OVERLAY
	
	; ����᪠�� ���૥� Overlay2.com
	lea bp, STR_OVL2
	call RUN_OVERLAY
	
	xor AL,AL
	mov AH,4Ch
	int 21H
CODE ENDS
; ������
DATA SEGMENT
	; ��ப� �訡��:
		STR_ERR_FREE_MEM	 		db 'Error when freeing memory: $'
		STR_ERR_ALLOC_MEM			db 'Error while allocating memory$'
		STR_ERR_TOO_LONG_TAIL		db 'Tail is too long$'

	; �訡�� �� DOS
		STR_ERR_WRNG_FNCT_NUMB		db 'Function number is wrong$'
		STR_ERR_FL_NOT_FND			db 'File not found$'
		STR_ERR_PATH_NOT_FOUND		db 'Path not found$'
		STR_ERR_TOO_MANY_FILES		db 'Too many open files$'
		STR_ERR_NO_ACCESS			db 'Access denied$'
		STR_ERR_INVLD_HNDL			db 'Invalid handle$'
		STR_ERR_MCB_DESTROYED		db 'Memory control blocks destroyed$'
		STR_ERR_NOT_ENOUGH_MEM		db 'Insufficient memory$'
		STR_ERR_WRNG_MEM_BL_ADDR 	db 'Invalid memory block address$'
		STR_ERR_WRONG_ENV			db 'Invalid environment$'
		STR_ERR_WRONG_FORMAT		db 'Invalid format$'
		STR_ERR_INV_ACCSS_MODE		db 'Invalid access mode$'
		STR_ERR_UNKNWN				db 'Unknown error$'

	; ��ப�, �������騥 � ࠡ�� �㭪権
		STR_FIRST_OVERLAY		db 'First overlay:$'
		STR_SECOND_OVERLAY		db 'Second overlay:$'
		STR_FREE_MEM			db 'Freeing memory:$'
		STR_ALLOC_MEM			db 'Allocating memory:$'
		STR_FIND_OVERLAY_PATH	db 'Finding overlay path:$'
		STR_RUN_OVERLAY			db 'Running overlay:$'
		STR_PROC_DONE			db 'Done.$'
		STR_RMV_OVERLAY			db 'Removing overlay:$'

	STRENDL 				db 0DH,0AH,'$'
	STRTEST					db '    $'
	
	OVERLAY_ADDR dd 0 ; ��ࢮ� ᫮�� - IP(=0), ��஥ - ᥣ����(��⠭���������� � �ணࠬ��)
	; ���� ��ࠬ��஢. ��। ����㧪�� ���୥� �ணࠬ�� �� ���� ������ 㪠�뢠�� ES:BX
	PARAMBLOCK	dw 0 ; �������� ����, �� ���஬� ����㦠���� ���૥�
				dd 0 ; �������� ���� � ᬥ饭�� ��ࠬ��஢ ��������� ��ப�
	OVERLAY_PATH  		db 105 dup ('$')
	STR_OVL1			db 'Overlay1.com',0
	STR_OVL2			db 'Overlay2.com',0

DATA ENDS
; ����
STACKSEG SEGMENT STACK
	dw 80h dup (?) ; 100h ����
STACKSEG ENDS
 END START
