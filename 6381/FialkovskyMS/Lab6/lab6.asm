CODE SEGMENT
 ASSUME CS:CODE, DS:DATA, ES:DATA, ss:STACK

START: jmp MAIN

; Сокращение для функции вывода.
PRINT_DX proc near
	mov ah,09h
	int 21h
	ret
PRINT_DX endp


; Половина байт AL переводится в символ шестнадцатиричного числа в AL
TETR_TO_HEX	proc near 
    and	al, 0Fh
    cmp	al, 09
    jbe	NEXT 
    add	al, 07
NEXT:	
    add		al, 30h
    ret
TETR_TO_HEX	endp


; Байт AL переводится в два символа шестнадцатиричного числа в AX
BYTE_TO_HEX	proc near 
    push cx
    mov	ah, al 
    call TETR_TO_HEX
    xchg al, ah 
    mov	cl, 4 
    shr	al, cl 
    call TETR_TO_HEX 
    pop	cx 			
    ret
BYTE_TO_HEX	endp


INIT_PARAM_DATA_BLOCK proc
	mov ax, es
	mov ParamDataBlock,0
	mov ParamDataBlock+2, ax
	mov ParamDataBlock+4, 80h
	mov ParamDataBlock+6, ax
	mov ParamDataBlock+8, 5Ch
	mov ParamDataBlock+10, ax
	mov ParamDataBlock+12, 6Ch
	ret
INIT_PARAM_DATA_BLOCK endp


; Освобождение места в памяти
FREE_MEM proc 
	mov bx, offset LAST_BYTE
	mov ax, es ;es-начало
	sub bx, ax
	mov cl, 4h
	shr bx, cl
	; в BX количество параграфов, которые будут выделяться модулю

	mov ah,4Ah 
	int 21h
	jnc NO_ERROR ; CF=0 при отсутствии ошибок
	
	;oбработка ошибок (если CF != 0, то в AX  - код ошибки)
	cmp ax, 7 
	mov dx, offset str_err_mcb_damaged
	je IS_ERROR
	cmp ax, 8 
	mov dx, offset str_err_addr_incorrect
	je IS_ERROR
	cmp ax, 9 
	mov dx, offset str_err_addr_incorrect
	
IS_ERROR:
	call PRINT_DX
	xor al,al
	mov ah,4Ch
	int 21H
NO_ERROR:
	ret
FREE_MEM endp


RUN_PROCESS proc 	
	mov es, es:[2Ch]
	mov si, 0

HANDLE_ENVIR:
	mov dl, es:[si]
	cmp dl, 00
	je DO_END_OF_LINE	
	inc si
	jmp HANDLE_ENVIR

DO_END_OF_LINE:
	inc si
	mov dl, es:[si]
	cmp dl, 00
	jne HANDLE_ENVIR	
	add si, 03
	push di
	lea di, PATH

HANDLE_PATH:
	mov dl, es:[si]
	cmp dl, 00
	je DO_END_OF_LINE_AGAIN	
	mov [di], dl	
	inc di			
	inc si	
	jmp HANDLE_PATH

DO_END_OF_LINE_AGAIN:
	sub di, 05h	
	mov [di], byte ptr '2'	
	mov [di+2], byte ptr 'C'
	mov [di+3], byte ptr 'O'
	mov [di+4], byte ptr 'M'
	mov [di+5], byte ptr 0h
	pop di
	mov KEEP_SP, SP
	mov KEEP_SS, SS
	push ds
	pop es
	mov bx, offset ParamDataBlock
	mov dx, offset PATH
	mov ax, 4B00h
	int 21h
	jnc IS_LOADED
	
	push ax
	mov ax, DATA
	mov ds, ax
	pop ax
	mov SS, KEEP_SS
	mov SP, KEEP_SP
	
	cmp ax, 1
	mov dx, offset str_err_func_number_incorrect
	je SIMPLE_EXIT

	cmp ax, 2
	mov dx, offset str_err_file_not_found
	je SIMPLE_EXIT

	cmp ax, 5
	mov dx, offset str_err_disk
	je SIMPLE_EXIT

	cmp ax, 8
	mov dx, offset str_err_mem_val_incorrect
	je SIMPLE_EXIT

	cmp ax, 10
	mov dx, offset str_err_env_val_incorrect
	je SIMPLE_EXIT

	cmp ax, 11
	mov dx, offset str_err_format_incorrect
	je SIMPLE_EXIT
	
SIMPLE_EXIT:
	call PRINT_DX
	
	xor al ,al
	mov ah, 4Ch
	int 21h
		
IS_LOADED:
	mov ax,4d00h
	int 21h
	
	cmp ah, 0
	mov dx, offset str_end_normal
	je EXIT_WITH_MES
	cmp ah, 1
	mov dx, offset str_end_ctrl_end
	je EXIT_WITH_MES
	cmp ah, 2
	mov dx, offset str_err_device
	je EXIT_WITH_MES
	cmp ah, 3
	mov dx, offset str_end_31h

EXIT_WITH_MES:
	call PRINT_DX
	mov di, offset END_CODE
	call BYTE_TO_HEX
	add di, 0Ah
	mov [di], al
	add di, 1
	xchg ah, al
	mov [di], al
	mov dx, offset END_CODE
	call PRINT_DX
	ret
RUN_PROCESS ENDP


MAIN:
	mov ax, DATA
	mov ds, ax
	call FREE_MEM 
	call INIT_PARAM_DATA_BLOCK
	call RUN_PROCESS

	xor al,al
	mov ah,4Ch ;выход 
	int 21h

LAST_BYTE:
CODE ENDS


DATA SEGMENT
    ParamDataBlock    	dw ? ;сегментный адрес среды
                        dd ? ;сегмент и смещение командной строки
                        dd ? ;сегмент и смещение первого FCB
                        dd ? ;сегмент и смещение второго FCB
    ; end_of_param_block

	str_err_mcb_damaged             DB 0DH, 0AH, 'Memory control unit has been damaged!',0DH,0AH,'$'
	str_err_func_number_incorrect   DB 0DH, 0AH, 'The number of function is incorrect!',0DH,0AH,'$'
	str_err_not_enough_mem          DB 0DH, 0AH, 'Not enough memory to perform the function!',0DH,0AH,'$'
	str_err_addr_incorrect          DB 0DH, 0AH, 'Incorrect address of the memory block!',0DH,0AH,'$'
	str_err_disk                    DB 0DH, 0AH, 'Disk reading error!',0DH,0AH,'$'
	str_err_file_not_found          DB 0DH, 0AH, 'File not found!',0DH,0AH,'$'
	str_err_format_incorrect        DB 0DH, 0AH, 'Incorrect format!',0DH,0AH,'$'
	str_err_mem_val_incorrect       DB 0DH, 0AH, 'Incorrect value of memory!',0DH,0AH,'$'
	str_err_device                  DB 0DH, 0AH, 'Completion-device error!',0DH,0AH,'$'
	str_err_env_val_incorrect       DB 0DH, 0AH, 'Incorrect environment string!',0DH,0AH,'$'
    ; end_of_errors_sector

	str_end_ctrl_end                DB 0DH, 0AH, 'Module has beem ended by Ctrl-Break!',0DH,0AH,'$'
	str_end_normal                  DB 0DH, 0AH, 'Module has been ended is normal way!',0DH,0AH,'$'
	str_end_31h                     DB 0DH, 0AH, 'Completion by function 31h!',0DH,0AH,'$'
    ; end_of_endings_sector

	PATH 	 DB '                                               ',0DH,0AH,'$',0
	KEEP_SS  DW 0
	KEEP_SP  DW 0
	END_CODE DB 'End code:   ',0DH,0AH,'$'
    ; end_of_help_sector
DATA ENDS

STACK SEGMENT STACK
	DW 64 DUP (?)
STACK ENDS

END START