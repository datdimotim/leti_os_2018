.286

;============================;
STACK_S SEGMENT STACK
	DW 100h DUP(?)
STACK_S ENDS

;============================;
DATA SEGMENT

	KEEP_PSP		dw	0h
	;;;;;;
	OV_1			db	'OV_1.OVL'
	OV_2			db	'OV_2.OVL'
	;;;;;;
	_4Ah_7			db	'Free memory Error: Memory control unit destroyed', 0Ah, '$'
	_4Ah_8			db	'Free memory Error: Not enough memory to perform the function', 0Ah, '$'
	_4Ah_9			db	'Free memory Error: Wrong address of the memory block', 0Ah, '$'
	;;;;;;
	_4Eh_2			db	'Error determining size: File not found', 0Ah, '$'
	_4Eh_3			db	'Error determining size: Route not found', 0Ah, '$'
	;;;;;;
	_ER_ALLOC_MEM	db	'Error: Memory not allocated', 0Ah, '$'
	_ER_DEALLOC_MEM	db	'Error: Memory not deallocated', 0Ah, '$'
	;;;;;;
	_ER_LOAD_1		db	'Launch Error: Non-existent function', 0Ah, '$'
	_ER_LOAD_2		db	'Launch Error: File not found', 0Ah, '$'
	_ER_LOAD_3		db	'Launch Error: Route not found', 0Ah, '$'
	_ER_LOAD_4		db	'Launch Error: Too many open files', 0Ah, '$'
	_ER_LOAD_5		db	'Launch Error: No access', 0Ah, '$'
	_ER_LOAD_8		db	'Launch Error: Low memory', 0Ah, '$'
	_ER_LOAD_10		db	'Launch Error: Incorrect environment', 0Ah, '$'
	;;;;;;

	;-Блок параметров-;
	ParBlock		dw	0h, 0h
	
	;-Командная строка-;
	CMD_Num_Char	db	0h
	CMD_STR			db  80h dup(0)
	
DATA ENDS

;============================;
CODE SEGMENT
	ASSUME CS:CODE, DS:DATA, SS:STACK_S	
	
;------------------------;
; Ошибка освобождения памяти
ERROR_4Ah proc near
	mov AX, DATA
	mov DS, AX

	cmp AX, 8
	je  ERROR_4Ah_8
	jg  ERROR_4Ah_9
	
	ERROR_4Ah_7:
		mov  DX, offset _4Ah_7
		jmp  ERROR_4Ah_PRINT
		
	ERROR_4Ah_8:
		mov  DX, offset _4Ah_8
		jmp  ERROR_4Ah_PRINT		
		
	ERROR_4Ah_9:
		mov  DX, offset _4Ah_9		
		
	ERROR_4Ah_PRINT:
		mov  AH, 09h
		int  21h
	
	ret
ERROR_4Ah ENDP

;------------------------;
; Ошибка при поиске файла оверлея
ERROR_4Eh	proc near
	
	cmp  AX, 2
	jg   ERROR_4Eh_3
	
	ERROR_4Eh_2:
		mov  DX, offset _4Eh_2
		jmp  ERROR_4Eh_PRINT
		
	ERROR_4Eh_3:
		mov  DX, offset _4Eh_3
	
	ERROR_4Eh_PRINT:
		mov  AH, 09h
		int  21h
	
	ret
ERROR_4Eh	ENDP

;------------------------;
; Ошибка при выделении памяти под оверлей
ERROR_ALLOC_MEM	proc near
	mov  AH, 09h
	mov DX, offset _ER_ALLOC_MEM
	int 21h
	
	ret
ERROR_ALLOC_MEM	ENDP

;------------------------;
; Ошибка при загрузке оверлея
ERROR_LOAD proc near
	
	cmp  AX, 4
	je   ER_LOAD_4
	jg   ER_LOAD_5_8_10
	
	ER_LOAD_1_2_3:
		cmp  AX, 2
		je   ER_LOAD_2
		jg   ER_LOAD_3
		
		ER_LOAD_1:
			mov  DX, offset _ER_LOAD_1
			jmp  ER_LOAD_PRINT
	
		ER_LOAD_2:
			mov  DX, offset _ER_LOAD_2
			jmp  ER_LOAD_PRINT
			
		ER_LOAD_3:
			mov  DX, offset _ER_LOAD_3
			jmp  ER_LOAD_PRINT
			
		ER_LOAD_4:
			mov  DX, offset _ER_LOAD_4
			jmp  ER_LOAD_PRINT
	
		ER_LOAD_5_8_10:
			cmp  AX, 8
			je   ER_LOAD_8
			jg   ER_LOAD_10
			
			ER_LOAD_5:
				mov  DX, offset _ER_LOAD_5
				jmp  ER_LOAD_PRINT
		
			ER_LOAD_8:
				mov  DX, offset _ER_LOAD_8
				jmp  ER_LOAD_PRINT
				
			ER_LOAD_10:
				mov  DX, offset _ER_LOAD_10
				jmp  ER_LOAD_PRINT
	
	ER_LOAD_PRINT:
		mov  AH, 09h
		int  21h

	ret
ERROR_LOAD ENDP

;------------------------;
; Ошибка освобождения памяти из-под оверлея
ERROR_DEALLOC_MEM	proc near
		mov  AH, 09h					
		mov  DX, offset _ER_DEALLOC_MEM	
		int  21h	
	ret
ERROR_DEALLOC_MEM ENDP

;------------------------;
; Установка, запуск и удаление оверлея
OVERLAY	proc near
	pusha
	push DS
	push ES
;;;;;==Создаём командную строку==;;;;;
push SI		
	mov  BX, DATA				;		
	mov  ES, BX					;
	mov  DI, offset CMD_STR		; ES:DI -> CMD_STR
	
	mov  AX, ES:KEEP_PSP		;
	mov  DS, AX					;
	mov  AX, DS:[2Ch]			;
	mov  DS, AX					;
	mov  SI, 0					; DS:SI -> адрес среды
	
	cikl:							;
		cmp  word ptr DS:[SI], 0	;
		je   break					;
			inc  SI					;
			jmp  cikl				; Идём по среде, пока
	break:							; не наткнёмся на 0000
	
	add SI, 4						; DS:SI -> маршрут данной программы
	
	cikl2:							;
		cmp  byte ptr DS:[SI], 0	;
			je   break2				;
				movsb				;
				jmp cikl2			; 
	break2:							; Копируем маршрут данной программы
	
	sub  DI, 6						;
	mov  DS, BX						;
pop SI			
	rep movsb	
	
;;;;++++Размер оверлая++++;;;;
	mov  DX, offset CMD_STR				; Находим файл оверлея
	mov  CX, 0							; в текущей 
	mov  AH, 4Eh						; директории
	int  21h							; 
	
	jnc  good_4Eh						; 
		call ERROR_4Eh					;
		mov  AH, 4Ch					; На случай отсутствия
		int  21h						; файла или маршрута
good_4Eh:
	
	push DS								;
		mov  AX, KEEP_PSP				;
		mov  DS, AX						;
		mov  AX, word ptr DS:[9Ah]		;
		mov  DX, word ptr DS:[9Ch]		; Помещаем в DX:AX
	pop  DS								; размер файла оверлея
	
	mov  CX, 4							;
	div  CX								;
	inc  AX								; Размер в параграфах
	
;;;;++++Выделение памяти под оверлай++++;;;;
	mov  BX, AX							;
	mov  AH, 48h						;
	int  21h							; Выделяем память
	
	jnc  MEM_ALLOC_SUCCESS				;
		call ERROR_ALLOC_MEM			; На случай ошибки
		mov  AH, 4Ch					; при выделении
		int  21h						; памяти
	MEM_ALLOC_SUCCESS:					;

;;;;++++Подготовка к запуску оверлея++++;;;;
	mov  word ptr DS:[ParBlock+2], AX	; Сохраняем выделенный сегмент
	mov  word ptr DS:[ParBlock], 100h
	
	mov  DX, offset CMD_STR				;
	mov  BX, offset ParBlock+2			; Загражаем 
	mov  AX, 4B03h						; оверлей
	int  21h							; в память
	
	jnc  SUCCESS_LOAD					;
		call ERROR_LOAD					; На случай ошибки
		mov  AH, 4Dh					; загрузки 
		int  21h						; овелея
	SUCCESS_LOAD:						;
	
;;;;++++Пуск и назад++++;;;;
	mov  AX, word ptr DS:[ParBlock+2]
	sub  AX, 10h
	mov  word ptr DS:[ParBlock+2], AX
		
	call  dword ptr DS:ParBlock			; Вызов оверлея
	
;;~~~Освобождение памяти~~~;;
	mov  AX, DS:[ParBlock+2]			;
	add  AX, 10h						;
	mov  ES, AX							;
	mov  AH, 49h						;
	int  21h							; Освобождаем память
	
	jnc  good_free_mem					;
		call ERROR_DEALLOC_MEM			; На случай ошибки
		mov  AH, 4Ch					; освобождения 
		int  21h						; памяти
	good_free_mem:						;

	pop ES
	pop DS
	popa
	ret
OVERLAY ENDP

;------------------------;
;------------------------;
;------------------------;
MAIN proc far	
	push DS
	sub  AX,AX
	push AX
	
;;;;;== Освобождение памяти ==;;;;;

	mov  BX, DS					;
	neg  BX						;
	add  BX, CODE				;
	shl  BX, 4					;
	add  BX, offset last_byte	;
	shr  BX, 4					;
	inc  BX						;
	
	mov  AH, 4Ah				;
	int  21h					; освобождаем память
	
	jnc  good_4Ah				;
		call ERROR_4Ah			;
		mov  AH, 4Ch			; на случай ошибки 
		int  21h				; освобождения памяти	
	good_4Ah:					;

;;;;;== Устанавливаем регистры данных ==;;;;;
	mov  AX, DATA
	mov  DS, AX	
		mov  KEEP_PSP, ES
	mov  ES, AX

;;;;;==  Вызовы оверлеев  ==;;;;;
	mov  CX, 8					;
	mov  SI, offset OV_1		;
		call OVERLAY			; Оверлей 1
	
	mov  CX, 8					;
	mov  SI, offset OV_2		;
		call OVERLAY			; Оверлей 2
		
;;;;;== Завершение работы ==;;;;;
	mov  AH, 4Ch
	int  21h

MAIN ENDP
	last_byte:
CODE ENDS
END MAIN