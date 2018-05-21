DATA SEGMENT

	STR_ERR_FUNCT 		db 		'Function does not exist', 0dh, 0ah, '$'
	STR_ERR_FILE 		db 		'File is not found', 0dh, 0ah, '$'
	STR_ERR_PATH		db		'Path is incorrect', 0dh, 0ah, '$'
	STR_ERR_MANY_FILES 	db		'Too many files were opened', 0dh, 0ah, '$'
	STR_ERR_ACCESS 		db 		'No access', 0dh, 0ah, '$'
	STR_ERR_MEM 		db 		'Not enough memory', 0dh, 0ah, '$'
	STR_ERR_ENV	 		db 		'Wrong environment', 0dh, 0ah, '$'
    STR_ERR_MCB			db 		'MCB was destroyed', 0dh, 0ah, '$' 
	STR_ERR_MORE_MEM 	db 		'Need more memory', 0dh, 0ah, '$' 	
	STR_ERR_ADR 		db 		'Wrong block address', 0dh, 0ah, '$'

	DTA			db		43 dup(0)  	
	PATH		db		255 dup(0) 
	ADR		dw		?
	FUNC_ADR	dd	?

	OVL1 		db 		'OVL1.ovl', 0dh, 0ah, '$'
	OVL2		db		'OVL2.ovl', 0dh, 0ah, '$'
DATA ENDS

AStack SEGMENT STACK
	dw 256 dup(?)
AStack ENDS

CODE	SEGMENT
.386
	ASSUME CS:CODE, DS:DATA, SS:AStack
;-----------------------------
PRINT	PROC	near
		push ax
		mov		ah, 09h
		int		21h
		pop ax
		ret
PRINT	ENDP
;-----------------------------
FREE_MEM Proc

	push ax
	push dx
	push bx

	lea  bx, FIN
    xor  ax, ax
    mov  ah, 4ah
    int  21h
	jnc NO_ERR
	
	
	cmp ax, 7
	je ERR1_8
	cmp ax, 8
	je ERR1_9
	cmp ax, 9
	je ERR1_10
ERR1_8:
	lea dx, STR_ERR_MCB
	call PRINT
	jmp exit
ERR1_9:
	lea dx, STR_ERR_MORE_MEM
	call PRINT
	jmp exit
ERR1_10:
	lea dx, STR_ERR_ADR
	call PRINT
exit:
	mov ax, 4Ch
	int 21h

NO_ERR:
	pop bx
	pop dx
	pop ax
	ret
	
FREE_MEM ENDP
;-----------------------------
GET_PATH	proc

	push si
	push di
	push es
	push dx
	push cx

	mov es, es:[2Ch]	
	xor si, si
	lea di, PATH
CYCLE1:   
	inc si    
	cmp word ptr es:[si], 0000h
	jne CYCLE1
	add si, 4           
PATH_LOOP:
	cmp byte ptr es:[si], 00h
	je CONT
	mov dl, es:[si]
	mov [di], dl
	inc si
	inc di
	jmp PATH_LOOP
   
CONT:
	mov si, bp 
	mov cx, 8
	sub di, 8   
CYCLE2:
	mov dl, ds:[si]
	mov [di], dl
	inc di
	inc si
	loop CYCLE2

	mov dl, 0h
	mov [di], dl
	inc di
	mov dl, '$'
	mov [di], dl

	pop cx
	pop dx
	pop es
	pop di
	pop si
	ret
	
GET_PATH	ENDP
;-----------------------------
;-----------------------------
ERROR2 proc

	push ax
	push dx
	

	cmp ax, 1
	je ERR2_1
	cmp ax, 2
	je ERR2_2
	cmp ax, 3
	je ERR2_3
	cmp ax, 4
	je ERR2_4
	cmp ax, 5
	je ERR2_5
	cmp ax, 8
	je ERR2_8
	cmp ax, 10
	je ERR2_10

ERR2_1:
	lea dx, STR_ERR_FUNCT
	call PRINT
	jmp FIN_
ERR2_2:
	lea dx, STR_ERR_FILE
	call PRINT
	jmp FIN_
ERR2_3:
	lea dx, STR_ERR_PATH
	call PRINT
	jmp FIN_
ERR2_4:
	lea dx, STR_ERR_MANY_FILES
	call PRINT
	jmp FIN_
ERR2_5:
	lea dx, STR_ERR_ACCESS
	call PRINT
	jmp FIN_
ERR2_8:
	lea dx, STR_ERR_MEM
	call PRINT
	jmp FIN_
ERR2_10:
	lea dx, STR_ERR_ENV
	call PRINT
FIN_:
	pop dx
	pop ax
	ret
	
ERROR2 ENDP
;-----------------------------
;-----------------------------
ERROR1 proc

	push ax
	push dx
	

	cmp ax, 2	
	je ERR3_2
	cmp ax, 3
	je ERR3_3

ERR3_2:
	lea dx, STR_ERR_FILE
	call PRINT
	jmp FIN__
ERR3_3:
	lea dx, STR_ERR_PATH
	call PRINT
	
FIN__:
	pop dx
	pop ax
	ret
	
ERROR1 ENDP
;-----------------------------
;-----------------------------
MEM_OVL proc

	push ax
	push bx
	push es
	push si
	push dx

	lea dx, DTA		
	mov ax, 1A00h
	int 21h
	
	mov cx, 0		
	lea dx, PATH
	mov ax, 4E00h
	int 21h
		
	jnc MEM_SIZE	
	call ERROR1
	jmp MEM_END
	
MEM_SIZE:
	mov si, offset DTA
	add si, 1Ah
	mov bx, [si]	
	shr bx, 4 
	mov ax, [si+2]	
	shl ax, 12
	add bx, ax
	add bx, 2
		
	mov ax, 4800h	
	int 21h
	mov ADR, ax	
	
MEM_END:
	pop dx
	pop si
	pop es
	pop bx
	pop ax
	ret
	
MEM_OVL endp
;-----------------------------
;-----------------------------
LOAD_OVL PROC

	push ax
	push bx
	push bp
	push dx
	push cx
	push es
	push ss
	push sp

	mov bx, seg ADR
	mov es, bx			
	lea bx, ADR		
	lea dx, PATH		
	
	mov ax, 4B03h
	int 21h

	jnc CONT_		
	call ERROR2
	jmp LOAD_END
CONT_:
	mov ax, ADR
	mov word ptr FUNC_ADR + 2, ax
	call FUNC_ADR
	mov es, ax
	mov ax, 4900h
	int 21h
	
LOAD_END:
	pop sp
	pop ss
	pop es
	pop cx
	pop dx
	pop bp
	pop bx
	pop ax	
	ret
	
LOAD_OVL ENDP
;-----------------------------

MAIN	PROC  

	mov ax, DATA
	mov ds, ax

	call FREE_MEM	

	lea bp, OVL1
	call GET_PATH
	lea dx, PATH
	call PRINT		
	call MEM_OVL	
	call LOAD_OVL	

	lea bp, OVL2
	call GET_PATH
	lea dx, PATH
	call PRINT		
	call MEM_OVL	
	call LOAD_OVL	

	mov ah, 4Ch
	int 21h
	
FIN:
MAIN ENDP
CODE ENDS

END MAIN