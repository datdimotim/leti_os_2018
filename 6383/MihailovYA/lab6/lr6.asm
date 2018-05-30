CODE SEGMENT
 	ASSUME CS:CODE, DS:DATA, ES:DATA, SS:_STACK
START: JMP BEGIN

PRINT PROC near
	push ax
	mov AH,09h
	int 21h
	pop ax
	ret
PRINT ENDP

TETR_TO_HEX PROC near
	and AL,0Fh
	cmp AL,09
	jbe NEXT
	add AL,07
NEXT:
	add AL,30h
	ret
TETR_TO_HEX ENDP

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

PODG PROC
	; освобождаем ненужную память(es - сегмент psp, bx - объем нужной памяти):
	mov ax,_STACK
	sub ax,CODE
	add ax,100h
	mov bx,ax
	mov ah,4ah
	int 21h
	jnc podg_skip1
		call EXEC_FILE
	podg_skip1:
	
	; подготавливаем блок параметров:
	call BLOCK_OF_PARAMETR
	
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
		mov PATH_FILE[si],al
		cmp byte ptr es:[bx+si],00h
		jne PUT_ZIKL
	
	; избавляемся от названия программы в пути
	add si,1
	PUT_ZIKL2:
		mov PATH_FILE[si],0
		sub si,1
		cmp byte ptr es:[bx+si],'\'
		jne PUT_ZIKL2
	; добавляем имя запускаем программы
	add si,1
	mov PATH_FILE[si],'O'
	add si,1
	mov PATH_FILE[si],'S'
	add si,1
	mov PATH_FILE[si],'_'
	add si,1
	mov PATH_FILE[si],'L'
	add si,1
	mov PATH_FILE[si],'A'
	add si,1
	mov PATH_FILE[si],'B'
	add si,1
	mov PATH_FILE[si],'_'
	add si,1
	mov PATH_FILE[si],'2'
	add si,1
	mov PATH_FILE[si],'.'
	add si,1
	mov PATH_FILE[si],'C'
	add si,1
	mov PATH_FILE[si],'O'
	add si,1
	mov PATH_FILE[si],'M'
	pop ax
	pop si
	pop bx
	pop es	
	
	ret
PODG ENDP


; Функция освобождения лишней памяти
FREE_MEM PROC
; Вычисляем в BX необходимое количество памяти для этой программы в параграфах
		mov ax,_STACK 
		mov bx,es
		sub ax,bx ;Вычитаем сегментный адрес PSP
		add ax,32h ;Прибавляем размер стека в параграфах
		mov bx,ax
; Попытка освободить лишнюю память
		mov ah,4Ah
		int 21h
		jnc FREE_MEM_SUCCESS
; Обработка ошибок
		mov dx,offset FREE_MEM_ERROR
		call PRINT
		cmp ax,7
		mov dx,offset MCB_DESTR_ERROR
		je FREE_MEM_PRINT_ERROR
		cmp ax,8
		mov dx,offset NOT_ENOUGH_MEMORY_ERROR
		je FREE_MEM_PRINT_ERROR
		cmp ax,9
		mov dx,offset WRNG_MEM_BL_ADDR_ERROR
		
		FREE_MEM_PRINT_ERROR:
		call PRINT
		mov dx,offset STRENDL
		call PRINT
; Выход в DOS
		xor AL,AL
		mov AH,4Ch
		int 21H
	
	FREE_MEM_SUCCESS:
	ret
FREE_MEM ENDP
; Функция создания блока параметров
BLOCK_OF_PARAMETR PROC
	mov ax, es:[2Ch]
	mov PARAMATR_BLOCK,ax ;Кладём сегментный адрес среды
	mov PARAMATR_BLOCK+2,es ; Сегментный адрес параметров командной строки(PSP)
	mov PARAMATR_BLOCK+4,80h ; Смещение параметров командной строки
	ret
BLOCK_OF_PARAMETR ENDP
; Функция запуска процесса
EXEC_FILE PROC
	
	
	mov dx,offset STRENDL
	call PRINT
	
		; Устанавливаем DS:DX на имя вызываемой программы
		mov dx,offset PATH_FILE
		; Смотрим, есть ли хвост
		xor ch,ch
		mov cl,es:[80h]
		cmp cx,0
		je EXEC_FILE_NO_TAIL ;Если нет хвоста, то используем стандартное имя вызываемой программы
		mov si,cx ; si - номер копируемого символа
		push si ; Сохраняем кол-во символов
		EXEC_FILE_CYCLE:
			mov al,es:[81h+si]
			mov [offset PATH_FILE+si-1],al			
			dec si
		loop EXEC_FILE_CYCLE
		pop si
		mov [PATH_FILE+si-1],0 ; Кладём в конец 0
		mov dx,offset PATH_FILE ; Хвост есть, используем его
		EXEC_FILE_NO_TAIL:
		; Устанавливаем ES:BX на блок параметров
		push ds
		pop es
		mov bx,offset PARAMATR_BLOCK

		mov KEEP_SP, SP
		mov KEEP_SS, SS
	
		mov ax,4b00h
		int 21h
		jnc EXEC_FILE_GO
	
		push ax
		mov ax,DATA
		mov ds,ax
		pop ax
		mov SS,KEEP_SS
		mov SP,KEEP_SP
	; Обработка ошибок:
		cmp ax,1
		mov dx,offset WRNG_FUCN_NUMB_ERROR
		je EXEC_FILE_ERROR
		cmp ax,2
		mov dx,offset YOUR_FILE_IS_NOT_FOUND_ERROR
		je EXEC_FILE_ERROR
		cmp ax,5
		mov dx,offset DISK_ERROR
		je EXEC_FILE_ERROR
		cmp ax,8
		mov dx,offset NOT_ENOUGH_MEM_2D_ERROR
		je EXEC_FILE_ERROR
		cmp ax,10
		mov dx,offset WRNG_ENV_STR_ERROR
		je EXEC_FILE_ERROR
		cmp ax,11
		mov dx,offset WRNG_WRONG_FORMAT_ERROR	
		je EXEC_FILE_ERROR
		mov dx,offset UNKNOWN_ERROR_WHTS_THE_MATTER
        
		EXEC_FILE_ERROR:
		call PRINT
		mov dx,offset STRENDL
		call PRINT
	; Выход в DOS
		xor AL,AL
		mov AH,4Ch
		int 21H
		
	EXEC_FILE_GO:
	mov ax,4d00h
	int 21h
	; Вывод причины завершения
		cmp ah,0
		mov dx,offset PROGRAMM_FNSHD_WTH_NORMAL_END
		je RUN_CHILD_PRINT_END_RSN
		cmp ah,1
		mov dx,offset BREAK_CTRLC
		je RUN_CHILD_PRINT_END_RSN
		cmp ah,2
		mov dx,offset DEVICE_ERROR
		je RUN_CHILD_PRINT_END_RSN
		cmp ah,3
		mov dx,offset RESIDENT_END
		je RUN_CHILD_PRINT_END_RSN
		mov dx,offset REASON_IS_UNKNOWN
		RUN_CHILD_PRINT_END_RSN:
		call PRINT
		mov dx,offset STRENDL
		call PRINT
	; Вывод кода завершения:
		mov dx,offset END_CODE
		call PRINT
		call BYTE_TO_HEX
		push ax
		mov ah,02h
		mov dl,al
		int 21h
		pop ax
		xchg ah,al
		mov ah,02h
		mov dl,al
		int 21h
		mov dx,offset STRENDL
		call PRINT
	ret
EXEC_FILE ENDP
;---------------------------------------
BEGIN:
	mov ax,data
	mov ds,ax
	
	call FREE_MEM
	;call BLOCK_OF_PARAMETR
	call PODG
	call EXEC_FILE
	
	xor AL,AL
	mov AH,4Ch
	int 21H
CODE ENDS

DATA SEGMENT
; Ошибки:
	FREE_MEM_ERROR	 		db 'Error when freeing memory: $'
	MCB_DESTR_ERROR 		db 'MCB is destroyed$'
	NOT_ENOUGH_MEMORY_ERROR 		db 'Not enough memory for function processing$'
	WRNG_MEM_BL_ADDR_ERROR 	db 'Wrong addres of memory block$'
	UNKNOWN_ERROR_WHTS_THE_MATTER			db 'Unknown error$'
	
	WRNG_FUCN_NUMB_ERROR		db 'Function number is wrong$'
	YOUR_FILE_IS_NOT_FOUND_ERROR			db 'File is not found$'
	DISK_ERROR			db 'Disk error$'
	NOT_ENOUGH_MEM_2D_ERROR		db 'Not enough memory$'
	WRNG_ENV_STR_ERROR		db 'Wrong environment string$'
	WRNG_WRONG_FORMAT_ERROR		db 'Wrong format$'
; Причины завершения вызываемой программы
	PROGRAMM_FNSHD_WTH_NORMAL_END		db 'Normal end$'
	BREAK_CTRLC		db 'End by Ctrl-Break$'
	DEVICE_ERROR	db 'End by device error$'
	RESIDENT_END		db 'End by 31h function$'
	REASON_IS_UNKNOWN			db 'End by unknown reason$'
	END_CODE		db 'End code: $'
		
	STRENDL 		db 0DH,0AH,'$'
; Блок параметров. Перед загрузкой программы на него должен указывать ES:BX
	PARAMATR_BLOCK 		dw 0 ; Сегментный адрес среды
					dd 0 ; Сегментный адрес и смещение параметров командной строки
					dd 0 ; Сегмент и смещение первого FCB
					dd 0 ; Второго

	PATH_FILE  	db 50h dup (0)
	;PATH_TO_FILE	db 'C:\OS_LAB_2.COM', 0 ;Путь до файла

	KEEP_SS 		dw 0
	KEEP_SP 		dw 0

DATA ENDS

_STACK SEGMENT STACK
	dw 100h dup (?)
_STACK ENDS

END START