ASSUME CS:CODE, DS:DATA, SS:AStack
AStack SEGMENT STACK
	DW 64 DUP(?)
AStack ENDS

CODE SEGMENT

INTERRUPT PROC FAR
	jmp function
;DATA
	AD_PSP dw ?
	SR_PSP dw ?
	keep_cs dw ?
	keep_ip dw ?
	is_loaded dw 0FFDAh
	scan_code db 2h, 3h, 4h, 5h, 6h, 7h, 8h, 9h, 0Ah, 0Bh, 82h, 83h, 84h, 85h, 86h, 87h, 88h, 89h, 8Ah, 8Bh, 00h
	newtable db '  abcdefghij'
	ss_keeper dw ?
	sp_keeper dw ?
	ax_keeper dw ?
	inter_stack dw 64 dup (?)


function:
	mov ss_keeper, ss
 	mov sp_keeper, sp
 	mov ax_keeper, ax
 	mov ax, seg inter_stack
 	mov ss, ax
 	mov sp, 0
 	mov ax, ax_keeper

	push bx
	push cx
	push dx
	push ax
	;Считывание номера клавиши
	sub ax, ax
	mov ax,40h
	mov es,ax
	mov al,es:[17h]
	cmp al,00000010b
	je not_processing
	in al, 60h
	;Проверка на требуемые скан-коды

	push ds
	push ax
	mov ax, SEG scan_code
	mov ds, ax
	pop ax
	mov dx, offset scan_code
	;dx - смещение символов, al - сам символ
	push bx
	push cx
	mov bx, dx
	sub ah, ah

	;Сравнение кодов
for_compare:
	mov cl, byte ptr [bx]
	cmp cl, 0h
	je end_compare
	cmp al, cl
	jne no_equally
	;Совпадает
	mov ah, 01h
no_equally:
	;Не совпадает
	inc bx
	jmp for_compare
end_compare:
	pop cx
	pop bx
	pop ds

	cmp ah, 01h
	je processing
	jmp not_processing

not_processing:
	;Возврат к стандартному обработчику прерывания
	pop ax
	mov ss, ss_keeper
	mov sp, sp_keeper
	pushf
	push keep_cs
	push keep_ip
	iret
	processing:
	;Обработка прерывания
	push bx
	push cx
	push dx

	cmp al,80h
	ja go

	push es
	push ds
	push ax

	mov ax, seg newtable
	mov ds, ax
	mov bx, offset newtable
	pop ax

	xlatb
	pop ds
	write_to_buffer:
	;Запись в буфер клавиатуры
	mov ah, 05h
	mov cl, al
	sub ch, ch
	int 16h
	or al, al
	jnz cleaning
	pop es
	go:
	jmp @ret
	;Очистка буфера и повторение
	cleaning:
	push ax
	mov ax, 40h
	mov es, ax
	mov word ptr es:[1Ah], 001Eh
	mov word ptr es:[1Ch], 001Eh
	pop ax
	jmp write_to_buffer
	@ret:
	;Отработка аппаратного прерывания
	in al, 61h
	mov ah, al
	or al, 80h
	out 61h, al
	xchg ah, al
	out 61h, al
	mov al, 20h
	out 20h, al

	;Востановление регистров
	pop dx
	pop cx
	pop bx

	pop ax
	mov ax, ss_keeper
 	mov ss, ax
 	mov ax, ax_keeper
 	mov sp, sp_keeper
	;pop ax       ;восстановление ax
	iret
INTERRUPT ENDP

LAST_BYTE PROC
LAST_BYTE ENDP

ISLOADED PROC near
	push dx
        push es
	push bx

	mov ax,3509h ;получение вектора прерываний
	int 21h

	mov dx,es:[bx+11]
	cmp dx,0FFDAh ;проверка на совпадение кода
	je int_is_loaded
	mov al,0h
	pop bx
	pop es
	pop dx
	ret
int_is_loaded:
	mov al,01h
  pop bx
	pop es
	pop dx
	ret
ISLOADED ENDP

CHECK_UNLOAD_FLAG PROC near
	push es
	mov ax,AD_PSP
	mov es,ax
	xor bx,bx
	inc bx


	mov al,es:[81h+bx]
	inc bx
	cmp al,'/'
	jne unload_end

	mov al,es:[81h+bx]
	inc bx
	cmp al,'u'
	jne unload_end

	mov al,es:[81h+bx]
	inc bx
	cmp al,'n'
	jne unload_end

	mov al,1h

unload_end:
	pop es
	ret
CHECK_UNLOAD_FLAG ENDP

LOAD PROC near
	push ax
	push bx
	push dx
	push es

	mov ax,3509h
	int 21h
	mov keep_ip,bx
	mov keep_cs,es

	push ds
	mov dx,offset INTERRUPT
	mov ax,seg INTERRUPT
	mov ds,ax
	mov ax,2509h
	int 21h
	pop ds

	mov dx,offset int_loaded
	mov ah,09h
	int 21h

	pop es
	pop dx
	pop bx
	pop ax
	ret
LOAD ENDP

UNLOAD PROC near
	push ax
	push bx
	push dx
	push es

	mov ax,3509h
	int 21h

	cli
	push ds
	mov dx,es:[bx+9]   ;IP стандартного
	mov ax,es:[bx+7]   ;CS стандартного
	mov ds,ax
	mov ax,2509h
	int 21h
	pop ds
	sti

	mov dx,offset int_unload    ;сообщение о выгрузке
	mov ah,09h
	int 21h

;Удаление MCB
	push es

	mov cx,es:[bx+3]
	mov es,cx
	mov ah,49h
	int 21h

	pop es
	mov cx,es:[bx+5]
	mov es,cx
	int 21h

	pop es
	pop dx
	pop bx
	pop ax
	ret
UNLOAD ENDP

Main PROC far

	mov bx,02Ch
	mov ax,[bx]
	mov SR_PSP,ax
	mov AD_PSP,ds  ;сохраняем PSP
	sub ax,ax
	xor bx,bx

	mov ax,data
	mov ds,ax
	call CHECK_UNLOAD_FLAG   ;Загрузка или выгрузка(проверка параметра)
	cmp al,1h
	je un_load

	call ISLOADED   ;Установлен ли разработанный вектор прерывания
	cmp al,01h
	jne al_loaded

	mov dx,offset int_al_loaded	;Уже установлен(выход с сообщение)
	mov ah,09h
	int 21h

	mov ah,4Ch
	int 21h

al_loaded:

;Загрузка
	call LOAD
;Оставляем обработчик прерываний в памяти
	mov dx,offset LAST_BYTE
	mov cl,4h
	shr dx,cl
	inc dx
	add dx,1Ah

	mov ax,3100h
	int 21h

;Выгрузка
un_load:

	call ISLOADED
	cmp al,0h
	je not_loaded

  call UNLOAD

	mov ax,4C00h
	int 21h

not_loaded:
	mov dx,offset int_not_loaded      ;Если резидент не установлен, то нежелательно выгружать стандартный ВП
	mov ah,09h
	int 21h

	mov ax,4C00h
	int 21h


Main ENDP
CODE ENDS

DATA SEGMENT
	int_not_loaded db 'Резидент не загружен',13,10,'$'
	int_al_loaded db 'Резидент уже загружен',13,10,'$'
	int_loaded db 'Резидент загружен',13,10,'$'
	int_unload db 'Резидент был выгружен',13,10,'$'
DATA ENDS
END Main
