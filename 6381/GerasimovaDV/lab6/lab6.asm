.MODEL SMALL
.DATA
;ДАННЫЕ
string_1      db  '	 Процесс успешно завершён! (Код: 0)', 0DH, 0AH, '$'
string_2      db  '  Неверный номер функции', 0DH, 0AH, '$'
string_3      db  '  Файл не найден', 0DH, 0AH, '$'
string_4      db  '  Ошибка диска', 0DH, 0AH, '$'
string_5      db  '  Недостаточно памяти', 0DH, 0AH, '$'
string_6      db  '  Неправильная строка среды', 0DH, 0AH, '$'
string_7      db  '  Неверный формат', 0DH, 0AH, '$'
string_8   		db  '  Разрушен управляющий блок памяти', 0DH, 0AH, '$'
string_9			db  '	 Недостаточно памяти для выполнения функции', 0DH, 0AH, '$'
string_10			db  '	 Неверный адрес блока памяти', 0DH, 0AH, '$'
string_11			db	'	 Завершение по Ctrl + C (Код: 1)', 0DH, 0AH, '$'
string_12			db	'	 Завершение по ошибке устройства (Код: 2)', 0DH, 0AH, '$'
string_13			db	'	 Завершение по функции 31h, оставляющей программу резидентной (Код: 3)', 0DH, 0AH, '$'
EOL db "$"
filename db 50 dup(0)
param dw 7 dup(?)

keep_SS dw ?
keep_SP dw ?

.STACK 200h

.CODE
;ПРОЦЕДУРЫ
;Вывод на экран
PRINT PROC
	push ax
	mov ah, 09h
	int 21h
	pop ax
	ret
PRINT ENDP
;-----------------------------------------------------
; КОД
BEGIN PROC FAR
	mov ax, @data
	mov ds, ax

	push si
	push di
	push es
	push dx
	mov es, es:[2Ch]
	xor si, si
	lea di, filename
env_char:
	cmp byte ptr es:[si], 00h
	je env_crlf
	inc SI
	jmp env_next
env_crlf:
	inc si
env_next:
	cmp word ptr es:[si], 0000h
	jne env_char
	add si, 4
abs_char:
	cmp byte ptr es:[si], 00h
	je vot
	mov dl, es:[si]
	mov [di], dl
	inc si
	inc di
	jmp abs_char
vot:
	sub di, 5
	mov dl, '2'
	mov [di], dl
	add di, 2
	mov dl, 'c'
	mov [di], dl
	inc di
	mov dl, 'o'
	mov [di], dl
	inc di
	mov dl, 'm'
	mov [di], dl
	inc di
	mov dl, 0h
	mov [di], dl
	inc di
	mov dl, EOL
	mov [di], dl
	pop dx
	pop es
	pop di
	pop si
	lea bx, ALL_MEM
	mov ax, es
	sub bx, ax
	mov cl, 4
	shr bx, cl
	mov ah, 4Ah
	int 21h
	jnc no_errors_4A
err:
	cmp ax, 7
	je err_7
	cmp ax, 8
	je err_8
	cmp ax, 9
	je err_9

err_7:
	lea dx, string_8
	call PRINT
	jmp Exit

err_8:
	lea dx, string_9
	call PRINT
	jmp Exit

err_9:
	lea dx, string_10
	call PRINT
	jmp Exit

no_errors_4A:
	push ds
	pop es
	lea dx, filename
	lea bx, param
	mov keep_SS, ss
	mov keep_SP, sp
	mov ax, 4b00h
	int 21h
	mov ss, keep_SS
	mov sp, keep_SP
	jnc no_errors_4B
	cmp AX, 1
	je err_1

	cmp AX, 2
	je err_2

	cmp AX, 5
	je err_5

	cmp AX, 8
	je err8

	cmp AX, 10
	je err_10

	cmp AX, 11
	je err_11

err_1:
	lea DX, string_2
	call PRINT
	jmp Exit

err_2:
	lea DX, string_3
	call PRINT
	jmp Exit

err_5:
	lea DX, string_4
	call PRINT
	jmp Exit

err8:
	lea DX, string_5
	call PRINT
	jmp Exit

err_10:
	lea DX, string_6
	call PRINT
	jmp Exit

err_11:
	lea DX, string_7
	call PRINT
	jmp Exit
no_errors_4B:
	mov AX, 4D00h
	int 21h

	cmp AH, 0
	je normal

	cmp AH, 1
	je ctrl_c

	cmp AH, 2
	je err_dev

	cmp AH, 3
	je err_31

normal:
	lea DX, string_1
	call PRINT
	jmp Exit
ctrl_c:
	lea DX, string_11
	call PRINT
	jmp Exit

err_dev:
	lea DX, string_12
	call PRINT
	jmp Exit

err_31:
	lea DX, string_13
	call PRINT
	jmp Exit

Exit:
	; Выход в DOS

		mov ah, 4Ch
		int 21h

BEGIN      ENDP
;-----------------------------------------------------
ALL_MEM PROC
ALL_MEM ENDP
;-----------------------------------------------------
END BEGIN
