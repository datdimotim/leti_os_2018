OVL_1 segment
ASSUME cs:OVL_1, ds:nothing, ss:nothing, es:nothing
MAIN PROC FAR
	push ds
	push ax
	push di
	push dx
	push bx
	
	mov ds, ax
	lea dx, cs:string	
	call OUTPUT_PROC	
	
	lea bx, cs:adr
	add bx, 19			
	mov di, bx		
	mov ax, cs			
	call WRD_TO_HEX
	
	lea dx, cs:adr	
	call OUTPUT_PROC	
	
	pop bx
	pop dx
	pop di
	pop ax
	pop ds
	retf
MAIN ENDP
;----------------------------
string 	db 	10, 13, 'Open first overlay', 10, 13, '$'
adr 		db 	'Segment adress:     ', 10, 13, '$'
;----------------------------
OUTPUT_PROC PROC  ;Вывод на экран сообщения
	push ax
	mov  ah, 09h
	int  21h
	pop	 ax
	ret
OUTPUT_PROC ENDP
;----------------------------
TETR_TO_HEX PROC NEAR
	and al,0Fh 
	cmp al,09 
	jbe NEXT 
	add al,07 
NEXT: 
	add al,30h 
	ret 
TETR_TO_HEX ENDP 
;----------------------------
BYTE_TO_HEX PROC NEAR 
	push cx 
	mov ah,al 
	call TETR_TO_HEX 
	xchg al,ah 
	mov cl,4 
	shr al,cl 
	call TETR_TO_HEX ; в al - старший байт
	pop cx ;в ah - младший
	ret 
BYTE_TO_HEX ENDP 
;----------------------------
WRD_TO_HEX PROC NEAR 
	push bx 
	mov bh,ah 
	call BYTE_TO_HEX 
	mov [di],ah 
	dec di 
	mov [di],al 
	dec di 
	mov al,bh 
	call BYTE_TO_HEX 
	mov [di],ah 
	dec di 
	mov [di],al 
	pop bx 
	ret 
WRD_TO_HEX ENDP 
;----------------------------
OVL_1 ENDS
END MAIN