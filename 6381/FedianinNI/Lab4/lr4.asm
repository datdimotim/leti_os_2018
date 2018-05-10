INT_STACK SEGMENT STACK
	DW 64 DUP (?)
INT_STACK ENDS


STACK SEGMENT STACK
	DW 64 DUP (?)
STACK ENDS
;---------------------------------------------------------------
DATA SEGMENT
	AlreadyLoaded DB 'User interruption is already loaded!',0DH,0AH,'$'
	Unloaded DB 'User interruption is Unloaded!',0DH,0AH,'$'
	Loaded DB 'User interruption is loaded!',0DH,0AH,'$'
DATA ENDS
;---------------------------------------------------------------
CODE SEGMENT
 ASSUME CS:CODE, DS:DATA, ES:DATA, SS:STACK
START: JMP MAIN
;---------------------------------------------------------------
PRINT_A_STR PROC 	NEAR ;вывод на экран 
		push 	AX
		mov 	AH, 09h
		int 	21h
		pop 	AX
		ret
PRINT_A_STR ENDP
;---------------------------------------------------------------
; Установка позиции курсора
SetCursor PROC
		push 	AX
		push 	BX
		push 	CX
		mov 	AH,02h
		mov 	BH,00h
		int 	10h
		pop 	CX
		pop 	BX
		pop 	AX
		ret
SetCursor ENDP
;---------------------------------------------------------------
; Получение позиции курсора
; Вход: BH = видео страница
; Выход: DH, DL = текущие строка, колонка курсора
;		 CH, CL = текущие начальная, конечная строки
GetCursor PROC
		push 	AX
		push 	BX
		push 	CX
		mov 	AH,03h
		mov 	BH,00h
		int 	10h
		pop 	CX
		pop 	BX
		pop 	AX
		ret
GetCursor ENDP
;---------------------------------------------------------------
; Функция вывода символа из AL
OutputAL PROC
		push 	AX
		push 	BX
		push 	CX
		mov 	AH,09h   ;писать символ в текущей позиции курсора
		mov 	BH,0     ;номер видео страницы
		mov 	BL,07h
		mov 	CX,1     ;число экземпляров символа для записи
		int 	10h      ;выполнить функцию
		pop 	CX
		pop 	BX
		pop 	AX
		ret
OutputAL ENDP
;---------------------------------------------------------------
Rout PROC FAR ;обработчик прерывания
		jmp 	RoutCode
RoutData:
		Signature 	DB '0000'
		KeepCS 		DW 0
		KeepIP 		DW 0
		KeepPSP 	DW 0 ;и PSP
		DeleteFlag 	DB 0 ;переменная, по которой определяется, надо выгружать прерывание или нет
		KeepSS 		DW 0
		KeepAX 		DW 0	
		KeepSP 		DW 0
		Counter 	DB '0 $' ;счётчик
RoutCode:
		mov 	KeepAX, AX ;сохраняем ax
		mov 	KeepSS, SS ;сохраняем стек
		mov 	KeepSP, SP
		mov 	AX, seg INT_STACK ;устанавливаем собственный стек
		mov 	SS, AX
		mov 	SP, 64h
		mov 	AX, KeepAX
		push 	DX 
		push 	DS
		push 	ES
		cmp 	DeleteFlag, 1
		je 		RoutRec1
		call 	GetCursor
		push 	DX
		mov 	DH,16h ;DH, DL - строка, колонка (считая от 0) 
		mov 	DL,25h
		call 	SetCursor

RoutCalc:	
	;подсчёт количества прерываний
		push 	SI ;сохранение изменяемых регистров
		push 	CX 
		push 	DS
		mov 	AX,SEG Counter
		mov 	DS,AX
		mov 	SI,offset Counter
		mov 	AH,[SI]
		inc 	AH
		mov 	[SI],AH ;возвращаем
		cmp 	AH,33h ;если не больше 2
		jne 	EndCalc
		mov 	AH,30h ;обнуляем
		mov 	[SI],AH
		jne 	EndCalc
		mov 	DH,30h
		mov 	[SI-3],DH
RoutRec1:
		cmp 	DeleteFlag, 1
		je 		RoutRec
EndCalc:
		pop 	DS
		pop 	CX
		pop 	SI
		mov 	AL,Counter
		or 		AL,30h
		call 	OutputAL
		int 	10h
		
		pop 	DX
		call 	SetCursor
		jmp 	RoutEnd

	;восстановление вектора прерывания
RoutRec:
		CLI ;запрещение прерывания
		mov 	DX,KeepIP
		mov 	AX,KeepCS
		mov 	DS,AX ;DS:DX = вектор прерывания: адрес программы обработки прерывания
		mov 	AH,25h 
		mov 	AL,1Ch 
		int 	21h ;восстанавливаем вектор
		mov 	ES, KeepPSP 
		mov 	ES, ES:[2Ch]
		mov 	AH, 49h  
		int 	21h
		mov 	ES, KeepPSP
		mov 	AH, 49h
		int 	21h
		STI
RoutEnd:
		pop 	ES ;восстановление регистров
		pop 	DS
		pop 	DX
		mov 	SS, KeepSS
		mov 	SP, KeepSP
		mov 	AX, KeepAX
		iret
Rout ENDP
;---------------------------------------------------------------
CheckINT PROC ;проверка прерывания
	;проверка, установлено ли пользовательское прерывание с вектором 1Ch
		mov 	AH,35h 
		mov 	AL,1Ch 
		int 	21h 
				
		
		mov 	SI, offset Signature 
		sub 	SI, offset Rout 
		
		mov 	AX,'00' ;сравним известное значение сигнатуры
		cmp 	AX,ES:[BX+SI] 
		jne 	NotLoaded 
		cmp 	AX,ES:[BX+SI+2] 
		jne 	NotLoaded 
		jmp 	ItLoaded ;если значения совпадают, то резидент установлен
	
NotLoaded: ;установка пользовательского прерывания
		call 	SetINT
		mov 	DX,offset LastByte
		mov 	CL,4
		shr 	DX,CL
		inc 	DX
		add 	DX,CODE
		sub 	DX,KeepPSP
		xor 	AL,AL
		mov 	AH,31h 
		int 	21h
		
ItLoaded: ;смотрим, есть ли в хвосте /un , тогда нужно выгружать
		push 	ES
		push 	AX
		mov 	AX,KeepPSP 
		mov 	ES,AX
		cmp 	byte ptr ES:[82h],'/' ;сравниваем аргументы
		jne 	NotUnload 
		cmp 	byte ptr ES:[83h],'u'
		jne 	NotUnload 
		cmp 	byte ptr ES:[84h],'n' 
		je 		Unload ;совпадают
NotUnload: ;если не /un
		pop 	AX
		pop 	ES
		mov 	dx,offset AlreadyLoaded
		call 	PRINT_A_STR
		ret
	;выгрузка пользовательского прерывания
Unload: ;если /un
		pop 	AX
		pop 	ES
		mov 	byte ptr ES:[BX+SI+10],1
		mov 	dx,offset Unloaded
		call 	PRINT_A_STR
		ret
CheckINT ENDP
;---------------------------------------------------------------
SetINT PROC ;установка написанного прерывания в поле векторов прерываний
		push 	DX
		push 	DS
		mov 	AH,35h
		mov 	AL,1Ch 
		int		21h
		mov 	KeepIP,BX 
		mov		KeepCS,ES 
		mov 	DX,offset Rout 
		mov 	AX,seg Rout 
		mov 	DS,AX 
		mov 	AH,25h 
		mov 	AL,1Ch 
		int 	21h
		pop 	DS
		mov 	DX,offset Loaded ;вывод сообщения
		call 	PRINT_A_STR
		pop 	DX
		ret
SetINT ENDP 
;---------------------------------------------------------------
MAIN:
		mov 	AX,DATA
		mov 	DS,AX
		mov 	KeepPSP,ES ;сохранение PSP
		call 	CheckINT ;проверка прерывания
		xor 	AL,AL
		mov 	AH,4Ch ;выход 
		int 	21H
LastByte:
	CODE ENDS
	END START
