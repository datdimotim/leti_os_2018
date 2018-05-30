CODE SEGMENT
	 ASSUME CS:CODE, DS:CODE, ES:NOTHING, SS:NOTHING
	 ORG 100H
START: JMP BEGIN

; данные
ADDR_SEG DB 'segment address not available memory=    ', 0AH, 0DH,'$'
ADDR_ENV DB 'segment addres of environment=    ', 0AH, 0DH, '$'
TAIL_OF_CMD DB 'the tail of cmd promt=' , '$'
NEW_LINE DB  0AH, 0DH, '$'
ENV DB 0AH, 0DH,'ENVIRONMENT:', 0AH, 0DH, '$'
PATH_TO_PROG DB 'path to prog=', '$'
; процедуры
TETR_TO_HEX PROC near
	and AL,0Fh
	cmp AL,09
	jbe NEXT
	add AL,07
	NEXT: add AL,30h
	ret
TETR_TO_HEX ENDP

BYTE_TO_HEX PROC near
	push CX
	mov AH,AL
	call TETR_TO_HEX
	xchg AL,AH
	mov CL,4
	shr AL,CL
	call TETR_TO_HEX ;в AL старшая цифра
	pop CX           ;в AH младшая
	ret
BYTE_TO_HEX ENDP

WRD_TO_HEX PROC near ;перевод в 16 с/с 16-ти разрядного числа
	push BX          ; в AX - число, DI - адрес последнего символа
	mov BH,AH        ;  now it aclually converts byte to string, last sybmol adress is di
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

BYTE_TO_DEC PROC near ; перевод байта в 10с/с, SI - адрес поля младшей цифры
	push	AX        ; AL содержит исходный байт
	push CX
	push DX
	xor AH,AH
	xor DX,DX
	mov CX,10
	loop_bd: div CX
	or DL,30h
	mov [SI],DL
	dec SI
	xor DX,DX
	cmp AX,10
	jae loop_bd
	cmp AL,00h
	je end_l
	or AL,30h
	mov [SI],AL
	end_l: pop DX
	pop CX
	pop	AX
	ret
BYTE_TO_DEC ENDP

print_env proc near
	mov dx, offset ENV
	mov ah, 09h
	int 21h
	mov bx, 2Ch
	mov ax, [bx]
	mov ds, ax
	mov di,0
	mov dx, di
	cicl:
		cmp byte ptr [di], 0
		je exit
		cf:
			inc di
			cmp byte ptr [di], 0
			jne cf
			mov byte ptr [di], '$'
				mov ah, 09h
				int 21h
				push dx
				push ds
				push es
				mov dx, offset NEW_LINE
				pop ds
				int 21h
				pop ds
				pop dx
			mov byte ptr [di], 0h
			inc di
			mov dx, di
			jmp cicl
	exit:
	push es
	pop ds
	mov dx, offset NEW_LINE
	mov ah, 09h
	int 21h
	ret
print_env endp

tail_of_cmd_str proc near
	mov dx, offset TAIL_OF_CMD
	mov ah, 09h
	int 21h
	mov bx, 80h
	mov al, [bx] ; в al - число символов в строке
	cmp al, 0
	je empty
		mov ah, 0
		mov di, ax
		mov al, [di+81h]
		push ax
		mov byte ptr [di+81h], '$'
		mov dx, 81h
		mov ah, 09h
		int 21h
		pop ax
		mov [di+81h], al
	empty:
	mov dx, offset NEW_LINE
	mov ah, 09h
	int 21h
	ret
tail_of_cmd_str endp

print_path_to_prog proc near ; di = end of env
	mov dx, offset PATH_TO_PROG
	mov ah, 09h
	int 21h
	mov bx, 2Ch
	mov ax, [bx]
	mov ds, ax
	add di, 3
	mov dx, di
	find:
	inc di
	cmp byte ptr [di], 0
	jne find
	mov byte ptr [di], '$'
		mov ah, 09h
		int 21h
	mov byte ptr [di], 0h
	push es
	pop ds
	ret
print_path_to_prog endp

BEGIN:
	push DS 
	sub AX,AX 
	push AX 
    ; my code
	
	; 1)
	mov bx, 2h
	mov ax, [bx]
	mov DI, OFFSET (ADDR_SEG+40)
	call WRD_TO_HEX
	mov dx, offset ADDR_SEG
	mov ah, 09h
	int 21h
	
	; 2)
	mov bx, 2ch
	mov ax, [bx]
	mov DI, OFFSET (ADDR_ENV+33)
	call WRD_TO_HEX
	mov dx, offset ADDR_ENV
	mov ah, 09h
	int 21h

	; 3)
	call tail_of_cmd_str
	
	; 4)
	call print_env
	
	; 5)
	call print_path_to_prog
	
    mov ah, 02h
    mov dl,0Ah
    int 21h
    mov dl,0Dh
    int 21h
	; end of program
    mov ah, 01h
    int 21h
	mov AH,4Ch
	int 21H
CODE ENDS
END START