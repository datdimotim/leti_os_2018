DATA SEGMENT

	err1 		db 		'Function is not exist', 0dh, 0ah, '$'
	err2 		db 		'File is not found', 0dh, 0ah, '$'
	err3		db		'Route is not found', 0dh, 0ah, '$'
	err4 		db		'Too many files were opened', 0dh, 0ah, '$'
	err5 		db 		'It is not access', 0dh, 0ah, '$'
	err6 		db 		'Too little memory', 0dh, 0ah, '$'
	err7	 	db 		'Wrong environment', 0dh, 0ah, '$'
    err8		db 		'Control Block was destroyed', 0dh, 0ah, '$' 
	err9 		db 		'Need more memory', 0dh, 0ah, '$' 	
	err10 		db 		'Wrong address of block', 0dh, 0ah, '$'

	DTA			db		43 dup(0)  	
	path		db		255 dup(0) 
	address		dw		?
	func_address	dd	?

	file1 		db 		'ovl1.ov', 0dh, 0ah, '$'
	file2		db		'ovl2.ov', 0dh, 0ah, '$'
DATA ENDS

AStack SEGMENT STACK
	dw 256 dup(?)
AStack ENDS

CODE	SEGMENT
	
.386
ASSUME CS:CODE, DS:DATA, SS:AStack

;-----------------------------
WRITE	PROC	near
		push ax
		mov		ah, 09h
		int		21h
		pop ax
		ret
WRITE	ENDP
;-----------------------------
;-----------------------------
FREE_MEM Proc

	push ax
	push dx
	push bx

	lea  bx, end_
    xor  ax, ax
    mov  ah, 4ah
    int  21h
	jnc no_err
	
	;сравниваем с кодами ошибок
	cmp ax, 7
	je err18
	cmp ax, 8
	je err19
	cmp ax, 9
	je err110
err18:
	lea dx, err8
	call WRITE
	jmp exit
err19:
	lea dx, err9
	call WRITE
	jmp exit
err110:
	lea dx, err10
	call WRITE
exit:
	mov ax, 4Ch
	int 21h

no_err:
	pop bx
	pop dx
	pop ax
	ret
	
FREE_MEM ENDP
;-----------------------------
;-----------------------------
GET_PATH	proc

	push si
	push di
	push es
	push dx
	push cx

	mov es, es:[2Ch]	;сегментный адрес среды
	xor si, si
	lea di, path
cycle1:   
	inc si    
	cmp word ptr es:[si], 0000h
	jne cycle1
	add si, 4           
path_loop:
	cmp byte ptr es:[si], 00h
	je next
	mov dl, es:[si]
	mov [di], dl
	inc si
	inc di
	jmp path_loop
   
next:
	mov si, bp 
	mov cx, 7
	sub di, 8   
cycle2:
	mov dl, ds:[si]
	mov [di], dl
	inc di
	inc si
	loop cycle2

	mov dl, 0h
	mov [di], dl
	inc di
	mov dl, '$'
	mov [di], dl

	pop cx
	pop dx
	pop es
	pop di
	pop si
	ret
	
GET_PATH	ENDP
;-----------------------------
;-----------------------------
ERROR2 proc

	push ax
	push dx
	
	;сравниваем с кодами ошибок
	cmp ax, 1
	je err21
	cmp ax, 2
	je err22
	cmp ax, 3
	je err23
	cmp ax, 4
	je err24
	cmp ax, 5
	je err25
	cmp ax, 8
	je err28
	cmp ax, 10
	je err210

err21:
	lea dx, err1
	call WRITE
	jmp exit__
err22:
	lea dx, err2
	call WRITE
	jmp exit__
err23:
	lea dx, err3
	call WRITE
	jmp exit__
err24:
	lea dx, err4
	call WRITE
	jmp exit__
err25:
	lea dx, err5
	call WRITE
	jmp exit__
err28:
	lea dx, err6
	call WRITE
	jmp exit__
err210:
	lea dx, err7
	call WRITE
exit__:
	pop dx
	pop ax
	ret
	
ERROR2 ENDP
;-----------------------------
;-----------------------------
ERROR1 proc

	push ax
	push dx
	
	;сравниваем с кодами ошибок
	cmp ax, 2	
	je err32
	cmp ax, 3
	je err33

err32:
	lea dx, err2
	call WRITE
	jmp exit_
err33:
	lea dx, err3
	call WRITE
	
exit_:
	pop dx
	pop ax
	ret
	
ERROR1 ENDP
;-----------------------------
;-----------------------------
MEM_OVL proc

	push ax
	push bx
	push es
	push si
	push dx

	lea dx, DTA		;выделяем память под буфер DTA
	mov ax, 1A00h
	int 21h
	
	mov cx, 0		;определяем размер оверлея
	lea dx, path
	mov ax, 4E00h
	int 21h
		
	jnc size_mem	;проверка, были ли ошибки
	call ERROR1
	jmp end_mem
	
size_mem:
	mov si, offset DTA
	add si, 1Ah
	mov bx, [si]	;младшее слово размера файла
	shr bx, 4 
	mov ax, [si+2]	;старшее слово размера файла
	shl ax, 12
	add bx, ax
	add bx, 2
		
	mov ax, 4800h	;отводим память
	int 21h
	mov address, ax	
	
end_mem:
	pop dx
	pop si
	pop es
	pop bx
	pop ax
	ret
	
MEM_OVL endp
;-----------------------------
;-----------------------------
LOAD_OVL PROC

	push ax
	push bx
	push bp
	push dx
	push cx
	push es
	push ss
	push sp

	mov bx, seg address
	mov es, bx			
	lea bx, address		;сегментный адрес среды
	lea dx, path		;путь к оверлею
	
	mov ax, 4B03h
	int 21h

	jnc continue		;проверка, были ли ошибки
	call ERROR2
	jmp end_load
continue:

	;освобождение памяти
	mov ax, address
	mov word ptr func_address + 2, ax
	call func_address
	mov es, ax
	mov ax, 4900h
	int 21h
	
end_load:
	pop sp
	pop ss
	pop es
	pop cx
	pop dx
	pop bp
	pop bx
	pop ax	
	ret
	
LOAD_OVL ENDP
;-----------------------------

MAIN	PROC  

	mov ax, DATA
	mov ds, ax

	call FREE_MEM	;освобождение памяти

	lea bp, file1
	call GET_PATH
	lea dx, path
	call WRITE		
	call MEM_OVL	;выделяет память под оверлей
	call LOAD_OVL	;загружает оверлей, в конце освобождает память

	lea bp, file2
	call GET_PATH
	lea dx, path
	call WRITE		
	call MEM_OVL	;выделяет память под оверлей
	call LOAD_OVL	;загружает оверлей, в конце освобождает память

	mov ah, 4Ch
	int 21h
	
end_:
MAIN ENDP
CODE ENDS
END MAIN