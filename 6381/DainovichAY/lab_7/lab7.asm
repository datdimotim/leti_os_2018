ASSUME CS:CODE, DS:DATA, ES:DATA, SS:STACK
;---------------------------------------------------------------
STACK SEGMENT STACK
	DW 64 DUP (?)
STACK ENDS
;---------------------------------------------------------------
DATA SEGMENT
	Mem_7     DB 0DH, 0AH,'Memory control unit destroyed!',0DH,0AH,'$'
	Mem_8     DB 0DH, 0AH,'Not enough memory to perform the function!',0DH,0AH,'$'
	Mem_9     DB 0DH, 0AH,'Wrong address of the memory block!',0DH,0AH,'$'
	OvlPath   DB 64	dup (0), '$'
	DTA       DB 43 DUP (?)
	KEEP_PSP  DW 0
	Path_To   DB 'Path to the overlay: ','$'
	File_2    DB 0DH, 0AH,'The file was not found!',0DH,0AH,'$'
	File_3    DB 0DH, 0AH,'The route was not found!',0DH,0AH,'$'
	Err_alloc DB 0DH, 0AH,'Failed to allocate memory to load overlay!',0DH,0AH,'$'
	SegAdr    DW 0
	CallAdr	  DD 0
	Load_1    DB 0DH, 0AH,'The overlay was not been loaded: a non-existent function!',0DH,0AH,'$'
	Load_2    DB 0DH, 0AH,'The overlay was not been loaded: file not found!',0DH,0AH,'$'
	Load_3    DB 0DH, 0AH,'The overlay was not been loaded: route not found!',0DH,0AH,'$'
	Load_4    DB 0DH, 0AH,'The overlay was not been loaded: too many open files!',0DH,0AH,'$'
	Load_5    DB 0DH, 0AH,'The overlay was not been loaded: no access!',0DH,0AH,'$'
	Load_8    DB 0DH, 0AH,'The overlay was not been loaded: low memory!',0DH,0AH,'$'
	Load_10   DB 0DH, 0AH,'The overlay was not been loaded: incorrect environment!',0DH,0AH,'$'
	Ovl1	  DB 'overlay1.ovl',0
	Ovl2	  DB 'overlay2.ovl',0	
DATA ENDS
;---------------------------------------------------------------
CODE SEGMENT
START: JMP MAIN
;���������
;---------------------------------------------------------------
PRINT PROC NEAR ;������ �� ����� 
	push ax
	mov ah, 09h
	int 21h
	pop ax
	ret
PRINT ENDP
;--------------------------------------------------------------------------------
FreeSpaceInMemory PROC ;����������� ������ ��� �������� ��������	
	mov bx,offset LAST_BYTE ;����� � ax ����� ����� ���������
	mov ax,es ;es-������
	sub bx,ax ;bx=������=�����-������
	mov cl,4h
	shr bx,cl ;��������� � ���������
	;����������� ����� � ������
	mov ah,4Ah ;������� ��������� ��������� ��������� ��������� ���� ������
	int 21h
	jnc NO_ERROR ;CF=0 - ���� ��� ������
	
	;o�������� ������ CF=1 AX = ��� ������ ���� CF ���������� 
	cmp ax,7 ;�������� ����������� ���� ������
	mov dx,offset Mem_7
	je YES_ERROR
	cmp ax,8 ;������������ ������ ��� ���������� �������
	mov dx,offset Mem_8
	je YES_ERROR
	cmp ax,9 ;�������� ����� ����� ������
	mov dx,offset Mem_9
	
YES_ERROR:
	call PRINT ;������� ������ �� �����
	xor al,al
	mov ah,4Ch
	int 21H
NO_ERROR:
	ret
FreeSpaceInMemory ENDP
;---------------------------------------------------------------
FindPath PROC ;���� ���� � ����� ������� 
	push ds
	push dx
	mov dx, seg DTA ;DS:DX = ����� ��� DTA 
	mov ds, dx
	mov dx,offset DTA ;������������� DS:DX �� ������, ���������� ��� ����� � ��������
	mov ah,1Ah ;���������� ����� DTA
	int 21h 
	pop dx
	pop ds
		
	push es ;���������� ����
	push dx
	push ax
	push bx
	push cx
	push di
	push si
	mov es, keep_PSP ;��������������� PSP
	mov ax, es:[2Ch] ;���������� ����� �����, ������������ ���������
	mov es, ax
	xor bx, bx ;�������� bx
CopyContents: 
	mov al, es:[bx] ;���� ��������� ������
	cmp al, 0h ;��������� �� �� ��� ��� ����� ������
	je	StopCopyContents ;���� ����� ������
	inc bx	;��� �������� � ���������� �������
	jmp CopyContents
StopCopyContents:
	inc bx	;��� �������� � ���������� �������
	cmp byte ptr es:[bx], 0h ;��������� �� �� ��� ��� ����� ������
	jne CopyContents ;���� �� ���� �� ����� ������ (�� 2 0-� ����� ������)
	add bx, 3h ;��� 0-� �����, � ����� 00h � 01h
	mov si, offset OvlPath
CopyPath: ;����
	mov al, es:[bx] ;���� ��������� ������
	mov [si], al ;��������
	inc si ;��������� � ���������� �������
	cmp al, 0h ;��������� �� �� ��� ��� ����� ������
	je	StopCopyPath
	inc bx ;��������� � ���������� �������
	jmp CopyPath
StopCopyPath:	
	sub si, 9h ;�������� �������� ��������� lab7.exe+1(�.�. �� ������� �� ��������� �����)
	mov di, bp ;� di - �������� �������
EntryWay: ;�����������
	mov ah, [di] ;���������� ������ �������� ������� � ah
	mov [si], ah ;���������� � ����
	cmp ah, 0h ;���� ����� �����
	je	StopEntryWay ;����������� ������
	inc di
	inc si
	jmp EntryWay
StopEntryWay:
	mov dx, offset Path_To
	call PRINT
	mov dx, offset OvlPath
	call PRINT
	pop si
	pop di
	pop cx
	pop bx
	pop ax
	pop dx
	pop es
	ret
FindPath ENDP
;---------------------------------------------------------------
SizeOfOverlay PROC ;������ ������ ����� ������� � ����������� ����� ������, ����������� ��� ��������
	push ds
	push dx
	push cx
	xor cx, cx ;cx - �������� ����� ���������, ������� ��� ����� ����� �������� 0
	mov dx, seg OvlPath ;DS:DX = ����� ������ ASCIIZ � ������ �����
	mov ds, dx
	mov dx, offset OvlPath
	mov ax,4E00h ;������� 4E ���������� 21h
	int 21h ;����� 1-� ����������� ���� 
	jnc FileFound ;�������, ���� CF=0, ���� ��� ������
	cmp ax,3
	je Error3
	mov dx, offset File_2 ;���� �� ������
	jmp exitFileEr
Error3:
	mov dx, offset File_3 ;������� �� ������
exitFileEr:
	call PRINT
	pop cx
	pop dx
	pop ds
	xor al,al
	mov ah,4Ch
	int 21H
FileFound: ;���� ���� ��� ������
	push es
	push bx
	mov bx, offset DTA ;�������� �� DTA
	mov dx,[bx+1Ch] ;������� ����� ������� ������ � ������
	mov ax,[bx+1Ah] ;������� ����� ������� �����
	mov cl,4h ;��������� � ��������� ������� �����
	shr ax,cl
	mov cl,12 
	sal dx, cl ;��������� � ����� � ���������
	add ax, dx ;����������
	inc ax ;����� ������� ����� ����� ����������
	mov bx,ax ;� bx - ���������� ������

	mov ah,48h ;������������ ������ (���� ������ ������)
	int 21h 
	jnc MemoryAlloc ;�������, ���� CF=0, ������ ������ ��������
	mov dx, offset Err_alloc ;������� ��������� �� ������
	call PRINT
	xor al,al
	mov ah,4Ch
	int 21H
MemoryAlloc:
	mov SegAdr, ax ;��������� ���������� ����� ��������������� �����
	pop bx
	pop es
	pop cx
	pop dx
	pop ds
	ret
SizeOfOverlay ENDP
;---------------------------------------------------------------
CallOverlay PROC ;���� ����������� �������� ����������� � �����������
	push dx
	push bx
	push ax
	mov bx, seg SegAdr ;ES:BX = ����� EPB (EXEC Parameter Block - ����� ���������� EXEC) 
	mov es, bx
	mov bx, offset SegAdr
		
	mov dx, seg OvlPath ;DS:DX = ����� ������ ASCIIZ � ������ �����, ����������� ���������
	mov ds, dx	
	mov dx, offset OvlPath	

	mov ax, 4B03h ;��������� ����������� �������
	int 21h
	push dx
	jnc IsLoad ;�������, ���� CF=0, ������ ��� ������
	cmp ax, 1 ;�������������� ����
	je Er1
	cmp ax, 2 ;���� �� ������
	je Er2
	cmp ax, 3 ;������� �� ������
	je Er3
	cmp ax, 4 ;������� ����� �������� ������
	je Er4
	cmp ax, 5 ;��� �������
	je Er5
	cmp ax, 8 ;���� ������
	je Er8
	cmp ax, 10 ;������������ �����
	je Er10
	jmp NoEr
	
Er1:
	mov dx, offset Load_1
	call PRINT
	jmp NoEr
Er2:
	mov dx, offset Load_2
	call PRINT
	jmp NoEr
Er3:
	mov dx, offset Load_3
	call PRINT
	jmp NoEr
Er4:
	mov dx, offset Load_4
	call PRINT
	jmp NoEr
Er5:
	mov dx, offset Load_5
	call PRINT
	jmp NoEr
Er8:
	mov dx, offset Load_8
	call PRINT
	jmp NoEr
Er10:
	mov dx, offset Load_10
	call PRINT
	jmp NoEr

IsLoad:
	mov AX,DATA ;��������������� ds
	mov DS,AX
	mov ax, SegAdr
	mov word ptr CallAdr+2, ax
	call CallAdr ;�������� ���������� ���������
	mov ax, SegAdr
	mov es, ax
	mov ax, 4900h ;���������� �������������� ���� ������
	int 21h
	mov AX,DATA ;��������������� ds
	mov DS,AX

NoEr:
	pop dx
	mov es, keep_PSP
	pop ax
	pop bx
	pop dx
	ret
CallOverlay ENDP
;---------------------------------------------------------------
MAIN:
	mov AX,DATA
	mov DS,AX
	mov KEEP_PSP, ES
	call FreeSpaceInMemory ;1)����������� ������ ������ ��� �������� �������
	mov bp, offset Ovl1
	call FindPath;���� ���� � ����� �������
	call SizeOfOverlay ;2)������ ������ ����� ������� � ����������� ����� ������, ����������� ��� ��������
	call CallOverlay ;3)���� ����������� �������� ����������� � �����������
					 ;4)������������� ������, ��������� ��� ����������� ��������
	mov bp, offset Ovl2
	call FindPath;���� ���� � ����� �������
	call SizeOfOverlay ;2)������ ������ ����� ������� � ����������� ����� ������, ����������� ��� ��������
	call CallOverlay ;3)���� ����������� �������� ����������� � �����������
					 ; ;4)������������� ������, ��������� ��� ����������� ��������
	xor al,al
	mov ah,4Ch ;����� 
	int 21h
LAST_BYTE:
	CODE ENDS
	END START