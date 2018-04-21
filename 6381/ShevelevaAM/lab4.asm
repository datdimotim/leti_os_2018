
CODE SEGMENT
	ASSUME CS:CODE, DS:CODE , SS:STACKSG

ROUT PROC FAR

jmp start
	String		DB		'Error'
	Symbol		DB		0
	Save_CS		DW		0 
	Save_IP		DW		0 
	Save_PSP	DW		0	

start:	
	push ss
	push sp

	push ax
	push bx
	push dx
	push cx

	mov ah,03h
	mov bh,0
	int 10h 
	push dx   ;текущие строка, колонка курсора
	

	mov ah,02h   ;передвижение курсора
	mov bh,0
	mov dh, 20
	mov dl,40
	int 10h 
	
	mov al, Symbol	;вывод символа	
	add al, 1
	mov Symbol, al
	mov ah,09h 
	mov bh,0 
	mov bl, 10
	mov cx,1 
	int 10h 
	
	mov ah,02h  ;возвращение курсора
	mov bh,0
	pop DX
	int 10h 
	
	pop CX
	pop dx
	pop bx
	pop ax
	
	pop sp
	pop ss
	
	MOV AL, 20H
	OUT 20H,AL
		
	IRET
	
ROUT ENDP
DW 20 DUP(?)
LAST_BYTE:

CHECK_TAIL PROC NEAR   ;проверка наличия строки /un в хвосте программы 

	push dx
	push cx
	push si
	
	mov ah, 02h
	
	mov cl, es:[80h]		;число символов в хвосте	
	cmp cl, 4
	jne another_tail
	
	mov si, 82h
	
	mov dl, es:[si]		;1ый символ
	cmp dl, '/'
	jne another_tail
	
	inc si
	mov dl, es:[si]		;2ой символ
	cmp dl, 'u'
	jne another_tail
	
	inc si
	mov dl, es:[si]		;3ий символ
	cmp dl, 'n'
	jne another_tail
	
	pop si
	pop	cx
	pop dx
	
	mov al, 1
	ret

another_tail:
	pop si
	pop	cx
	pop dx
	
	mov al, 0
	ret
CHECK_TAIL ENDP

ERR	DB "! Handler is already set!", '$'

MAIN PROC near

	mov ax, CODE
	mov ds, ax
	
	mov ax, 2
	call CHECK_TAIL
	
	cmp al, 1
	je un
	
	mov Save_PSP, es   ;сохранение PSP 
	mov ah, 35H
	mov al, 1CH 
	int 21H
	mov Save_IP, bx 
	mov Save_CS, es 
	
	mov ah, 2	;проверка, установлен ли обработчик
	mov si, 3
	mov dl, es:[si]
	int 21h
	cmp dl, 'E'
	jne continue
	
	inc si
	mov dl, es:[si]
	int 21h
	cmp dl, 'r'
	jne continue
	
	inc si
	mov dl, es:[si]
	int 21h
	cmp dl, 'r'
	jne continue
	
	inc si
	mov dl, es:[si]
	int 21h
	cmp dl, 'o'
	jne continue
	
	inc si
	mov dl, es:[si]
	int 21h
	cmp dl, 'r'
	jne continue
	

	mov ax, CODE
	mov ds, ax
	lea dx, ERR
	mov ah, 09h
	int 21h
	
	jmp exit
	
continue:
	push ds					;устанавливаем написанное прерывание в поле векторов прерываний		
	mov dx, OFFSET ROUT					 
	mov ax, SEG ROUT 
	mov ds, ax 
	mov ah, 25H 
	mov al, 1CH 
	int 21H 
	pop ds

	mov dx, OFFSET LAST_BYTE + 100h  ;оставляем процедуру прерывания резидентной в памяти
	mov cl,4
	shr dx,cl
	inc dx
	mov ah, 31h
	int 21h
	
un:
	mov ah, 35h
	mov al, 1Ch 
	int 21h

	cli  ;выгружаем обработчик
	push ds
	mov si, 11
	mov dx, es:[si] 
	mov si, 9
	mov ax, es:[si] 
	mov ds, ax
	mov ah, 25h
	mov al, 1Ch
	int 21h
	pop ds
	sti
	
	mov si, 13
	mov ax, es:[si]
	push ax
	mov es, ax
	
	mov si, 2Ch
	mov ax, es:[si]
	mov es, ax
	
	mov ah, 49h		
	int 21h	
	
	pop es			
	mov ah, 49h	
	int 21h	
	
exit:	
	; выход в DOS
	xor al,al
	mov ah,4Ch
	int 21h

MAIN ENDP
CODE ENDS

STACKSG	SEGMENT STACK 
	DW 64 DUP(?)
STACKSG	ENDS
	END MAIN
	

	
