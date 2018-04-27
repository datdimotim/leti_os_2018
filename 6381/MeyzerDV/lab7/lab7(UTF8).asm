print macro
	push ax
	mov ax,0900h
	int 21h
	pop ax
endm
printl macro a
	push ax
	push dx
	lea dx,a
	mov ax,0900h
	int 21h
	lea dx,STRENDL
	int 21h
	pop dx
	pop ax
endm
debug macro r
	pushf
	push ax
	push di
	mov ax,r
	lea di,STRTEST+3
	call WRD_TO_HEX
	printl STRTEST
	pop di
	pop ax
	popf
endm
CODE SEGMENT
 ASSUME CS:CODE, DS:DATA, ES:DATA, SS:STACKSEG
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
; перевод в 16с/с 16-ти разрядного числа
; в AX - число, DI - адрес последнего символа
WRD_TO_HEX PROC far
	push BX
	mov BH,AH
	call BYTE_TO_HEX
	mov [DI],AH
	dec DI
	mov [DI],AL
	dec DI
	mov AL,BH
	call BYTE_TO_HEX
	mov [DI],AH
	dec DI
	mov [DI],AL
	pop BX
	ret
WRD_TO_HEX ENDP
;---------------------------------------
; Функция освобождения лишней памяти √
FREE_MEM PROC
	push ax
	push bx
	push dx
	; Выводим промежуточное сообщение:
		printl STR_FREE_MEM
	; Вычисляем в BX необходимое количество памяти для этой программы в параграфах
		mov ax,STACKSEG ; В ax сегментный адрес стека
		mov bx,es
		sub ax,bx ; Вычитаем сегментный адрес PSP
		add ax,10h ; Прибавляем размер стека в параграфах
		mov bx,ax
	; Пробуем освободить лишнюю память
		mov ah,4Ah
		int 21h
		jnc FREE_MEM_SUCCESS

	; Обработка ошибок
		mov dx,offset STR_ERR_FREE_MEM
		print
		cmp ax,7
		mov dx,offset STR_ERR_MCB_DESTROYED
		je FREE_MEM_PRINT_ERROR
		cmp ax,8
		mov dx,offset STR_ERR_NOT_ENOUGH_MEM
		je FREE_MEM_PRINT_ERROR
		cmp ax,9
		mov dx,offset STR_ERR_WRNG_MEM_BL_ADDR

		FREE_MEM_PRINT_ERROR:
		print
		mov dx,offset STRENDL
		print

	; Выход в DOS
		xor AL,AL
		mov AH,4Ch
		int 21H

	FREE_MEM_SUCCESS:
	printl STR_PROC_DONE
	pop dx
	pop bx
	pop ax
	ret
FREE_MEM ENDP
;---------------------------------------
; Процедура выделения памяти для оверлейного сегмента.
; Изменяемое значение - ax - адрес сегмента выделенной памяти
ALLOC_MEM PROC
	push ds
	push dx
	; Выводим промежуточное сообщение:
		printl STR_ALLOC_MEM

	; Читаем размер файла оверлея:
		xor cx,cx
		mov ax,4E00h
		int 21h
		jnc ALLOC_MEM_FILE_FOUND
			printl STR_ERR_FL_NOT_FND
			pop dx
			pop ds
			mov ax,4c00h
			int 21h
		ALLOC_MEM_FILE_FOUND:
		push es
		push bx
		; Получаем в ES:BX адрес DTA
		mov ah,2fh
		int 21h
		; Кладём размер файла в DX:AX
		add bx,1ah
		mov ax,word ptr ES:[BX]
		mov dx,word ptr ES:[BX+2]
		mov bx,10h
		div bx ; Получаем в ax размер файла в параграфах
		inc ax

	; Запрашиваем объем памяти:
		mov ah,48h
		int 21h
		jnc ALLOC_MEM_DONE
			printl STR_ERR_ALLOC_MEM
			call PROCESS_LOADER_ERRORS
			mov ax,4c00h
			int 21h
		ALLOC_MEM_DONE:
		pop es
		pop bx
	pop dx
	pop ds
	printl STR_PROC_DONE
	mov word ptr OVERLAY_ADDR+2,ax
	mov PARAMBLOCK,ax
	ret
ALLOC_MEM ENDP
;---------------------------------------
; Процедура поиска файла оверлея √
; В регистре bp - название файла оверлея, лежащего в той же папке
; Изменяемое значение - DS:DX указывает на строку с полным именем запускаемого оверлея
FIND_OVERLAY_PATH PROC
	; Выводим промежуточное сообщение:
		printl STR_FIND_OVERLAY_PATH

	push es ; Сохраняем PSP
	push ax
	push si
	push di
	push cx
	
	; Переходим в область среды
	mov ax, es:[2ch]
	mov es, ax
	; Пропускаем переменные среды:
	; Сканируем строку es:di, пока байт не равен 0
	mov al, 0 ; Какой байт ищем
	mov di, 0 ; Указатель на область данных в области среды
	FIND_OVERLAY_SKIP_BEGIN:
	mov cx, 512 ; Максимальный размер блока поиска
repne scasb ; Повторяем, пока анализируемый байт не равен al(0)
	cmp es:[di],al ; Если второй байт - не ноль, продолжаем пропускать
	jne FIND_OVERLAY_SKIP_BEGIN
	
	add di, 3 ; Пропускаем 001
	
	; Считаем длину строки, содержащей полный путь к программе
	push di
	mov cx,100 ; Максимальная длина строки
repne scasb
	mov ax,di ; Кладем в ax адрес символа, следующим за строкой
	pop di ; Кладем в di начало строки
	sub ax,di 
	dec ax ; Получаем в ax количество символов в строке пути к программе
	mov cx,ax ; Кладём в cx количество копируемых символов
	
	; Копируем строку
	push ds
	push es
	pop ds
	pop es ; Поменяли местами es(область среды) и ds(сегмент данных)
	mov si,di ; Кладем в ds:si начало копируемой строки
	lea di,OVERLAY_PATH ; Кладем в es:di начало строки, в которую копируем
rep movsb ; Копируем cx байт из ds:si в es:di
	mov byte ptr es:[di],0 ; Завершаем скопированную строку нулем
		
	; Заменяем название текущей программы названием оверлея
	mov cx,100
	mov al,'\' ; Ищем символ '\'
	std ; Идем в обратную сторону, es:di - конец скопированной строки
repne scasb
	cld ; Возвращаем стандартное направление прохода
	add di,2 ; Переходим на символ за символом '\'
	mov cx,13 ; Имя оверлея - 13 байтов, включая 0
	mov ax,data
	mov ds,ax
	mov si,bp
	; Установили ds:si на копируемую строку, es:di - на то, куда копируем
rep movsb ; Выполняем копирование
	
	pop cx
	pop di
	pop si
	pop ax
	pop es ; Восстанавливаем PSP
	
	lea dx,OVERLAY_PATH ; Кладём указатель на полное имя программы в dx
	
	printl STR_PROC_DONE
	ret
FIND_OVERLAY_PATH ENDP
;---------------------------------------
; Процедура запуска оверлея
; Принимает в bp указатель на имя запускаемого оверлея из того же каталога, что и сама программа
RUN_OVERLAY PROC
	push ds
	push es
	push ax
	push bx
	push cx
	push dx
	
	
	; Ищем файл с оверлеем, устанавливаем DS:DX на строку, содержащую имя файла с оверлеем
	call FIND_OVERLAY_PATH
	; Выделяем память для оверлея и получаем сегментный адрес выделенной памяти в ax
	call ALLOC_MEM

	mov CS:KEEP_SP, SP
	mov CS:KEEP_SS, SS
	mov CS:KEEP_DS, DS
	mov CS:KEEP_ES, ES

	; Генерируем блок параметров
	mov PARAMBLOCK,ax 
	push ds
	pop es ; В ES кладём DS
	lea bx, PARAMBLOCK ; ES:BX указывает на блок параметров
	; Выводим промежуточное сообщение:
	printl STR_RUN_OVERLAY
	; Запускаем оверлей
		mov ax,4b03h
		int 21h
		jnc OVL_LOADED
			call PROCESS_LOADER_ERRORS
		OVL_LOADED:
	; Переходим в оверлей
		printl STRENDL
		call dword ptr OVERLAY_ADDR
		printl STRENDL
	mov SP,CS:KEEP_SP
	mov SS,CS:KEEP_SS
	mov DS,CS:KEEP_DS
	mov ES,CS:KEEP_ES
	jnc OVERLAY_SUCCESS

	; Обработка ошибок
		call PROCESS_LOADER_ERRORS

	; Ошибок нет
	OVERLAY_SUCCESS:
	printl STR_PROC_DONE
	; Освобождаем память
	printl STR_RMV_OVERLAY
	push es
	mov ax,PARAMBLOCK
	mov es,ax
	mov ax,4900h
	int 21h
	pop es
	jnc OVERLAY_DELETE_SUCCESS
	call PROCESS_LOADER_ERRORS
	OVERLAY_DELETE_SUCCESS:
	printl STR_PROC_DONE
	pop dx
	pop cx
	pop bx
	pop ax
	pop es
	pop ds
	ret
	; Переменные для хранения регистров
	KEEP_SP dw 0
	KEEP_SS dw 0
	KEEP_DS dw 0
	KEEP_ES dw 0
RUN_OVERLAY ENDP
;---------------------------------------
; Процедура обработки ошибок загрузчика ОС √
PROCESS_LOADER_ERRORS PROC
	cmp ax,1
	lea dx,STR_ERR_WRNG_FNCT_NUMB
	je PROCESS_LOADER_ERRORS_PRINT
	cmp ax,2
	lea dx,STR_ERR_FL_NOT_FND
	je PROCESS_LOADER_ERRORS_PRINT
	cmp ax,3
	lea dx,STR_ERR_PATH_NOT_FOUND
	je PROCESS_LOADER_ERRORS_PRINT
	cmp ax,4
	lea dx,STR_ERR_TOO_MANY_FILES
	je PROCESS_LOADER_ERRORS_PRINT
	cmp ax,5
	lea dx,STR_ERR_NO_ACCESS
	je PROCESS_LOADER_ERRORS_PRINT
	cmp ax,6
	lea dx,STR_ERR_INVLD_HNDL
	je PROCESS_LOADER_ERRORS_PRINT
	cmp ax,7
	lea dx,STR_ERR_MCB_DESTROYED
	je PROCESS_LOADER_ERRORS_PRINT
	cmp ax,8
	lea dx,STR_ERR_NOT_ENOUGH_MEM
	je PROCESS_LOADER_ERRORS_PRINT
	cmp ax,9
	lea dx,STR_ERR_WRNG_MEM_BL_ADDR
	je PROCESS_LOADER_ERRORS_PRINT
	cmp ax,10
	lea dx,STR_ERR_WRONG_ENV
	je PROCESS_LOADER_ERRORS_PRINT
	cmp ax,11
	lea dx,STR_ERR_WRONG_FORMAT
	je PROCESS_LOADER_ERRORS_PRINT
	cmp ax,12
	lea dx,STR_ERR_INV_ACCSS_MODE
	je PROCESS_LOADER_ERRORS_PRINT
	lea dx,STR_ERR_UNKNWN
	PROCESS_LOADER_ERRORS_PRINT:
	print
	mov ax,4c00h
	int 21h
PROCESS_LOADER_ERRORS ENDP
;---------------------------------------
BEGIN:
	mov ax,data
	mov ds,ax
	; Освобождаем лишнюю память
	call FREE_MEM

	push dx
	lea dx,STRENDL
	print
	pop dx
	printl STR_FIRST_OVERLAY
	
	; Запускаем оверлей Overlay1.com
	lea bp, STR_OVL1
	call RUN_OVERLAY
	
	push dx
	lea dx,STRENDL
	print
	pop dx
	printl STR_SECOND_OVERLAY
	
	; Запускаем оверлей Overlay2.com
	lea bp, STR_OVL2
	call RUN_OVERLAY
	
	xor AL,AL
	mov AH,4Ch
	int 21H
CODE ENDS
; ДАННЫЕ
DATA SEGMENT
	; Строки ошибок:
		STR_ERR_FREE_MEM	 		db 'Error when freeing memory: $'
		STR_ERR_ALLOC_MEM			db 'Error while allocating memory$'
		STR_ERR_TOO_LONG_TAIL		db 'Tail is too long$'

	; Ошибки от DOS
		STR_ERR_WRNG_FNCT_NUMB		db 'Function number is wrong$'
		STR_ERR_FL_NOT_FND			db 'File not found$'
		STR_ERR_PATH_NOT_FOUND		db 'Path not found$'
		STR_ERR_TOO_MANY_FILES		db 'Too many open files$'
		STR_ERR_NO_ACCESS			db 'Access denied$'
		STR_ERR_INVLD_HNDL			db 'Invalid handle$'
		STR_ERR_MCB_DESTROYED		db 'Memory control blocks destroyed$'
		STR_ERR_NOT_ENOUGH_MEM		db 'Insufficient memory$'
		STR_ERR_WRNG_MEM_BL_ADDR 	db 'Invalid memory block address$'
		STR_ERR_WRONG_ENV			db 'Invalid environment$'
		STR_ERR_WRONG_FORMAT		db 'Invalid format$'
		STR_ERR_INV_ACCSS_MODE		db 'Invalid access mode$'
		STR_ERR_UNKNWN				db 'Unknown error$'

	; Строки, оповещающие о работе функций
		STR_FIRST_OVERLAY		db 'First overlay:$'
		STR_SECOND_OVERLAY		db 'Second overlay:$'
		STR_FREE_MEM			db 'Freeing memory:$'
		STR_ALLOC_MEM			db 'Allocating memory:$'
		STR_FIND_OVERLAY_PATH	db 'Finding overlay path:$'
		STR_RUN_OVERLAY			db 'Running overlay:$'
		STR_PROC_DONE			db 'Done.$'
		STR_RMV_OVERLAY			db 'Removing overlay:$'

	STRENDL 				db 0DH,0AH,'$'
	STRTEST					db '    $'
	
	OVERLAY_ADDR dd 0 ; Первое слово - IP(=0), второе - сегмент(устанавливается в программе)
	; Блок параметров. Перед загрузкой дочерней программы на него должен указывать ES:BX
	PARAMBLOCK	dw 0 ; Сегментный адрес, по которому загружается оверлей
				dd 0 ; Сегментный адрес и смещение параметров командной строки
	OVERLAY_PATH  		db 105 dup ('$')
	STR_OVL1			db 'Overlay1.com',0
	STR_OVL2			db 'Overlay2.com',0

DATA ENDS
; СТЕК
STACKSEG SEGMENT STACK
	dw 80h dup (?) ; 100h байт
STACKSEG ENDS
 END START
