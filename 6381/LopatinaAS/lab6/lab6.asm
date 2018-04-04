ASSUME CS:CODE, DS:DATA, SS:AStack
AStack SEGMENT STACK
	DW 64 DUP(?)
AStack ENDS

DATA SEGMENT
	env_addr	dw ?	; сегментный адрес среды
	cmd			dd ?	; сегмент и смещение командной строки
	seg_of_1FCB	dd ?	; сегмент и смещение первого FCB 
	seg_of_2FCB	dd ?	; сегмент и смещение второго FCB 
	keep_sp		dw ?	
	keep_ss		dw ?	
	path_str 	db '                                               ',0dH,0ah,'$',0h
	EOL			db '   ',0dh,0ah,'$'
	err_1_7  	db 'The memory block is destroyed (code 7)', 0dh, 0ah, '$'
    err_1_8	 	db 'Not enought memory to perform the function (code 8)', 0dh, 0ah, '$'
    err_1_9	 	db 'Wrong adress of memory block (code 9)', 0dh, 0ah, '$'
DATA ENDS

CODE SEGMENT
;----------------------------
OUTPUT_PROC PROC NEAR ;Вывод на экран сообщения
		push ax
		mov  ah, 09h
	    int  21h
	    pop	 ax
	    ret
OUTPUT_PROC ENDP
;----------------------------
COMPLETION_PROC PROC NEAR
	jmp begin_f
	finish   db   'Program finished with code    ', 0dh, 0ah, '$'
	finish_0 db   'Normal completion', 0dh, 0ah, '$'
	finish_1 db   'Completion by Ctrl-Break', 0dh, 0ah, '$'
	finish_2 db   'Completion by device error', 0dh, 0ah, '$'
	finish_3 db   'Completion by 31h function', 0dh, 0ah, '$'
begin_f:
	push ds
	push ax
	push dx
	push bx
	
	mov ax, 4D00h
	int 21h

	push ax
	mov ax, SEG finish
	mov ds, ax
	pop ax
	
	lea dx, finish_0
	cmp ah, 0h
	je output_err_1
	
	lea dx, finish_1
	cmp ah, 1h
	je output_err_1
	
	lea dx, finish_2
	cmp ah, 2h
	je output_err_1
	
	lea dx, finish_3
	cmp ah, 3h
	
output_err_1:
	call OUTPUT_PROC
	lea dx, finish
	mov bx, dx
	add bx, 1Bh
	mov byte ptr [bx], al
	call OUTPUT_PROC
	
	pop bx
	pop dx
	pop ax
	pop ds
	ret
COMPLETION_PROC ENDP
;----------------------------
ERROR_PROC PROC NEAR
	jmp begin2
	err_2	 db 'Program was not downloaded', 0dh, 0ah, '$'
	err_2_1	 db 'Wrong number of the function (code 1)', 0dh, 0ah, '$'
	err_2_2  db 'File not found (code 2)', 0dh, 0ah, '$'
	err_2_5  db 'Disk error (code 5)', 0dh, 0ah, '$'
	err_2_8  db 'Not enought memory (code 8)', 0dh, 0ah, '$'
	err_2_10 db 'Wrong enviroment string (code 10)', 0dh, 0ah, '$'
	err_2_11 db 'Wrong format (code 11)', 0dh, 0ah, '$'
begin2:
	push ds
	push ax
	push dx
	
	push ax
	mov ax, SEG err_2
	mov ds, ax
	pop ax
	
	lea dx, err_2
	call OUTPUT_PROC
	
	lea dx, err_2_1
	cmp ax, 1h
	je output_err_2

	lea dx, err_2_2
	cmp ax, 2h
	je output_err_2
	
	lea dx, err_2_5
	cmp ax, 5h
	je output_err_2
	
	lea dx, err_2_8
	cmp ax, 8h
	je output_err_2
	
	lea dx, err_2_10
	cmp ax, 10h
	je output_err_2
	
	lea dx, err_2_11
	cmp ax, 11h
	
output_err_2:
	call OUTPUT_PROC
	
	pop dx
	pop ax
	pop ds
	ret
ERROR_PROC ENDP
;----------------------------
Main PROC FAR
	mov ax, DATA
	mov ds, ax

	;Освобождение памяти
	lea bx, ENDPROG
	mov cl,4h
	shr bx,cl
	add bx,30h ;размер памяти, необходимый для лаб6
	mov ah,4ah
	int 21h
	jnc success ; CF=0
	
	lea dx, err_1_7
	cmp ax, 7h
	je output_err
	lea dx, err_1_8
	cmp ax, 8h
	je output_err
	lea dx, err_1_9
	output_err:
		call OUTPUT_PROC
		jmp quit

success:
	;Заполнение блока параметров
	mov env_addr, 00h
	
	mov ax, es
	mov word ptr cmd, ax
	mov word ptr cmd+2, 0080h
	
	mov word ptr seg_of_1FCB, ax
	mov word ptr seg_of_2FCB+2, 005ch
	
	mov word ptr seg_of_2FCB,ax
	mov word ptr seg_of_1FCB, 006ch
	
	;Подготовка среды, содержащей имя и путь вызываемой программмы
	;push es
	;push dx
	;push bx
	
	mov es, es:[2Ch]; сегментный адрес среды, передаваемый программе
	mov si, 0
env:
	mov dl, es:[si]
	cmp dl, 00h		; конец строки?
	je EOL_	
	inc si
	jmp env
EOL_:
	inc si
	mov dl, es:[si]
	cmp dl, 00h		;конец среды?
	jne env
	
	add si, 03h	; si указывает на начало маршрута	
	
	push di
	lea di, path_str
path_:
	mov dl, es:[si]
	cmp dl, 00h		;конец маршрута?
	je EOL2	
	mov [di], dl	
	inc di			
	inc si			
	jmp path_
EOL2:
	sub di, 05h	
	mov [di], byte ptr '2'	
	mov [di+2], byte ptr 'C'
	mov [di+3], byte ptr 'O'
	mov [di+4], byte ptr 'M'
	mov [di+5], byte ptr 0h
	
	pop di
	;pop bx
	;pop ds
	;pop es
	
	;Сохраняем содержимое регистров SS и SP переменных		 			
	push ds	
	mov keep_sp, sp		
	mov keep_ss, ss	

	mov ax, DATA
	mov es, ax	;es:bx должен указывать на блок параметров
	lea bx, env_addr
	mov ds, ax	; ds:dx должен указывать на подготовленную строку
	lea dx, path_str	
	
	mov ax, 4B00h	; Вызываем загрузчик OS
	int 21h			
	
	;Восстанавливаем параметры
	pop ds
	mov ss, keep_ss
	mov sp, keep_sp
	
	push ax
	push dx
	push ds
	mov ax, DATA
	mov ds, ax
	lea dx, EOL
	call OUTPUT_PROC
	call OUTPUT_PROC
	pop ds
	pop dx
	pop ax
	
	jnc null_	; CF=0
	call ERROR_PROC
	jmp quit
null_:
	call COMPLETION_PROC

quit:
	xor al, al
	mov ah, 4ch
	int 21h	
Main ENDP

ENDPROG:
CODE ENDS
END Main