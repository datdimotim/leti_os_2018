TESTPC SEGMENT
		assume cs:TESTPC, ds:TESTPC, es:nothing, ss:nothing
		org 100h
start: jmp begin

;Data Segment
AVAILABLE_MEMORY db "Available memory:        [b]", 0dh, 0ah, '$'
EXTENDED_MEMORY db "Extended memory:       [kb]", 0dh, 0ah, '$'

NEW_LINE db 0dh, 0ah, '$'

TABLE_TITLE db " Address   MCB type	PSP address	Size[b]      Name    ", 0dh, 0ah, '$'
DATA_IN_TABLE  db "                                                               ", 0dh, 0ah, '$'
ALLOC_ERROR_TEXT db "Memory allocation error!", 0dh, 0ah, '$'
;End Data Segment
;--------------------------------------------------------------------------------
PRINT PROC near
		push ax
		mov ah, 09h
		int	21h
		pop ax
		ret
PRINT ENDP
;--------------------------------------------------------------------------------
TETR_TO_HEX PROC near

	and AL,0Fh
	cmp AL,09
	jbe NEXT
	add AL,07
NEXT:	add AL,30h
	ret
TETR_TO_HEX ENDP
;--------------------------------------------------------------------------------
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
;--------------------------------------------------------------------------------
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
;--------------------------------------------------------------------------------
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
	end_l:	pop DX
	pop CX
	ret
BYTE_TO_DEC ENDP
;--------------------------------------------------------------------------------
WRD_TO_DEC PROC near
	push CX
	push DX
	mov CX,10
	loop_w: div CX
	or DL,30h
	mov [SI],DL
	dec SI
	xor DX,DX
	cmp AX,10
	jae loop_w
	cmp AL,00h
	je endl
	or AL,30h
	mov [SI],AL
	endl: pop DX
	pop CX
	ret
WRD_TO_DEC ENDP
;--------------------------------------------------------------------------------
GET_A_MEMORY PROC NEAR
	push ax
	push bx
	push dx
	push si

	xor ax, ax
	mov ah, 04Ah
	mov bx, 0FFFFh
	int 21h

	mov ax, 10h
	mul bx

	mov si, offset AVAILABLE_MEMORY
	add si, 017h
	call WRD_TO_DEC

	mov dx, offset AVAILABLE_MEMORY
	call PRINT

	pop si
	pop dx
	pop bx
	pop ax

	ret
GET_A_MEMORY ENDP
;--------------------------------------------------------------------------------
GET_E_MEMORY PROC NEAR
	push ax
	push bx
	push dx
	push si

	xor dx, dx

	mov al, 30h
    out 70h, al
    in al, 71h 
    mov bl, al 
    mov al, 31h  
    out 70h, al
    in al, 71h

	mov ah, al
	mov al, bl

	mov si, offset EXTENDED_MEMORY
	add si, 015h
	call WRD_TO_DEC

	mov dx, offset EXTENDED_MEMORY
	call PRINT

	pop si
	pop dx
	pop bx
	pop ax

	ret
GET_E_MEMORY ENDP
;--------------------------------------------------------------------------------
GET_MCB_DATA PROC near
	;mcb address
	mov di, offset DATA_IN_TABLE
	mov ax, es
	add di, 05h
	call WRD_TO_HEX

	;mcb type
	mov di, offset DATA_IN_TABLE
	add di, 0Fh
	xor ah, ah
	mov al, es:[00h]
	call BYTE_TO_HEX
	mov [di], al
	inc di
	mov [di], ah
	
	;psp address
	mov di, offset DATA_IN_TABLE
	mov ax, es:[01h]
	add di, 1Dh
	call WRD_TO_HEX

	;size
	mov di, offset DATA_IN_TABLE
	mov ax, es:[03h]
	mov bx, 10h
	mul bx
	add di, 2Eh
	push si
	mov si, di
	call WRD_TO_DEC
	pop si

	;name
	mov di, offset DATA_IN_TABLE
	add di, 35h
    mov bx, 0h
	GET_8_BYTES:
        mov dl, es:[bx + 8]
		mov [di], dl
		inc di
		inc bx
		cmp bx, 8h
	jne GET_8_BYTES

	mov ax, es:[03h]
	mov bl, es:[00h]

	ret
GET_MCB_DATA ENDP
;--------------------------------------------------------------------------------
GET_ALL_MCB_DATA PROC NEAR
	mov ah, 52h
	int 21h
	sub bx, 2h
	mov es, es:[bx]

FOR_EACH_MCB:
		call GET_MCB_DATA
		mov dx, offset DATA_IN_TABLE
		call PRINT

		mov cx, es
		add ax, cx
		inc ax
		mov es, ax

		cmp bl, 4Dh
		je FOR_EACH_MCB
GET_ALL_MCB_DATA ENDP
;--------------------------------------------------------------------------------
begin:
    call GET_A_MEMORY
	call GET_E_MEMORY

	;get 64kb mem
	mov ah, 48h
	mov bx, 1000h
	int 21h

	jc alloc_error
	jmp not_alloc_error

	alloc_error:
		mov dx, offset ALLOC_ERROR_TEXT
		call PRINT
	not_alloc_error:

	;free mem
	mov ah, 4ah
	mov bx, offset END_OF_PROGRAMM
	int 21h

	mov dx, offset NEW_LINE
	call PRINT

	mov dx, offset TABLE_TITLE
	call PRINT

	call GET_ALL_MCB_DATA

	xor al, al
	mov ah, 4Ch
	int 21h
	ret
	
	END_OF_PROGRAMM db 0
TESTPC ENDS
END START