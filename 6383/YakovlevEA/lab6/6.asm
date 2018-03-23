.MODEL SMALL
;-----------------------------------------------------
.DATA
;ДАННЫЕ
successPrint      db  '		Process ended successful, code: ', '$'
errPrint      db  '		Error! No file', '$'
ctrlCPrint      db  '		Process ended with ctrl + c', '$'
fileName db 50 dup(0)
EOL db "$"
PARAM dw 7 dup(?)
stackS dw ?
stackP dw ?
MEMMORY db 0
;-----------------------------------------------------
.STACK 200h
;-----------------------------------------------------
.CODE
;ПРОЦЕДУРЫ
;-----------------------------------------------------
TETR_TO_HEX   PROC  near
	and      AL,0Fh
	cmp      AL,09
	jbe      NEXT
	add      AL,07
	NEXT:      add      AL,30h
	ret
TETR_TO_HEX   ENDP
;-----------------------------------------------------
BYTE_TO_HEX   PROC  near
; байт в AL переводится в два символа шестн. числа в AX
	push     CX
	mov      AH,AL
	call     TETR_TO_HEX
	xchg     AL,AH
	mov      CL,4
	shr      AL,CL
	call     TETR_TO_HEX ;в AL старшая цифра
	pop      CX          ;в AH младшая
	ret
BYTE_TO_HEX  ENDP
;-----------------------------------------------------
;Освобождение памяти
freeMem PROC
	lea bx, TEMP
	mov ax, es
	sub bx, ax
	mov cl, 4
	shr bx, cl
	mov ah, 4Ah 
	int 21h
	jc @err
	jmp @noterr
	@err:
		mov MEMMORY, 1
	@noterr:
		ret
freeMem ENDP
;-----------------------------------------------------
;Вывод на экран
print PROC
	push ax
	mov ah, 09h
	int 21h
	pop ax
	ret
print ENDP
;-----------------------------------------------------
;Выход из программы
exitProgram PROC
	mov ah, 4Dh
	int 21h
	cmp ah, 1
	je @errchild
	lea bx, successPrint
	mov [bx], ax
	lea dx, successPrint
	call print
	call BYTE_TO_HEX
	push ax
	mov dl, ' '
	mov ah, 2h
	int 21h
	pop ax
	push ax
	mov dl, al
	mov ah, 2h
	int 21h
	pop ax
	mov dl, ah
	mov ah, 2h
	int 21h
	jmp @exget
	@errchild:
		lea dx, ctrlCPrint
		call print
	@exget:
		ret
exitProgram ENDP

;-----------------------------------------------------
READ PROC
	push si
	push di
	push es
	push dx
	mov es, es:[2Ch]
	xor si, si
	lea di, fileName
	@env_char: 
		inc si      
		cmp word ptr es:[si], 0000h
		jne @env_char
		add si, 4           
	@abs_char:
		cmp byte ptr es:[si], 00h
		je @next_step
		mov dl, es:[si]
		mov [di], dl
		inc si
		inc di
		jmp @abs_char        
	@next_step:
		sub di, 5
		mov dl, '2'
		mov [di], dl
		add di, 2
		mov dl, 'c'
		mov [di], dl
		inc di
		mov dl, 'o'
		mov [di], dl
		inc di
		mov dl, 'm'
		mov [di], dl
		inc di
		mov dl, 0h
		mov [di], dl
		inc di
		mov dl, EOL
		mov [di], dl
		pop dx
		pop es
		pop di
		pop si
		ret
READ ENDP
;-----------------------------------------------------
; КОД
BEGIN PROC FAR
		mov ax, @data
		mov ds, ax	
		call READ
		call freeMem
		cmp MEMMORY, 0
		jne @Exit
		push ds
		pop es
		lea dx, fileName 
		lea bx, PARAM 
		mov stackS, ss
		mov stackP, sp
		mov ax, 4b00h
		int 21h
		mov ss, stackS
		mov sp, stackP
		jc @erld
		jmp @noterld
	@erld:
		lea dx, errPrint
		call print
		lea dx, fileName
		call print
		jmp @Exit
	@noterld:
		call exitProgram
	@Exit:
	; Выход в DOS
		mov ah, 4Ch
		int 21h
	   
BEGIN      ENDP
;-----------------------------------------------------
TEMP PROC
TEMP ENDP
;-----------------------------------------------------
END BEGIN
