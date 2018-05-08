INT_STACK SEGMENT
	DW 100h DUP(?)
INT_STACK ENDS
;////////////////////////////////////////////////////////
STACK SEGMENT STACK
	DW 64 DUP (?)
STACK ENDS
;////////////////////////////////////////////////////////
DATA SEGMENT
	INT_ALR_LOADED DB 'User interruption is already loaded!',10,13,'$'
	INT_UNLOADED DB 'User interruption is unloaded!',10,13,'$'
	INT_LOADED DB 'User interruption is loaded!',10,13,'$'
	INT_NOT_LOADED db 'User interruption is not loaded',13,10,'$'
DATA ENDS
;////////////////////////////////////////////////////////
CODE SEGMENT
	ASSUME CS:CODE, DS:DATA, ES:DATA, SS:STACK
start: jmp MAIN
;---------------------------------------------------------------
PRINT_STR PROC
	push ax
	mov ah, 09h
	int 21h
	pop ax
	ret
PRINT_STR ENDP
;---------------------------------------------------------------
SET_CURS PROC ;установка позиции курсора
	push AX
	push BX
	push CX
	mov AH,02h
	mov BH,00h
	int 10h
	pop CX
	pop BX
	pop AX
	ret
SET_CURS ENDP
;---------------------------------------------------------------
GET_CURS PROC ;определение позиции и размера курсора 
	push AX
	push BX
	push CX
	mov AH,03h
	mov BH,00h
	int 10h
	pop CX
	pop BX
	pop AX
	ret
GET_CURS ENDP
;---------------------------------------------------------------
OUTPUT_AL PROC
	push ax
	push bx
	push cx
	mov ah,09h  
	mov bh,0
	mov cx,1
	int 10h  
	pop cx
	pop bx
	pop ax
	ret
OUTPUT_AL ENDP
;--------------------------------------------------------------
ROUT PROC FAR ;обработчик прерывания
	jmp ROUT_CODE
ROUT_DATA:
	SIGNATURE DB '0000'
	KEEP_CS DW 0
	KEEP_IP DW 0
	KEEP_PSP DW 0
	COUNT db 0
	COUNT_1 db 0
	COUNT_2 db 0
	COUNT_3 db 0
	COUNT_4 db 0
	KEEP_SS dw 0
	KEEP_SP dw 0
	KEEP_DX dw 0
ROUT_CODE:	
	push ax
	mov KEEP_SS,ss
	mov KEEP_SP,sp
	mov ax, seg INT_STACK
	mov ss, ax
	mov sp, 100h
	push ax
	push bx
	push cx
	push dx
	push ds
	push es
	
	call GET_CURS	
	push dx
	mov dx,01625h
	call SET_CURS
	
	cmp COUNT,0AH
	jl rout_skip
	mov count,0h
rout_skip:
	mov al,COUNT
	or al,30h
	call OUTPUT_AL
	
	pop dx
	call SET_CURS
	inc COUNT
	
	jmp int_end
	
	call GET_CURS
	push dx
	
	mov dh,22
	mov dl,40
	call SET_CURS
		
	cmp COUNT_1,10
	jl next_it
	mov COUNT_1,0
	add COUNT_2,1
	cmp COUNT_2,10
	jl next_it
	mov COUNT_2,0
	add COUNT_3,1
	cmp COUNT_3,10
	jl next_it
	mov COUNT_3,0
	add COUNT_4,1
	cmp COUNT_4,10
	jl next_it
	mov COUNT_4,0
	
next_it:
	
	mov al,COUNT_1    
	add al,30h
	call OUTPUT_AL
	
	mov dl,39
	call SET_CURS
	
	mov al,COUNT_2    
	add al,30h
	call OUTPUT_AL
	
	mov dl,38
	call SET_CURS
	
	mov al,COUNT_3    
	add al,30h
	call OUTPUT_AL
	
	mov dl,37
	call SET_CURS
	
	mov al,COUNT_4    
	add al,30h
	call OUTPUT_AL
	
	inc COUNT_1
	
	pop dx
	call SET_CURS
	
int_end:
	pop es
	pop ds
	pop dx
	pop cx
	pop bx
	pop ax 
	mov ss, KEEP_SS
	mov sp, KEEP_SP
	mov al,20h
	out 20h,al
	pop ax
	iret
end_inter:
ROUT ENDP
;---------------------------------------------------------------
CHECK_INT PROC
	mov AH,35h 
	mov AL,1Ch 
	int 21h 
			
	mov SI, offset SIGNATURE
	sub SI, offset ROUT
	
	mov AX,'00' ;сравнивание известных значений сигнатуры
	cmp AX,ES:[BX+SI]
	jne NO_LOADED
	cmp AX,ES:[BX+SI+2]
	jne NO_LOADED
	mov AX,1h
	ret
NO_LOADED:
	mov AX,0h
	ret
CHECK_INT ENDP
;---------------------------------------------------------------
LOADING_INT PROC near
	push ax
	push cx
	push bx
	push dx
	push ds
	mov ah, 35h
    mov al, 1Ch
    int 21h
    
    mov KEEP_IP, bx
    mov KEEP_CS, es
	mov ax, SEG ROUT
	mov dx, OFFSET ROUT
	mov ds,ax
	mov ah, 25h
    mov al, 1Ch
    int 21h
    
    mov dx, OFFSET end_inter
    mov cl,4
    shr dx,cl
    inc dx
    add dx, CODE
    sub dx, KEEP_PSP
    mov ah, 31h
    int 21h
    pop ds
	pop dx
	pop bx
	pop cx
	pop ax
	ret
LOADING_INT ENDP
;---------------------------------------------------------------
IS_UNLOAD PROC near
	push di
	mov di, 81h
	cmp byte ptr [di+0], ' '
	jne bad_key
	cmp byte ptr [di+1], '/'
	jne bad_key
  	cmp byte ptr [di+2], 'u'
 	jne bad_key
  	cmp byte ptr [di+3], 'n'
  	jne bad_key
  	cmp byte ptr [di+4], 0Dh
  	jne bad_key
  	cmp byte ptr [di+5], 0h
  	jne bad_key
	pop di
	mov al,1
	ret
bad_key:
	pop di
	mov al,0
	ret
IS_UNLOAD ENDP
;---------------------------------------------------------------
UNLOADING_INT PROC near
	push ax
	push dx
	mov ah, 35h
    mov al, 1Ch
    int 21h
    cli
    push ds
    mov dx, es:KEEP_IP
    mov ax, es:KEEP_CS
	mov ds, ax
    mov ah, 25h
    mov al, 1Ch
    int 21h
    pop ds

	mov es, es:KEEP_PSP
	push es
    mov es, es:[2Ch] 
    mov ah, 49h
    int 21h
    pop es
    mov ah, 49h
    int 21h

	sti	
	pop dx
	pop ax
	ret
UNLOADING_INT ENDP
;---------------------------------------------------------------
MAIN:
	push ds
    sub ax,ax
    push ax
    mov cs:KEEP_PSP, es
	
	call CHECK_INT
	cmp al, 1
	je loaded
	
	call IS_UNLOAD
	cmp al, 1
	je not_loaded
	
	mov dx, offset INT_LOADED
	mov ax,DATA
    mov ds,ax
	mov ah, 9
	int 21h
	call LOADING_INT
	jmp end_prog
	
not_loaded:
	mov dx, offset INT_NOT_LOADED
	mov ax,DATA
    mov ds,ax
	mov ah, 9
	int 21h
	jmp end_prog
	
loaded:
	call IS_UNLOAD
	cmp al, 1
	je need_to_unload
	
	mov dx, offset INT_ALR_LOADED
	mov ax,DATA
    mov ds,ax
	mov ah, 9
	int 21h
	jmp end_prog
	
need_to_unload:
	call UNLOADING_INT
	mov dx, offset INT_UNLOADED
	mov ax,DATA
    mov ds,ax
	mov ah, 9
	int 21h
	jmp end_prog	
	
end_prog:	
	xor al,al
	mov ah,4ch
	int 21h
LAST_BYTE:
CODE ENDS
END START