STACK SEGMENT STACK
	DW 64 DUP (?)
STACK ENDS
;---------------------------------------------------------------
DATA SEGMENT
	ALR_LOADED DB 'User interruption is already loaded!',0DH,0AH,'$'
	UNLOADED DB 'User interruption is unloaded!',0DH,0AH,'$'
	IS_LOADDED DB 'User interruption is loaded!',0DH,0AH,'$'
DATA ENDS
;---------------------------------------------------------------
CODE SEGMENT
 ASSUME CS:CODE, DS:DATA, ES:DATA, SS:STACK
START: JMP MAIN
;---------------------------------------------------------------
PRINT PROC NEAR ;вывод на экран 
	push ax
	mov ah, 09h
	int 21h
	pop ax
	ret
PRINT ENDP
;---------------------------------------------------------------
setCurs PROC ;установка позиции курсора; установка на строку 25 делает курсор невидимым
	push AX
	push BX
	push CX
	mov AH,02h
	mov BH,00h
	int 10h ;выполнение
	pop CX
	pop BX
	pop AX
	ret
setCurs ENDP
;---------------------------------------------------------------
getCurs PROC ;функция, определяющая позицию и размер курсора 
	push AX
	push BX
	push CX
	mov AH,03h ;03h читать позицию и размер курсора
	mov BH,00h ;BH = видео страница
	int 10h ;выполнение
	;выход: DH, DL = текущая строка, колонка курсора
	;CH, CL = текущая начальная, конечная строки курсора
	pop CX
	pop BX
	pop AX
	ret
getCurs ENDP
;---------------------------------------------------------------
ROUT PROC FAR ;обработчик прерывания
	jmp ROUT_CODE
ROUT_DATA:
	SIGNATURE DB '0000' ;сигнатура, некоторый код, который идентифицирует резидент
	KEEP_CS DW 0 ;для хранения сегмента
	KEEP_IP DW 0 ;и смещения прерывания
	KEEP_PSP DW 0 ;и PSP
	DELETE DB 0 ;переменная, по которой определяется, надо выгружать прерывание или нет
	COUNTER DB 'Total number of interrupts: 0000 $' ;счётчик
ROUT_CODE:
	push AX ;сохранение изменяемых регистров
	push DX
	push DS
	push ES
	;обработка прерывания
	cmp DELETE, 1
	je ROUT_REC1
	;установка курсора
	call getCurs ;получаем текущее положение курсора 
	push DX ;сохранение положения курсора в стеке
	mov DH,16h ;DH, DL - строка, колонка (считая от 0) 
	mov DL,25h
	call setCurs ;устанавливаем курсор

ROUT_CALC:	
	;подсчёт количества прерываний
	push SI ;сохранение изменяемых регистров
	push CX 
	push DS
	mov AX,SEG COUNTER
	mov DS,AX
	mov SI,offset COUNTER ;для изменения счетчика
	add SI,1Fh ;смещение на последнюю цифру
	;(000*) 
	mov AH,[SI] ;получаем цифру
	inc AH ;увеличиваем её на 1
	mov [SI],AH ;возвращаем
	cmp AH,3Ah ;если не больше 9
	jne END_CALC ;заканчиваем
	mov AH,30h ;обнуляем
	mov [SI],AH ;возвращаем и переходим на следущующую цифру
	;(00*0) 
	mov BH,[SI-1] 
	inc BH 
	mov [SI-1],BH
	cmp BH,3Ah                   
	jne END_CALC 
	mov BH,30h 
	mov [SI-1],BH 
	;(0*00) 
	mov CH,[SI-2] 
	inc CH 
	mov [SI-2],CH 
	cmp CH,3Ah  
	jne END_CALC 
	mov CH,30h 
	mov [SI-2],CH 
	;(*000) 
	mov DH,[SI-3] 
	inc DH 
	mov [SI-3],DH
	cmp DH,3Ah
	jne END_CALC
	mov DH,30h
	mov [SI-3],DH
ROUT_REC1:
	cmp DELETE, 1
	je ROUT_REC
END_CALC:
    pop DS
    pop CX
	pop SI
	;вывод счётчика-строки на экран
	push ES 
	push BP
	mov AX,SEG COUNTER
	mov ES,AX
	mov AX,offset COUNTER
	mov BP,AX ;ES:BP = адрес 
	mov AH,13h ;функция 13h прерывания 10h
	mov AL,00h ;режим вывода
	mov CX,20h ;длина строки
	mov BH,0 ;видео страница
	int 10h
	pop BP
	pop ES
	
	;возвращение курсора
	pop DX
	call setCurs
	jmp ROUT_END

	;восстановление вектора прерывания
ROUT_REC:
	CLI ;запрещение прерывания
	mov DX,KEEP_IP
	mov AX,KEEP_CS
	mov DS,AX ;DS:DX = вектор прерывания: адрес программы обработки прерывания
	mov AH,25h 
	mov AL,1Ch 
	int 21h ;восстанавливаем вектор
	;освобождение памяти, занимаемой резидентом
	mov ES, KEEP_PSP 
	mov ES, ES:[2Ch] ;ES = сегментный адрес (параграф) освобождаемого блока памяти 
	mov AH, 49h ;функция 49h прерывания 21h    
	int 21h ;освобождение распределенного блока памяти
	mov ES, KEEP_PSP ;ES = сегментный адрес (параграф) освобождаемого блока памяти 
	mov AH, 49h ;функция 49h прерывания 21h  
	int 21h	;освобождение распределенного блока памяти
	STI ;разрешение прерывания
ROUT_END:
	pop ES ;восстановление регистров
	pop DS
	pop DX
	pop AX 
	iret
ROUT ENDP
;---------------------------------------------------------------
CHECK_INT PROC ;проверка прерывания
	;проверка, установлено ли пользовательское прерывание с вектором 1Ch
	mov AH,35h 
	mov AL,1Ch 
	int 21h 
			
	
	mov SI, offset SIGNATURE 
	sub SI, offset ROUT 
	
	mov AX,'00' ;сравним известное значение сигнатуры
	cmp AX,ES:[BX+SI] 
	jne NOT_LOADED 
	cmp AX,ES:[BX+SI+2] 
	jne NOT_LOADED 
	jmp LOADED ;если значения совпадают, то резидент установлен
	
NOT_LOADED: ;установка пользовательского прерывания
	call SET_INT ;процедура установки пользовательского прерывания
	;вычисление необходимого количества памяти для резидентной программы
	mov DX,offset LAST_BYTE ;размер в байтах от начала
	mov CL,4 ;перевод в параграфы
	shr DX,CL
	inc DX	;размер в параграфах
	add DX,CODE ;прибавляем адрес сегмента CODE
	sub DX,KEEP_PSP ;вычитаем адрес сегмента PSP
	xor AL,AL
	mov AH,31h 
	int 21h ;оставляем нужное количество памяти
			;(dx - количество параграфов) и выходим в DOS, оставляя программу в памяти резидентно 
		
LOADED: ;смотрим, есть ли в хвосте /un , тогда нужно выгружать
	push ES
	push AX
	mov AX,KEEP_PSP 
	mov ES,AX
	cmp byte ptr ES:[82h],'/' ;сравниваем аргументы
	jne NOT_UNLOAD 
	cmp byte ptr ES:[83h],'u'
	jne NOT_UNLOAD 
	cmp byte ptr ES:[84h],'n' 
	je UNLOAD ;совпадают
NOT_UNLOAD: ;если не /un
	pop AX
	pop ES
	mov dx,offset ALR_LOADED
	call PRINT
	ret
	;выгрузка пользовательского прерывания
UNLOAD: ;если /un
	pop AX
	pop ES
	mov byte ptr ES:[BX+SI+10],1 ;DELETE = 1
	mov dx,offset UNLOADED ;вывод сообщения
	call PRINT
	ret
CHECK_INT ENDP
;---------------------------------------------------------------
SET_INT PROC ;установка написанного прерывания в поле векторов прерываний
	push DX
	push DS
	mov AH,35h ;функция получения вектора
	mov AL,1Ch 
	int 21h
	mov KEEP_IP,BX 
	mov KEEP_CS,ES 
	mov DX,offset ROUT 
	mov AX,seg ROUT 
	mov DS,AX 
	mov AH,25h 
	mov AL,1Ch 
	int 21h ;меняем прерывание
	pop DS
	mov DX,offset IS_LOADDED ;вывод сообщения
	call PRINT
	pop DX
	ret
SET_INT ENDP 
;---------------------------------------------------------------
MAIN:
	mov AX,DATA
	mov DS,AX
	mov KEEP_PSP,ES ;сохранение PSP
	call CHECK_INT ;проверка прерывания
	xor AL,AL
	mov AH,4Ch ;выход 
	int 21H
LAST_BYTE:
	CODE ENDS
	END START