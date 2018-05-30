CODE SEGMENT
 ASSUME CS:CODE, DS:DATA, ES:DATA, SS:ASTACK
START: JMP BEGIN
; ПРОЦЕДУРЫ
;---------------------------------------
TETR_TO_HEX PROC near
	and AL,0Fh
	cmp AL,09
	jbe NEXT
	add AL,07
NEXT: add AL,30h
	ret
TETR_TO_HEX ENDP
;---------------------------------------
BYTE_TO_HEX PROC near
	push CX
	mov AH,AL
	call TETR_TO_HEX
	xchg AL,AH
	mov CL,4
	shr AL,CL
	call TETR_TO_HEX 
	pop CX 
	ret
BYTE_TO_HEX ENDP
;---------------------------------------
PRINT PROC
	push ax
	mov AH,09h
	int 21h
	pop ax
	ret
PRINT ENDP
;---------------------------------------
PODG PROC
	; освобождаем ненужную память(es - сегмент psp, bx - объем нужной памяти):
	mov ax,ASTACK
	sub ax,CODE
	add ax,100h
	mov bx,ax
	mov ah,4ah
	int 21h
	jnc podg_skip1
		call OBR_OSH
	podg_skip1:
	
	; подготавливаем блок параметров:
	call PODG_PAR
	
	; определяем путь до программы:
	push es
	push bx
	push si
	push ax
	mov es,es:[2ch] ; в es сегментный адрес среды
	mov bx,-1
	SREDA_ZIKL:
		add bx,1
		cmp word ptr es:[bx],0000h
		jne SREDA_ZIKL
	add bx,4
	mov si,-1
	PUT_ZIKL:
		add si,1
		mov al,es:[bx+si]
		mov PROGR[si],al
		cmp byte ptr es:[bx+si],00h
		jne PUT_ZIKL
	
	; избавляемся от названия программы в пути
	add si,1
	PUT_ZIKL2:
		mov PROGR[si],0
		sub si,1
		cmp byte ptr es:[bx+si],'\'
		jne PUT_ZIKL2
	; добавляем имя запускаем программы
	add si,1
	mov PROGR[si],'l'
	add si,1
	mov PROGR[si],'a'
	add si,1
	mov PROGR[si],'b'
	add si,1
	mov PROGR[si],'2'
	add si,1
	mov PROGR[si],'.'
	add si,1
	mov PROGR[si],'e'
	add si,1
	mov PROGR[si],'x'
	add si,1
	mov PROGR[si],'e'
	pop ax
	pop si
	pop bx
	pop es	
	
	ret
PODG ENDP
;---------------------------------------
PODG_PAR PROC
	mov ax, es:[2ch]
	mov PARAM, ax
	mov PARAM+2,es ; Сегментный адрес параметров командной строки(PSP)
	mov PARAM+4,80h ; Смещение параметров командной строки
	ret
PODG_PAR ENDP
;---------------------------------------
ZAP_MOD PROC
	; устанавливаем ES:BX на блок параметров
	mov ax,ds
	mov es,ax
	mov bx,offset PARAM
	
	; устанавливаем DS:DX на путь и имя вызываемой программы
	mov dx,offset PROGR
	
	; сохраняем SS и SP:
	mov KEEP_SS, SS
	mov KEEP_SP, SP
	
	; запускаем программу:
	mov ax,4B00h
	int 21h
	
	; восстанавливаем DS, SS, SP:
	push ax
	mov ax,DATA
	mov ds,ax
	pop ax
	mov SS,KEEP_SS
	mov SP,KEEP_SP
	; обрабатываем ошибки:
	jnc zap_mod_skip1
		call OBR_OSH
		jmp zap_mod_konec
	zap_mod_skip1:
	
	; обработка завершения программы:
	call PROV_ZAV
	
	zap_mod_konec:

	ret
ZAP_MOD ENDP
;---------------------------------------
OBR_OSH PROC
	mov dx,offset o
	call PRINT

	mov dx,offset o1
	cmp ax,1
	je osh_pechat
	mov dx,offset o2
	cmp ax,2
	je osh_pechat
	mov dx,offset o7
	cmp ax,7
	je osh_pechat
	mov dx,offset o8
	cmp ax,8
	je osh_pechat
	mov dx,offset o9
	cmp ax,9
	je osh_pechat
	mov dx,offset o10
	cmp ax,10
	je osh_pechat
	mov dx,offset o11
	cmp ax,11
	je osh_pechat
	
	osh_pechat:
	call PRINT
	mov dx,offset STRENDL
	call PRINT
	
	ret
OBR_OSH ENDP
;---------------------------------------
PROV_ZAV PROC
	; получаем в al код завершения, в ah - причину:
	mov al,00h
	mov ah,4dh
	int 21h

	mov dx, offset z0
	cmp ah, 0
	je prov_zav_pech_1
	mov dx,offset z1
	cmp ah,1
	je prov_zav_pech
	mov dx,offset z2
	cmp ah,2
	je prov_zav_pech
	mov dx,offset z3
	cmp ah,3
	je prov_zav_pech
	
	prov_zav_pech_1:
	call PRINT
	mov dx,offset STRENDL
	call PRINT
	mov dx, offset z
	
	prov_zav_pech:
	call PRINT

	cmp ah,0
	jne prov_zav_skip

	; печать кода завершения:
	call BYTE_TO_HEX
	push ax
	mov ah,02h
	mov dl,al
	int 21h
	pop ax
	mov dl,ah
	mov ah,02h
	int 21h
	mov dx,offset STRENDL
	call PRINT
	prov_zav_skip:
	
	ret
PROV_ZAV ENDP
;---------------------------------------
BEGIN:
	mov ax,data
	mov ds,ax
	call PODG
	call ZAP_MOD
	xor AL,AL
	mov AH,4Ch
	int 21H
CODE ENDS
; ДАННЫЕ
DATA SEGMENT	
	; ошибки
	o db 'Ошибка: $'
	o1 db 'Номер функции неверен$'
	o2 db 'Файл не найден$'
	o7 db 'Разрушен управляющий блок памяти$'
	o8 db 'Недостаточный объем памяти$'
	o9 db 'Неверный адрес блока памяти$'
	o10 db 'Неправильная строка среды$'
	o11 db 'Неправильный формат$'
	
	; причины завершения
	z0 db 'Нормальное завершение$'
	z1 db 'Завершение по Ctrl-Break$'
	z2 db 'Завершение по ошибке устройства$'
	z3 db 'Завершение по функции 31h$'
	z db 'Код завершения: $'
		
	STRENDL db 0DH,0AH,'$'
	
	; блок параметров
	PARAM 	dw 0 ; сегментный адрес среды
			dd 0 ; сегмент и смещение командной строки
			dd 0 ; сегмент и смещение первого FCB
			dd 0 ; сегмент и смещение второго FCB
	
	; путь и имя вызываемой программы	
	PROGR db 40h dup (0)
	; переменные для хранения SS и SP
	KEEP_SS dw 0
	KEEP_SP dw 0
DATA ENDS
; СТЕК
ASTACK SEGMENT STACK
	dw 100h dup (?)
ASTACK ENDS
 END START