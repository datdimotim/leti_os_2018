.286

;============================;
STACK_S SEGMENT STACK
	DW 100h DUP(?)
STACK_S ENDS

;============================;
DATA SEGMENT

	KEEP_SP	dw 0h
	KEEP_SS	dw 0h
	;;;;;;
	PSP_COM			db	'PSP.COM'
	RET_AL			db	'AL =   $'
	;;;;;;
	_4Ah_7			db	'Free memory Error: Memory control unit destroyed', 0Ah, '$'
	_4Ah_8			db	'Free memory Error: Not enough memory to perform the function', 0Ah, '$'
	_4Ah_9			db	'Free memory Error: Wrong address of the memory block', 0Ah, '$'
	;;;;;;
	_ER_LAUNCH_1	db	'Launch Error: The function number is not found', 0Ah, '$'
	_ER_LAUNCH_2	db	'Launch Error: File not found', 0Ah, '$'
	_ER_LAUNCH_5	db	'Launch Error: Disk error', 0Ah, '$'
	_ER_LAUNCH_8	db	'Launch Error: Insufficient memory', 0Ah, '$'
	_ER_LAUNCH_10	db	'Launch Error: Incorrect environment string', 0Ah, '$'
	_ER_LAUNCH_11	db	'Launch Error: Incorrect format', 0Ah, '$'
	;;;;;;
	_RET_MESSAGE_0	db	0Ah, 'Program exit normally', 0Ah, '$'
	_RET_MESSAGE_1	db	0Ah, 'Program exit by Ctrl-Break', 0Ah, '$'
	_RET_MESSAGE_2	db	0Ah, 'Program exit by device error', 0Ah, '$'
	_RET_MESSAGE_3	db	0Ah, 'Program exit as resident', 0Ah, '$'
	

	;-Блок параметров-;
	;
	 ParBlock		dw	0h
					dw	DATA, offset CMD_Num_Char
					dd	0h
					dd	0h
	
	;-Командная строка-;
	;
	CMD_Num_Char	db	0h
	CMD_STR			db  81h dup(0)
	
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
; Ошибка запуска
ERROR_LAUNCH proc near
	
	cmp  AX, 6
	je   ERR_8_10_11
	
		cmp  AX, 2
		je   ERROR_LAUNCH_2
		jg   ERROR_LAUNCH_5
		
		ERROR_LAUNCH_1:
			mov  DX, offset _ER_LAUNCH_1
			jmp  ERROR_LAUNCH_PRINT
			
		ERROR_LAUNCH_2:
			mov  DX, offset _ER_LAUNCH_2
			jmp  ERROR_LAUNCH_PRINT
			
		ERROR_LAUNCH_5:
			mov  DX, offset _ER_LAUNCH_5
			jmp  ERROR_LAUNCH_PRINT
	
	ERR_8_10_11:
		
		cmp  AX, 10
		je   ERROR_LAUNCH_10
		jg   ERROR_LAUNCH_11
		
		ERROR_LAUNCH_8:
			mov  DX, offset _ER_LAUNCH_8
			jmp  ERROR_LAUNCH_PRINT
			
		ERROR_LAUNCH_10:
			mov  DX, offset _ER_LAUNCH_10
			jmp  ERROR_LAUNCH_PRINT
			
		ERROR_LAUNCH_11:
			mov  DX, offset _ER_LAUNCH_11	
	
	ERROR_LAUNCH_PRINT:
		mov  BX, AX
		
		mov  AH, 09h
		int  21h
	
	ret
ERROR_LAUNCH ENDP

;------------------------;
; Код завершения
RET_MESSAGE proc near
	cmp  AH, 0
	jne   RET_MESSAGE_1_2_3
	
	RET_MESSAGE_0:
		mov  DX, offset _RET_MESSAGE_0
		jmp  RET_MESSAGE_PRINT
		
	
	RET_MESSAGE_1_2_3:
		cmp  AH, 2
		je   RET_MESSAGE_2
		jg   RET_MESSAGE_3
		
		RET_MESSAGE_1:
			mov  DX, offset _RET_MESSAGE_1
			jmp  RET_MESSAGE_PRINT
			
		RET_MESSAGE_2:
			mov  DX, offset _RET_MESSAGE_1
			jmp  RET_MESSAGE_PRINT
			
		RET_MESSAGE_3:
			mov  DX, offset _RET_MESSAGE_1
			
			
	RET_MESSAGE_PRINT:		
		mov  AH, 09h
		int  21h
		
		mov  AH, AL
		shr  AL, 4
		cmp  AL, 10
		js   CIFR
			add  AL, 7h
		CIFR:
		add  AL, 30h
		mov  byte ptr DS:[offset RET_AL + 5], AL
		
		mov  AL, AH
		and  AL, 0Fh
		cmp  AL, 10
		js   NE_BUKB
			add  AL, 7h
		NE_BUKB:
		add  AL, 30h
		mov  byte ptr DS:[offset RET_AL + 6], AL
	
		mov  AH, 09h
		mov  DX, offset RET_AL
		int  21h
		
	ret
RET_MESSAGE ENDP
	
;------------------------;
MAIN proc far	
	push DS
	sub  AX,AX
	push AX
	
;;;;;;;;;;;;;;; освобождение памяти

	mov  BX, DS					;
	neg  BX						;
	add  BX, CODE				;
	add  BX, offset last_byte	;
	shr  BX, 4					; BX = (-"Адрес PSP"+"Адрес кода"+"байт в коде") / 4
	add  BX, 0AAh				; столько параграфов занимает PSP.COM вместе со своим PSP
	
	
	mov  AH, 4Ah				;
	int  21h					; освобождаем память
	
	jnc  good_4Ah
		call ERROR_4Ah			;
		mov  AH, 4Ch			; на случай ошибки 
		int  21h				; освобождения памяти
		
good_4Ah:
;;;;;==Создаём командную строку==;;;;;
	mov  BX, DATA				;		
	mov  ES, BX					;
	mov  DI, offset CMD_STR		; ES:DI -> CMD_STR
	
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
	mov  CX, 7						;
	mov  DS, BX						;
	mov  SI, offset PSP_COM			; Заменяем имя исполняемого файла
			
	rep movsb	

;;;;++++Сохраняемся перед запуском++++;;;;
	mov  KEEP_SP, SP
	mov  KEEP_SS, SS
	
;;;;++++Пуск++++;;;;
	mov  BX, offset ParBlock
	mov  DX, offset CMD_STR	
	
	mov  AX, 4B00h
	int  21h
	
;;;;++++Восстановление после запуска++++;;;;
	mov  BX, DATA
	mov  DS, BX
	
	mov  SP, KEEP_SP
	mov  SS, KEEP_SS
	
;;~~~Обработка результатов~~~;;
	jnc   SUCCESS_LAUNCH		
		call ERROR_LAUNCH		
		jmp  exit				
		
	SUCCESS_LAUNCH:				
		mov  AH, 4Dh			
		int  21h				
		
		call RET_MESSAGE		
		
exit:
	mov  AH, 4Ch
	int  21h

MAIN ENDP
last_byte:
CODE ENDS
END MAIN