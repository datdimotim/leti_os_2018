TESTPC SEGMENT
 ASSUME CS:TESTPC, DS:TESTPC, ES:NOTHING, SS:NOTHING
 ORG 100H
START: JMP BEGIN
; ДАННЫЕ
OS db 'Type OS: $'
OS_VERS db 'Version OS:   .  ',0DH,0AH,'$'
OS_OEM db 'OEM:    ',0DH,0AH,'$'
SER_NUM db 'Serial number: ','$'
STRING db '    $'
ENDSTR db 0DH,0AH,'$'

PC db 'PC',0DH,0AH,'$'
PCXT db 'PC/XT',0DH,0AH,'$'
_AT db 'AT',0DH,0AH,'$'
PS2_30 db 'PS2 model 30',0DH,0AH,'$'
PS2_80 db 'PS2 model 80',0DH,0AH,'$'
PCjr db 'PCjr',0DH,0AH,'$'
PC_Cnv db 'PC Convertible',0DH,0AH,'$'

WriteMsg PROC near
	mov AH,09h
	int 21h
	ret
WriteMsg ENDP

;---------------------------------------
; Печатает тип ОС
TYPE_OS PROC near
	mov dx, OFFSET OS
	call WriteMsg
	mov ax,0F000h
	mov es,ax
	mov ax,es:0FFFEh

	; Определяем тип ОС
	cmp al,0FFh
	je PC_metka
	cmp al,0FEh
	je PCXT_metka
	cmp al,0FBh
	je PCXT_metka
	cmp al,0FCh
	je AT_metka
	cmp al,0FAh
	je PS2_30_metka
	cmp al,0F8h
	je PS2_80_metka
	cmp al,0FDh
	je PCjr_metka
	cmp al,0F9h
	je PC_Cnv_metka

	PC_metka:
		mov dx, OFFSET PC
		jmp konec1
	PCXT_metka:
		mov dx, OFFSET PCXT
		jmp konec1
	AT_metka:
		mov dx, OFFSET _AT
		jmp konec1
	PS2_30_metka:
		mov dx, OFFSET PS2_30
		jmp konec1
	PS2_80_metka:
		mov dx, OFFSET PS2_80
		jmp konec1
	PCjr_metka:
		mov dx, OFFSET PCjr
		jmp konec1
	PC_Cnv_metka:
		mov dx, OFFSET PC_Cnv
		jmp konec1

	konec1:
	call WriteMsg
	ret
TYPE_OS ENDP

;---------------------------------------
; Печатает версию системы
VERSION_OS PROC near
	; Получаем данные
	mov ax,0
	mov ah,30h
	int 21h

	; Пишем в строку OS_VERS номер основной версии ОС
	mov si,offset OS_VERS
	add si,12
	push ax
	call BYTE_TO_DEC

	; Пишем модификацию ОС
	pop ax
	mov al,ah
	add si,3
	call BYTE_TO_DEC

	; Пишем версию ОС в консоль
	mov dx,offset OS_VERS
	call WriteMsg

	; Пишем OEM
	mov si,offset OS_OEM
	add si,7
	mov al,bh
	call BYTE_TO_DEC

	mov dx,offset OS_OEM
	call WriteMsg

	; Пишем серийный номер пользователя
	mov dx,offset SER_NUM
	call WriteMsg
	mov  al,bl
	call BYTE_TO_HEX
	mov bx,ax
	mov dl,bl
	mov ah,02h
	int 21h
	mov dl,bh
	int 21h
	mov di,offset STRING
	add di,3
	mov ax,cx
	call WRD_TO_HEX
	mov dx,offset STRING
	call WriteMsg

	mov dx,offset ENDSTR
	call WriteMsg

	ret
VERSION_OS ENDP
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
WRD_TO_HEX PROC near
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
; перевод в 10с/с, SI - адрес поля младшей цифры
BYTE_TO_DEC PROC near
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
	ret
BYTE_TO_DEC ENDP
;---------------------------------------
BEGIN:
	call TYPE_OS
	call VERSION_OS
	xor AL,AL
	mov AH,4Ch
	int 21H
TESTPC ENDS
 END START