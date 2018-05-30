ASSUME CS:CODE, DS:DATA, ES:DATA, SS:ASTACK
		
ASTACK SEGMENT STACK
	DW 64 DUP (?)
ASTACK ENDS

DATA SEGMENT
	ErrorMem7     DB 0DH, 0AH,'MCB destroyed',0DH,0AH,'$'
	ErrorMem8     DB 0DH, 0AH,'Not enough memory for processing',0DH,0AH,'$'
	ErrorMem9     DB 0DH, 0AH,'Wrong address',0DH,0AH,'$'
	OverlayPath   DB 64 DUP (0), '$'
	DTA           DB 43 DUP (?)
	KeepPSP       DW 0
	Path   	      DB 'Path: ',0DH,0AH,'$'
	ErrorCall2    DB 0DH, 0AH,'File not found',0DH,0AH,'$'
	ErrorCall3    DB 0DH, 0AH,'Route not found',0DH,0AH,'$'
	ErrАlloc      DB 0DH, 0AH,'Incorrect allocate memory',0DH,0AH,'$'
	SegmentAdr    DW 0
	OverlayAdr	  DD 0
	ErrorLoad1    DB 0DH, 0AH,'Non-existent function',0DH,0AH,'$'
	ErrorLoad2    DB 0DH, 0AH,'File not found',0DH,0AH,'$'
	ErrorLoad3    DB 0DH, 0AH,'Route not found',0DH,0AH,'$'
	ErrorLoad4    DB 0DH, 0AH,'A lot of open files',0DH,0AH,'$'
	ErrorLoad5    DB 0DH, 0AH,'No access',0DH,0AH,'$'
	ErrorLoad8    DB 0DH, 0AH,'Not enough memory',0DH,0AH,'$'
	ErrorLoad10   DB 0DH, 0AH,'Incorrect environment',0DH,0AH,'$'
	Overlay1	  DB 'ovl_1.ovl',0
	Overlay2	  DB 'ovl_2.ovl',0	
DATA ENDS

CODE SEGMENT
START: 
	JMP BEGIN

FREE_MEMORY PROC                 ;подготовка и освобождение места в памяти 
		lea bx,Last_byte 
		mov ax,es 
		sub bx,ax
		mov cl,4h
		shr bx,cl 

		mov ah,4Ah 
		int 21h
		jnc EndFree              ;проверка CF

		cmp ax,7
		lea dx, ErrorMem7
		je ErrorMemory
		cmp ax,8
		lea dx, ErrorMem8
		je ErrorMemory
		cmp ax,9
		lea dx, ErrorMem9
		
	ErrorMemory:
		call WRITE
		xor al,al
		mov ah,4Ch
		int 21H
	EndFree:
		ret
FREE_MEMORY ENDP
;-----------------------------------------------------------
FIND_PATH PROC                   ;ищем путь к файлу оверлея 
		push ds
		push dx
		mov dx, seg DTA 
		mov ds, dx
		lea dx, DTA
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
		
		mov es, KeepPSP
		mov ax, es:[2Ch]
		mov es, ax
		xor bx, bx
		lea si, OverlayPath		
	SkipFirst: 
		cmp word ptr es:[bx], 0000H
		je	StopSF
		inc bx
		jmp SkipFirst
	StopSF:
		inc bx
		cmp byte ptr es:[bx], 00h 
		jne SkipFirst
		add bx, 3
	SkipSecond:                  ;путь
		mov al, es:[bx]
		mov [si], al
		inc si
		cmp al, 0h
		je	StopSs
		inc bx
		jmp SkipSecond
	StopSs:
		sub si, 8
		mov di, bp
	SkipThird:                   ;перемещение
		mov ah, [di]             ;перемещаем символ названия оверлея в ah
		mov [si], ah             ;записываем в путь
		cmp ah, 0h               ;если конец имени
		je	StopSt               ;заканчиваем запись
		inc di
		inc si
		jmp SkipThird
	StopSt:
		lea dx, Path
		call WRITE
		lea dx, OverlayPath
		call WRITE
		pop si
		pop di
		pop cx
		pop bx
		pop ax
		pop dx
		pop es
		ret
FIND_PATH ENDP
;-----------------------------------------------------------
MEM_OVERLAY_SIZE PROC
		push ds
		push dx
		push cx
		xor cx, cx
		mov dx, seg OverlayPath
		mov ds, dx
		lea dx, OverlayPath
		mov ax,4E00h
		int 21h
		jnc FileFound
		cmp ax,3
		je Error3
		lea dx, ErrorCall2
		jmp ErrorExit
	Error3:
		lea dx, ErrorCall3
	ErrorExit:
		call WRITE
		pop cx
		pop dx
		pop ds
		xor al,al
		mov ah,4Ch
		int 21H
	FileFound:
		push es
		push bx
		lea bx, DTA
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
		jnc NoErrAlloc           ;перейти, если CF=0, значит память выделена
		lea dx, ErrАlloc         ;выводим сообщение об ошибке
		call WRITE
		xor al,al
		mov ah,4Ch
		int 21H
	NoErrAlloc:
		mov SegmentAdr, ax
		pop bx
		pop es
		pop cx
		pop dx
		pop ds
		ret
MEM_OVERLAY_SIZE ENDP
;-----------------------------------------------------------
CALL_OVERLAY PROC 
		push dx
		push bx
		push ax
		mov bx, seg SegmentAdr
		mov es, bx
		lea bx, SegmentAdr
		mov dx, seg OverlayPath 
		mov ds, dx	
		lea dx, OverlayPath	
		mov ax, 4B03h
		int 21h
		push dx
		jnc NoError
		
		cmp ax, 1
		jne NoError1
		lea dx, ErrorLoad1
		call WRITE
		jmp Exit
	NoError1:	
		cmp ax, 2
		jne NoError2
		lea dx, ErrorLoad2
		call WRITE
		jmp Exit
	NoError2:	
		cmp ax, 3
		jne NoError3
		lea dx, ErrorLoad4
		call WRITE
		jmp Exit
	NoError3:
		cmp ax, 4
		jne NoError4
		lea dx, ErrorLoad4
		call WRITE
		jmp Exit
	NoError4:	
		cmp ax, 5
		jne NoError5
		lea dx, ErrorLoad5
		call WRITE
		jmp Exit
	NoError5:	
		cmp ax, 8
		jne NoError8
		lea dx, ErrorLoad8
		call WRITE
		jmp Exit
	NoError8:	
		cmp ax, 10
		jne Exit
		lea dx, ErrorLoad10
		call WRITE
		jmp Exit

	NoError:
		mov AX,DATA 
		mov DS,AX
		mov ax, SegmentAdr
		mov word ptr OverlayAdr+2, ax
		call OverlayAdr
		mov ax, SegmentAdr
		mov es, ax
		mov ax, 4900h
		int 21h
		mov AX,DATA 
		mov DS,AX
	Exit:
		pop dx
		mov es, KeepPSP
		pop ax
		pop bx
		pop dx
		ret
CALL_OVERLAY ENDP
;-----------------------------------------------------------
WRITE PROC NEAR
	push ax
	mov ah, 09h
	int 21h
	pop ax
	ret
WRITE ENDP
;-----------------------------------------------------------
BEGIN:
		mov AX,DATA
		mov DS,AX
		mov KeepPSP, ES
		call FREE_MEMORY
		
		lea bp, Overlay1
		call FIND_PATH
		call MEM_OVERLAY_SIZE 
		call CALL_OVERLAY
		
		lea bp, Overlay2
		call FIND_PATH
		call MEM_OVERLAY_SIZE 
		call CALL_OVERLAY
		
		xor al,al
		mov ah,4Ch 
		int 21h
	Last_byte:
		CODE ENDS
	END START