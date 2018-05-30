overlay_1 segment
	assume cs:overlay_1, ds:nothing, ss:nothing, es:nothing

BEGIN proc far
	push ds
	push ax
	push di
	push dx
	
	mov ax, cs
	mov ds, ax
	lea dx, string
	mov ah, 09h
	int 21h
	
	lea bx, address
	add bx, 14
	mov di, bx
	mov ax, cs
	call WRD_TO_HEX

	lea dx, address
	mov ah, 09h
	int 21h

	pop dx
	pop di
	pop ax
	pop ds
	retf
BEGIN endp
;-------------------------------
TETR_TO_HEX		PROC	near
		and		al,0fh
		cmp		al,09
		jbe		NEXT
		add		al,07
NEXT:	add		al,30h
		ret
TETR_TO_HEX		ENDP
;-------------------------------
;-------------------------------
BYTE_TO_HEX		PROC near
		push	cx
		mov		ah,al
		call	TETR_TO_HEX
		xchg	al,ah
		mov		cl,4
		shr		al,cl
		call	TETR_TO_HEX ; � AL ������� �����
		pop		cx  ; � AH �������
		ret
BYTE_TO_HEX		ENDP
;-------------------------------
;-------------------------------
WRD_TO_HEX		PROC	near
		push	bx
		mov		bh,ah
		call	BYTE_TO_HEX
		mov		[di],ah
		dec		di
		mov		[di],al
		dec		di
		mov		al,bh
		call	BYTE_TO_HEX
		mov		[di],ah
		dec		di
		mov		[di],al
		pop		bx
		ret
WRD_TO_HEX		ENDP
;-------------------------------

string		db 	0dh, 0ah, 'ovl2.ov is loaded', 0dh, 0ah, '$'
address 	db 	'Address:      ', 0dh, 0ah, '$'

overlay_1 ends
end BEGIN