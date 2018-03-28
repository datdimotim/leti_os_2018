TESTPC SEGMENT
 ASSUME CS:TESTPC, DS:TESTPC, ES:NOTHING, SS:NOTHING
 ORG 100H
 START: JMP BEGIN

COUNT_AVV_MEM_MSG db 'Количество доступной памяти: '
COUNT_AVV_MEM db '       байт',0DH,0AH,'$'
SIZE_EXP_MEM_MSG db 'Размер расширенной памяти : '
SIZE_EXP_MEM db '      Кбайт',0DH,0AH,'$'
BLOCK_UPR_MEM_MSG 	db 'Цепочка блоков управления памятью: ',0DH,0AH
					db ' АДРЕС | ВЛАДЕЛЕЦ | РАЗМЕР |   ИМЯ',0DH,0AH,'$'
BLOCK_UPR_MEM 		db '                             $'
ERRORR_STR	db 'Ошибка',0DH,0AH,'$'
STRENDL db 0DH,0AH,'$'

WRITEMSG PROC
	push ax
	mov ah,09h
	int 21h
	pop ax
	ret
WRITEMSG ENDP

AVV_MEM PROC
	mov ax,0
	mov ah,4Ah
	mov bx,0FFFFh
	int 21h
	mov ax,bx 
	mov bx,16
	mul bx 
	mov si,offset COUNT_AVV_MEM+5
	call TO_DEC
	mov dx,offset COUNT_AVV_MEM_MSG
	call WRITEMSG
	ret
AVV_MEM ENDP

EXP_MEM PROC
	mov  AL,30h
    out 70h,AL
    in AL,71h
    mov BL,AL
    mov AL,31h
    out 70h,AL
    in AL,71h
	mov bh,al
	
	mov ax,bx
	mov dx,0
	mov si,offset SIZE_EXP_MEM+4
	call TO_DEC
	mov dx,offset SIZE_EXP_MEM_MSG
	call WRITEMSG
	
	ret
EXP_MEM ENDP

MCB PROC
	mov bx,0A000h
	mov ax,offset ENDING
	mov bl,10h
	div bl
	xor ah,ah
	add ax,1
	
	mov bx,cs
	add ax,bx
	mov bx,es
	sub ax,bx
	mov al,0
	mov ah,4Ah
	int 21h
	jnc ERRORR
		mov dx,offset ERRORR_STR
		call WRITEMSG
	ERRORR:
	
	mov bx,1000h
	mov ah,48h
	int 21h
	
	mov dx,offset BLOCK_UPR_MEM_MSG
	call WRITEMSG
	push es
	mov ah,52h
	int 21h
	mov bx,es:[bx-2]
	mov es,bx
	CYCLE:
		mov ax,es
		mov di,offset BLOCK_UPR_MEM+4
		call WRD_TO_HEX
		mov ax,es:[01h]
		mov di,offset BLOCK_UPR_MEM+14
		call WRD_TO_HEX
		mov ax,es:[03h]
		mov si,offset BLOCK_UPR_MEM+26
		mov dx, 0
		mov bx, 10h
		mul bx
		call TO_DEC
		mov dx,offset BLOCK_UPR_MEM
		call WRITEMSG
		mov cx,8
		mov bx,8
		mov ah,02h
		CYCLE2:
			mov dl,es:[bx]
			add bx,1
			int 21h
		loop CYCLE2
		mov dx,offset STRENDL
		call WRITEMSG
		mov ax,es
		add ax,1
		add ax,es:[03h]
		mov bl,es:[00h]
		mov es,ax
		push bx
		mov ax,'  '
		mov bx,offset BLOCK_UPR_MEM
		mov [bx+19],ax
		mov [bx+21],ax
		mov [bx+23],ax
		pop bx	
		cmp bl,4Dh
		je CYCLE
	pop es
	ret
MCB ENDP

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
	call TETR_TO_HEX
	pop CX
	ret
BYTE_TO_HEX ENDP

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

TO_DEC PROC near
	push CX
	push DX
	mov CX,10
loop_bd2: div CX
	or DL,30h
	mov [SI],DL
	dec SI
	xor DX,DX
	cmp AX,10
	jae loop_bd2
	cmp AL,00h
	je end_l2
	or AL,30h
	mov [SI],AL
end_l2: pop DX
	pop CX
	ret
TO_DEC ENDP
	
BEGIN:	
	call AVV_MEM
	call EXP_MEM
	call MCB
	xor AL,AL
	mov AH,4Ch
	int 21H
ENDING:
TESTPC ENDS
 END START 