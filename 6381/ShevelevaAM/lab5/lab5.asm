
CODE SEGMENT
	ASSUME CS:CODE, DS:CODE , SS:STACKSG

ROUT PROC FAR

jmp start
	String		DB		'Erro'
	Symbol		DB		0
	Save_CS		DW		0 
	Save_IP		DW		0 
	Save_PSP	DW		0

start:

	mov Save_SS, ss   ;сохран€ем старый стек
	mov Save_SP, sp
	
	mov temp, cs
	mov ss, temp
	
	mov sp, offset new_stack 
	add sp, 128    ;передвигаем sp на верхушку стека
	
	push	ax
	
	in	al,60h  
	cmp	al,2dh  ;код клавиши x
	jz	do_req

	pop	ax

	mov ss, Save_SS  ;возвращаем стек
	mov sp, Save_SP
	
	jmp	cs:old_vector


do_req:
	in	al,61h
	mov	ah,al
	or	al,80h
	out	61h,al
	xchg	ah,al
	out	61h,al
	mov	al,20h
	out	20h,al

	push	ax
	push	es

	mov ax,040h
	mov es,ax
	mov al,es:[17h]
	pop	es

	and al,00000100b 		;Ќажат ctrl
	pop	ax
	jnz write_symbol2

	mov cl,03h
	jmp write_symbol3


write_symbol2:
	mov cl,02h

write_symbol3:	
	mov	ah,05h
	mov	ch,00h
	int	16h
	or	al,al
	jnz	skip
	jmp end_rout
	
skip:
	push es
	cli
	mov ax,040h
	mov es,ax
	mov	al,es:[1ah]
	mov	es:[1ah],al
	sti
	int	16h
	pop	es
end_rout:	
	
	pop cx
	pop	es
	pop	ax

	mov ss, Save_SS   ;возвращаем стек
	mov sp, Save_SP	
	
	mov	al,20h
	out	20h,al
	iret
	
	old_vector dd ?
	
ROUT	ENDP
DW 20 DUP(?)

CHECK_TAIL PROC NEAR   ;проверка наличи€ строки /un в хвосте программы 

	push dx
	push cx
	push si
	
	mov al, 02h
	
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
Save_SS		DW		0
Save_SP		DW		0
temp		DW		0


MAIN PROC near

	mov ax, CODE
	mov ds, ax
	
	call CHECK_TAIL
	
	cmp al, 1
	je un     ;переход если есть хвост
	
	mov Save_PSP, es   ;сохранение PSP 
	mov ah, 35H
	mov al, 09H 
	int 21H
	mov Save_IP, bx 
	mov Save_CS, es 
	mov word ptr old_vector + 2,es
	mov word ptr old_vector, bx
	
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
	mov al, 09H 
	int 21H 
	pop ds

	mov dx, OFFSET LAST_BYTE + 100h  ;оставл€ем процедуру прерывани€ резидентной в пам€ти
	mov cl,4
	shr dx,cl
	inc dx
	mov ah, 31h
	int 21h
	
un:               ;хвост есть
	mov ah, 35h
	mov al, 09h 
	int 21h

	cli  ;выгружаем обработчик
	push ds
	
	
	mov si, 10
	mov dx, es:[si]   ;ip
	mov si, 8
	mov ax, es:[si]   ;cs
	mov ds, ax	
	mov ah, 25h
	mov al, 09h
	int 21h
	pop ds
	sti
	
	mov si, 12      ;psp
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

new_stack dw 64 DUP(?)  ;размер нового стека

LAST_BYTE:

CODE ENDS

STACKSG	SEGMENT STACK 
	DW 64 DUP(?)
STACKSG	ENDS
	END MAIN
	

	
