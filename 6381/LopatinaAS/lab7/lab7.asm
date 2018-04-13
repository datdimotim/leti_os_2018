ASSUME CS:CODE, ds:DATA, ss:AStack
AStack SEGMENT STACK
	DW 64 DUP(?)
AStack ENDS

DATA		SEGMENT
	err_1_7  	db 'The memory block is destroyed (code 7)', 0dh, 0ah, '$'
    err_1_8	 	db 'Not enought memory to perform the function (code 8)', 0dh, 0ah, '$'
    err_1_9	 	db 'Wrong adress of memory block (code 9)', 0dh, 0ah, '$'
	err_2	    db 'Overlay program was not loaded', 0dh, 0ah, '$'						
	err_2_1		db 'Non-existen function (code 1)', 0dh, 0ah, '$'   		
	err_2_2   	db 'File not found (code 2)', 0dh, 0ah, '$'								
	err_2_3   	db 'Way not found (code 3)', 0dh, 0ah, '$'								
	err_2_4   	db 'Too many open files (code 4)', 0dh, 0ah, '$'						
	err_2_5   	db 'No acsess (code 5)', 0dh, 0ah, '$'									
	err_2_8   	db 'Low memory(code 8)', 0dh, 0ah, '$'							
	err_2_10  	db 'Incorrect environment (code 10)', 0dh, 0ah, '$'					
	err_3	    db 'Overlay size not defined', 0dh, 0ah, '$'					
	err_3_2	    db 'File not found (code 2)', 0dh, 0ah, '$'   							
	err_3_3     db 'Way not found (code 3)', 0dh, 0ah, '$'			
	
	name1		db	'ovl1.ovl',0
	name2		db	'ovl2.ovl',0	
	
	adr 		dd 	0
	keep_PSP 	dw 	0
	ovl_adr     dw 	0
	DTA 		db 	43 dup (0), '$'
	DTA_path    db	64	dup (0), '$'
DATA 		ENDS

CODE	SEGMENT
;----------------------------
OVL_SIZE PROC ;Определяем размер оверлея
	push es
	push bx
	push si
	push ds
	push dx
	mov dx, seg DTA
	mov ds, dx
	lea dx, DTA	
	mov ax, 1A00h ;Установка адреса для DTA
	int 21h
	pop dx
	pop ds
		
	push ds
	push dx
	mov cx, 0 
	mov dx, seg DTA_path	
	mov ds, dx
	lea dx, DTA_path ;Указатель на строку, содержащую путь к оверлею
	mov ax, 4E00h
	int 21h
	pop dx
	pop ds
	jnc without_err
	
	lea dx, err_3
	call OUTPUT_PROC
	cmp ax, 2
	je err_3_2_out
	cmp ax, 3
	je err_3_3_out
		
err_3_2_out:
	lea dx, err_3_2
	call OUTPUT_PROC
	jmp end_1
	
err_3_3_out:
	lea dx, err_3_3
	call OUTPUT_PROC
	jmp end_1
	
without_err:
	push es
	push bx
	push si
	lea si, DTA
	add si, 1Ch	;В буфере старшее слово размера файла
	mov bx, [si]	
	sub si, 2	
	mov bx, [si]
	push cx
	mov cl, 4
	shr bx, cl ;Переводим в параграфы 
	pop cx
	mov ax, [si+2] 
	push cx
	mov cl, 12
	sal ax, cl	;Переводим в байты, а затем в параграфы
	pop cx
	add bx, ax	
	inc bx
	inc bx
		
	mov ax, 4800h ;Выделение памяти
	int 21h			
	mov ovl_adr, ax
	pop si
	pop bx
	pop es

end_1:
	pop si
	pop bx
	pop es
	ret
OVL_SIZE  ENDP
;----------------------------
FIND_PATH	PROC
	push ax
	push bx
	push cx
	push dx
	push si
	push di
	push es
	
	mov es, keep_PSP
	mov ax, es:[2Ch]
	mov es, ax
	mov bx, 0
	mov cx, 2
		
env_loop:
	inc cx
	mov al, es:[bx]
	inc bx
	cmp al, 0
	jz 	end_env
	loop env_loop
		
end_env:
	cmp byte ptr es:[bx], 0
	jnz env_loop
	add bx, 3
	lea si, DTA_path
		
path_loop:
	mov al, es:[bx]
	mov [si], al
	inc si
	inc bx
	cmp al, 0
	jz 	end_path
	jmp path_loop
	
end_path:	
	sub si, 9
	mov di, bp
		
replace_loop:
	mov ah, [di]
	mov [si], ah
	cmp ah, 0
	jz 	end_replace
	inc di
	inc si
	jmp replace_loop
	
end_replace:
	pop es
	pop di
	pop si
	pop dx
	pop cx
	pop bx
	pop ax
	ret
FIND_PATH	ENDP	
;----------------------------
CALL_OVL	PROC
	push ax
	push bx
	push cx
	push dx
	push bp
		
	mov bx, seg ovl_adr
	mov es, bx
	lea bx, ovl_adr	
		
	mov dx, seg DTA_path
	mov ds, dx	
	lea dx, DTA_path	
		
	push ss
	push sp
		
	mov ax, 4B03h	
	int 21h
	jnc without_err_2
	
	lea dx, err_2
	call OUTPUT_PROC
	
	cmp ax, 1
	je err_2_1_out
	cmp ax, 2
	je err_2_2_out
	cmp ax, 3
	je err_2_3_out
	cmp ax, 4
	je err_2_4_out
	cmp ax, 5
	je err_2_5_out
	cmp ax, 8
	je err_2_8_out
	cmp ax, 10
	je err_2_10_out
	jmp end_2
	
err_2_1_out:
	lea dx, err_2_1
	call OUTPUT_PROC
	jmp end_2
	
err_2_2_out:
	lea dx, err_2_2
	call OUTPUT_PROC
	jmp end_2
	
err_2_3_out:
	lea dx, err_2_3
	call OUTPUT_PROC
	jmp end_2

err_2_4_out:
	lea dx, err_2_4
	call OUTPUT_PROC
	jmp end_2

err_2_5_out:
	lea dx, err_2_5
	call OUTPUT_PROC
	jmp end_2

err_2_8_out:
	lea dx, err_2_8
	call OUTPUT_PROC
	jmp end_2

err_2_10_out:
	lea dx, err_2_10
	call OUTPUT_PROC
	jmp end_2

without_err_2:
	mov ax, seg DATA
	mov ds, ax	;Восстанавливаем ds
	mov ax, ovl_adr
	mov word ptr adr+2, ax
	call adr
	mov ax, ovl_adr
	mov es, ax
	mov ax, 4900h
	int 21h
	mov ax, seg DATA
	mov ds, ax
	
end_2:
	pop sp
	pop ss
	mov es, keep_PSP
	pop bp
	pop dx
	pop cx
	pop bx
	pop ax	
	ret
CALL_OVL  	ENDP
;----------------------------
OUTPUT_PROC PROC NEAR ;Вывод на экран сообщения
	push ax
	mov  ah, 09h
	int  21h
	pop	 ax
	ret
OUTPUT_PROC ENDP
;----------------------------
Main 	PROC  
	mov ax, seg DATA
	mov ds, ax
	mov keep_PSP, es

	;Освобождение памяти
	lea bx, ENDPROG
	mov cl,4h
	shr bx,cl
	mov ah,4ah
	int 21h
	jnc success ; CF=0
	
	cmp ax, 7			
	je err_1_7_out 
	cmp ax, 8			
	je err_1_8_out
	cmp ax, 9		
	je err_1_8_out 

err_1_7_out:
	lea dx, err_1_7
	call OUTPUT_PROC
	jmp quit
	
err_1_8_out:
	lea dx, err_1_8
	call OUTPUT_PROC
	jmp quit

err_1_9_out:
	lea dx, err_1_9
	call OUTPUT_PROC
	jmp quit
	
success:
	lea bp, name1
	call FIND_PATH
	call OVL_SIZE
	call CALL_OVL
	
	lea bp, name2
	call FIND_PATH
	call OVL_SIZE
	call CALL_OVL
	
quit:
	xor al, al
	mov ah, 4ch
	int 21h	
Main ENDP

ENDPROG:
CODE ENDS
END Main