.Model small
.DATA
string db "Message$"
strld db 13, 10, "Resident loaded$", 13, 10
struld db 13, 10, "Resident unloaded$"
strald db 13, 10, "Resident is already loaded$"
PSP dw ?
isUd db ?
isloaded db ?
sg dw ?
num db 0
KEEP_CS DW ? ; для хранения сегмента
KEEP_IP DW ? ; и смещения вектора прерывания
.STACK 400h
.CODE
resID dw 0ff00h
;-----------------------------------
ROUT PROC FAR
	mov cs:[typeKey], 0
	in al, 60h
	cmp al, 10h  ;\\ 
	jl oldint9 ;   q w e r t y u i o p 
	cmp al, 19h ;//
	jle do_req1
	inc cs:[typeKey]
	cmp al, 49 ; N
	je do_req
	inc cs:[typeKey]
	cmp al, 14 ; backspace
	je do_req
	do_req1:
		push ax
		push es
		xor ax, ax
		mov es, ax
		mov al, es:[417h]
		pop es
		and al, 1000b ; левый/правый sft нажат или активен cps lock?
		pop ax
		jnz do_req
	oldint9:
		jmp dword ptr cs:[Int9_vect];
	do_req: 
		push ax
		;следующий код необходим для отработки аппаратного прерывания
		in al, 61h   ;взять значение порта управления клавиатурой
		mov ah, al     ; сохранить его
		or al, 80h    ;установить бит разрешения для клавиатуры
		out 61h, al    ; и вывести его в управляющий порт
		xchg ah, al    ;извлечь исходное значение порта
		out 61h, al    ;и записать его обратно
		mov al, 20h     ;послать сигнал "конец прерывания"
		out 20h, al     ; контроллеру прерываний 8259
	l16h:
		pop ax
		mov ah, 05h  ; Код функции
		cmp cs:[typeKey], 0
		je key1
		cmp cs:[typeKey], 1
		je key2
		cmp cs:[typeKey], 2
		je key3
	key1:
		push ax
		push es
		xor ax, ax
		mov es, ax
		mov al, es:[417h]
		pop es
		and al, 1000b ; левый/правый sft нажат или активен cps lock?
		jnz isalt
		pop ax
		jmp dword ptr cs:[Int9_vect];
	isalt:
		pop ax
		mov cl, 0B0h
		add cl, al
		sub cl, 0Fh ;Если цифра q-p и нажат alt выводим символы псевдографики
		jmp writeKey 
	key2:
		push ax
		push es
		xor ax, ax
		mov es, ax
		mov al, es:[417h]
		pop es
		and al, 01000011b ; левый/правый sft нажат или активен cps lock?
		jnz big
		pop ax
		mov cl, 'n'
		jmp writeKey
	big:
		pop ax
		mov cl, 'N' ; Пишем символ в буфер клавиатуры
		jmp writeKey
	key3:
		mov cl, 'D'
		jmp notcls
	writeKey:
		mov ch,00h ; 
		int 16h ;
		or al, al ; проверка переполнения буфера
		jnz clsbuf ; если переполнен идем skip
		jmp notcls
		; работать дальше
	clsbuf:  ; очистить буфер и повторить
		push es
		CLI	;запрещаем прерывания
		xor ax, ax
		MOV es, ax	
		MOV al, es:[41AH];\\	
		MOV es:[41CH], al;- head=tail 	
		STI	;разрешаем прерывания
		pop es
	notcls:
		IRET		
		Int9_vect dd ?		
		typeKey db 0 ; 0 if q-p , 1 if n , 2 if del
ROUT  ENDP  
;-----------------------------------
IsUnload PROC
	;Tail of command line
	push es
	push ax
	mov ax, psp
	mov es, ax
	mov cl, es:[80h]
	mov dl, cl
	xor ch, ch
	test cl, cl	
	jz ex2
	xor di, di
	readChar:
		inc di
		mov al, es:[81h+di]
		inc di
		cmp al, '/'
		jne ex2
		mov al, es:[81h+di]
		inc di
		cmp al, 'u'
		jne ex2
		mov al, es:[81h+di]
		cmp al, 'n'
		jne ex2
		mov isUd, 1 ; if is unloading resident
	ex2:
		pop ax
		pop es
		ret
IsUnload ENDP
;-----------------------------------
IsAlreadyLoad PROC
	push es
	mov ax, 3509h ; функция получения вектора
	int 21h
	mov dx, es:[bx-2]
	pop es
	cmp dx, resId
	je ad
	jmp exd
	ad:
		mov isloaded, 1
	exd:
		ret
IsAlreadyLoad ENDP
;-----------------------------------
UnLoad proc
	push es
	mov ax, sg
	mov es, ax
	mov DX, word ptr es:Int9_vect
	mov ax, word ptr es:Int9_vect+2
	mov KEEP_IP, dx
	mov KEEP_CS, ax
	pop es
	CLI
	push ds
	mov dx, KEEP_IP
	mov ax, KEEP_CS
	mov ds, ax
	mov ah, 25h
	mov al, 09h
	int 21h          ; восстанавливаем вектор
	pop ds
	STI
	ret
Unload endp
;-----------------------------------
MakeResident proc
	lea dx, strld
	call WRITE
	lea dx, temp
	sub dx, psp
	mov cl, 4
	shr dx, cl
	mov Ax, 3100h
	int 21h
	ret
MakeResident Endp
;-----------------------------------
WRITE PROC
	push ax
	mov ah, 09h
	int 21h
	pop ax
	ret
WRITE ENDP
;-----------------------------------
Main PROC  FAR 
	mov ax, ds
	mov ax, @DATA		  
	mov ds, ax
	mov ax, es
	mov psp, ax

	call isAlreadyLoad
	
	call isUnload
	
	cmp isloaded, 1
	je a
	mov ax, 3509h ; функция получения вектора
	int 21h
	mov KEEP_IP, bx  ; запоминание смещения
	mov KEEP_CS, es  ; и сегмента вектора прерывания
	mov word ptr int9_vect+2, es
	mov word ptr int9_vect, bx

	push ds
	mov dx, OFFSET ROUT ; смещение для процедуры в DX
	mov ax, SEG ROUT    ; сегмент процедуры
	mov ds, ax          ; помещаем в DS
	mov ax, 2509h         ; функция установки вектора
	int 21H             ; меняем прерывание
	pop ds
	call MakeResident
	a:
		cmp isUd, 1
		jne b
		call UnLoad
		lea dx, struld
		call WRITE
		mov ah, 4ch                        
		int 21h   
	b:
		lea dx, strald
		call WRITE
		mov ah, 4ch                        
		int 21h                             
Main ENDP

TEMP PROC
TEMP ENDP

END Main
		  
