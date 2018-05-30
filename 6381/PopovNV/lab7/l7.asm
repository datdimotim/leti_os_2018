STACK SEGMENT STACK
	DW 64 DUP (?)
STACK ENDS
;===============================================================
DATA SEGMENT
	ErMem7      DB 10,13,'MCB destroyed!',10,13,'$'
	ErMem8      DB 10,13,'Not enough memory for processing!',10,13,'$'
	ErMem9      DB 10,13,'Wrong address of the memory block!',10,13,'$'
	OvlPath     DB 50 dup (0), '$'
	DTA         DB 43 DUP (?)
	KEEP_PSP    DW 0
	Path_To     DB 'Path to the called file: ','$'
	ErFile2     DB 10,13,'The file was not found!',10,13,'$'
	ErFile3     DB 10,13,'The route was not found!',10,13,'$'
	Err_alloc   DB 10,13,'Failed to allocate memory to load overlay!',10,13,'$'
	SegAdr      DW 0
	CallAdr     DD 0
	ErLoadOvl1  DB 10,13,'Overlay wasnt loaded: a nonexistent function!',10,13,'$'
	ErLoadOvl2  DB 10,13,'Overlay wasnt loaded: file not found!',10,13,'$'
	ErLoadOvl3  DB 10,13,'Overlay wasnt loaded: route not found!',10,13,'$'
	ErLoadOvl4  DB 10,13,'Overlay wasnt loaded: too many open files!',10,13,'$'
	ErLoadOvl5  DB 10,13,'Overlay wasnt loaded: no access!',10,13,'$'
	ErLoadOvl8  DB 10,13,'Overlay wasnt loaded: low memory!',10,13,'$'
	ErLoadOvl10 DB 10,13,'Overlay wasnt loaded: incorrect environment!',10,13,'$'
	Ovl1	    DB 'OVERLAY1.OVL',0
	Ovl2	    DB 'OVERLAY2.OVL',0	
DATA ENDS
;===============================================================
CODE SEGMENT
	ASSUME CS:CODE, DS:DATA, ES:DATA, SS:STACK
START: 
	jmp MAIN
;---------------------------------------------------------------
PRINT_STR PROC NEAR
	push ax
	mov ah, 09h
	int 21h
	pop ax
	ret
PRINT_STR ENDP
;--------------------------------------------------------------------------------
FREE_MEMORY PROC ;освобождение памяти
	mov bx,offset Last_byte
	mov ax,es
	sub bx,ax
	mov cl,4h
	shr bx,cl
	mov ah,4Ah
	int 21h
	;проверка на ошибки
	jnc ExitFreeMem
	cmp ax,7
	mov dx,offset ErMem7
	je ErrorFreeMem
	cmp ax,8
	mov dx,offset ErMem8
	je ErrorFreeMem
	cmp ax,9
	mov dx,offset ErMem9
	
ErrorFreeMem:
	call PRINT_STR
	xor al,al
	mov ah,4Ch
	int 21H
ExitFreeMem:
	ret
FREE_MEMORY ENDP
;---------------------------------------------------------------
FIND_PATH_FROM_OVERLAY PROC ;поиск пути к файлу оверлея
	push ds
	push dx
	mov dx, seg DTA
	mov ds, dx
	mov dx,offset DTA
	mov ah,1Ah
	int 21h 
	pop dx
	pop ds
		
	push es
	push dx
	push ax
	push bx
	push cx
	push di
	push si
	mov es, keep_PSP
	mov ax, es:[2Ch]
	mov es, ax
	xor bx, bx
CopyContents: 
	mov al, es:[bx]
	cmp al, 0h
	je	StopCopyContents
	inc bx
	jmp CopyContents
StopCopyContents:
	inc bx
	cmp byte ptr es:[bx], 0h
	jne CopyContents
	add bx, 3h
	mov si, offset OvlPath
CopyPath:
	mov al, es:[bx]
	mov [si], al
	inc si
	cmp al, 0h
	je	StopCopyPath
	inc bx
	jmp CopyPath
StopCopyPath:	
	sub si, 7h
	mov di, bp
EntryWay:
	mov ah, [di]
	mov [si], ah
	cmp ah, 0h
	je	StopEntryWay
	inc di
	inc si
	jmp EntryWay
StopEntryWay:
	mov dx, offset Path_To
	call PRINT_STR
	mov dx, offset OvlPath
	call PRINT_STR
	pop si
	pop di
	pop cx
	pop bx
	pop ax
	pop dx
	pop es
	ret
FIND_PATH_FROM_OVERLAY ENDP
;---------------------------------------------------------------
CHECK_SIZE_OF_OVERLAY PROC ;чтение размера файла оверлея и запрос объёма памяти
	push ds
	push dx
	push cx
	xor cx, cx
	mov dx, seg OvlPath
	mov ds, dx
	mov dx, offset OvlPath
	mov ax,4E00h ;функция 4E прерывания 21h
	int 21h
	;проверка на ошибки
	jnc FileFound
	cmp ax,3
	je Error3
	mov dx, offset ErFile2
	jmp exitFileEr
Error3:
	mov dx, offset ErFile3
exitFileEr:
	call PRINT_STR
	pop cx
	pop dx
	pop ds
	xor al,al
	mov ah,4Ch
	int 21H
FileFound:
	push es
	push bx
	mov bx, offset DTA
	mov dx,[bx+1Ch]
	mov ax,[bx+1Ah]
	mov cl,4h
	shr ax,cl
	mov cl,12 
	sal dx, cl
	add ax, dx
	inc ax
	mov bx,ax

	mov ah,48h
	int 21h 
	jnc MemoryAlloc
	mov dx, offset Err_alloc
	call PRINT_STR
	xor al,al
	mov ah,4Ch
	int 21H
MemoryAlloc:
	mov SegAdr, ax
	pop bx
	pop es
	pop cx
	pop dx
	pop ds
	ret
CHECK_SIZE_OF_OVERLAY ENDP
;---------------------------------------------------------------
CALL_OVERLAY PROC ;загрузка и выполнение файла оверлейного сегмента
	push dx
	push bx
	push ax
	mov bx, seg SegAdr
	mov es, bx
	mov bx, offset SegAdr
		
	mov dx, seg OvlPath
	mov ds, dx	
	mov dx, offset OvlPath	

	mov ax, 4B03h
	int 21h
	push dx
	;проверка на ошибки
	jnc IsLoad
	cmp ax, 1
	je Er1
	cmp ax, 2
	je Er2
	cmp ax, 3
	je Er3
	cmp ax, 4
	je Er4
	cmp ax, 5
	je Er5
	cmp ax, 8
	je Er8
	cmp ax, 10
	je Er10
	jmp NoEr
	
Er1:
	mov dx, offset ErLoadOvl1
	call PRINT_STR
	jmp NoEr
Er2:
	mov dx, offset ErLoadOvl2
	call PRINT_STR
	jmp NoEr
Er3:
	mov dx, offset ErLoadOvl3
	call PRINT_STR
	jmp NoEr
Er4:
	mov dx, offset ErLoadOvl4
	call PRINT_STR
	jmp NoEr
Er5:
	mov dx, offset ErLoadOvl5
	call PRINT_STR
	jmp NoEr
Er8:
	mov dx, offset ErLoadOvl8
	call PRINT_STR
	jmp NoEr
Er10:
	mov dx, offset ErLoadOvl10
	call PRINT_STR
	jmp NoEr

IsLoad:
	mov AX,DATA
	mov DS,AX
	mov ax, SegAdr
	mov word ptr CallAdr+2, ax
	call CallAdr
	mov ax, SegAdr
	mov es, ax
	mov ax, 4900h ;освобождение распределенного блока памяти
	int 21h
	mov AX,DATA
	mov DS,AX

NoEr:
	pop dx
	mov es, keep_PSP
	pop ax
	pop bx
	pop dx
	ret
CALL_OVERLAY ENDP
;---------------------------------------------------------------
MAIN:
	mov AX,DATA
	mov DS,AX
	mov KEEP_PSP, ES
	call FREE_MEMORY
	mov bp, offset Ovl1
	call FIND_PATH_FROM_OVERLAY
	call CHECK_SIZE_OF_OVERLAY
	call CALL_OVERLAY
	mov bp, offset Ovl2
	call FIND_PATH_FROM_OVERLAY
	call CHECK_SIZE_OF_OVERLAY
	call CALL_OVERLAY
	
	xor al,al
	mov ah,4Ch
	int 21h
Last_byte:
CODE ENDS
END MAIN