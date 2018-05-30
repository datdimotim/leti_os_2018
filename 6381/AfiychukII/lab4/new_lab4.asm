STACK SEGMENT STACK
	DW 256 DUP (?)
STACK ENDS

MY_STACK SEGMENT STACK
	DW 32 DUP (?)
MY_STACK ENDS

DATA SEGMENT
	str_loaded DB 'New interruption is succesfully loaded!',0DH,0AH,'$'
	str_already_loaded DB 'New interruption has been already loaded!',0DH,0AH,'$'
	str_unloaded DB 'New interruption is unloaded!',0DH,0AH,'$'
	endl db 0DH,0AH,'$'
DATA ENDS

CODE SEGMENT
	ASSUME CS:CODE, DS:DATA, ES:DATA, SS:STACK
START: JMP MAIN


; Сокращение для функции вывода.
PRINT_DX proc near
	mov AH,09h
	int 21h
	ret
PRINT_DX endp

; Установка позиции курсора
SET_CURSOR_POSITION PROC 
	push AX
	push BX
	push CX
	mov AH,2
	mov BH,0
	int 10h
	pop CX
	pop BX
	pop AX
	ret
SET_CURSOR_POSITION ENDP

; Получение позиции курсора
; Вход: BH = видео страница
; Выход: DH, DL = текущие строка, колонка курсора
;		 CH, CL = текущие начальная, конечная строки
GET_CURSOR_POSITION PROC
	push AX
	push BX
	push CX
	mov AH,3
	mov BH,0
	int 10h
	pop CX
	pop BX
	pop AX
	ret
GET_CURSOR_POSITION ENDP

; Обработчик прерывания
ROUT proc far 
	jmp ROUT_begin

	; Data
	SIGNATURE DB 'SOAP' ; идентификатор 
	KEEP_CS DW 0 
	KEEP_IP DW 0 
	KEEP_PSP DW 0
	IS_LOADED DB 0 
	str_counter DB 'Number of handler calls (00000)$' ;счётчик
	KEEP_SS DW 0
	KEEP_AX DW 0	
	KEEP_SP DW 0

ROUT_begin:
	mov KEEP_AX, ax
	mov KEEP_SS, ss
	mov KEEP_SP, sp
	mov ax, seg MY_STACK ;устанавливаем собственный стек
	mov ss, ax
	mov sp, 32h
	mov ax, KEEP_ax
	
	push ax
	push dx
	push ds
	push es

	cmp IS_LOADED, 1
	je ROUT_restore_default
	call GET_CURSOR_POSITION
	push DX ; в dx текущее положение курсора
	mov DH,0 ; строка
	mov DL,0 ; столбик
	call SET_CURSOR_POSITION

ROUT_number_of_interaptions:	
	push ax
	push bx
	push si 
	push ds
	mov ax,SEG str_counter
	mov ds,ax
	mov bx,offset str_counter
	add bx,26 ;смещение к последней цифре (хардкод) - 2

	mov si,3
next_number:
		mov ah,[bx+si]
		inc ah
		cmp ah,58 ; сравниваем с 9
	jne ROUT_after_adding_1
		mov ah,48 ; присваиваем 0
		mov [bx+si],ah
		dec si
		cmp si, 0
	jne next_number

ROUT_after_adding_1:
	mov [bx+si],ah
    pop ds
    pop si
	pop bx
	pop ax

	push es 
	push bp
	mov ax,SEG str_counter
	mov es,ax
	mov ax,offset str_counter
	mov bp,ax
	mov ah,13h 
	mov al,0 
	mov cx,31 ; длина строки
	mov bh,0
	int 10h
	pop bp
	pop es
	
	; возврат положения курсора
	pop dx
	call SET_CURSOR_POSITION
	jmp ROUT_end

	; Восстановление дефолтного вектора и освобождение памяти
ROUT_restore_default:
	CLI ; команда игнорирования прерываний от внешних устройств
	; восстаналвиваем вектор
	mov dx,KEEP_IP
	mov ax,KEEP_CS
	mov ds,ax
	mov ah,25h 
	mov al,1Ch 
	int 21h
	; Освобождаем памятт после засевшего (словно партизана) резидента
	mov es, KEEP_PSP
	mov es, es:[2Ch]
	mov ah, 49h
	int 21h 
	mov es, KEEP_PSP
	mov ah, 49h 
	int 21h	
	STI ; останов игнорирования прерываний

ROUT_end:
	pop es
	pop ds
	pop dx
	pop ax
	mov ss, KEEP_SS
	mov sp, KEEP_SP
	mov ax, KEEP_AX	
	iret
ROUT endp

; Проверка состояния загрузки нового прерывания в память
CHECK_HANDLER proc near
	mov ah,35h 
	mov al,1Ch 
	int 21h ; в es bx получим адрес обработчика прерываний
	mov si, offset SIGNATURE 
	sub si, offset ROUT ; в si смещение сигнатуры от начала функции
	
	; сравниваем  с идеалом
	mov ax,'OS'
	cmp ax,es:[bx+si]
	jne not_loaded
	mov ax, 'PA'
	cmp ax,es:[bx+si+2] 
	je loaded
	; Загружаем новый Обработчик
not_loaded:
	call SET_HANDLER
	; Вычисляем память для резидента
	mov dx,offset LAST_BYTE ; в байтах
	mov cl,4 ;в параграфы в dx
	shr dx,cl
	inc dx
	add dx,CODE ;прибавляем адрес code seg
	sub dx,KEEP_PSP ;вычитаем адрес psp
	xor ax,ax
	mov ah,31h
	int 21h 

; Проверка аргумента cmd
loaded: 
	push es
	push ax
	mov ax,KEEP_PSP 
	mov es,ax
	cmp byte ptr es:[82h],'/' 
	je next_symbol
	cmp byte ptr es:[82h],'|' 
	jne args_false
next_symbol:
	cmp byte ptr es:[83h],'u' 
	jne args_false
	cmp byte ptr es:[84h],'n'
	je do_unload

args_false:
	pop ax
	pop es
	mov dx,offset str_already_loaded
	call PRINT_DX
	ret

; Выгружаем свой Обработчик
do_unload:
	pop ax
	pop es
	mov byte ptr es:[BX+SI+10],1
	mov dx,offset str_unloaded
	call PRINT_DX
	ret
CHECK_HANDLER endp

;установка написанного прерывания в поле векторов прерываний
SET_HANDLER proc near 
	push dx
	push ds

	mov ah,35h
	mov al,1Ch
	int 21h; es:bx
	mov KEEP_IP,bx 
	mov KEEP_CS,es

	mov dx,offset ROUT
	mov ax,seg ROUT
	mov ds,ax
	mov ah,25h
	mov al,1Ch
	int 21h

	pop ds
	mov dx,offset str_loaded
	call PRINT_DX
	pop dx
	ret
SET_HANDLER ENDP 


MAIN:
	mov AX,DATA
	mov DS,AX
	mov KEEP_PSP,ES
	call CHECK_HANDLER
	xor AL,AL
	mov AH,4Ch ;выход 
	int 21H
LAST_BYTE:
	CODE ENDS	
END START