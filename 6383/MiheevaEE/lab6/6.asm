.286
ASTACK SEGMENT stack
db 100h dup(?)
ASTACK ENDS

DATA SEGMENT
    
 
    EXITED0 DB 0AH,0DH,'EXITED NORMALLY', 0AH,0DH, '$'
    EXITED1 DB 0AH,0DH,'EXITED BY CTRL-BREAK', 0AH,0DH, '$'
    EXITED2 DB 0AH,0DH,'EXITED BY DEVICE ERROR', 0AH,0DH, '$'
    EXITED3 DB 0AH,0DH,'EXITED BY 31h FUNCTION', 0AH,0DH, '$'

    BLOCK_MIS7 DB 'CONTROLLING MEMORY BLOCK DESTROYED',0AH,0DH,'$'
    BLOCK_MIS8 DB 'MEMORY NOT ENOUGH',0AH,0DH,'$'
    BLOCK_MIS9 DB 'WRONG ADDRESS OF MEMORY BLOCK',0AH,0DH,'$'

    LOAD_ERR1  DB 'WRONG NUMBER OF FUN', 0AH,0DH, '$'
    LOAD_ERR2  DB 'FILE NOT FOUND', 0AH,0DH, '$'
    LOAD_ERR5  DB 'DISK ERROR', 0AH,0DH, '$'
    LOAD_ERR8  DB 'MEMORY NOT ENOUGH', 0AH,0DH, '$'
    LOAD_ERR10 DB 'WRONG PROMT OF ENVIRONMENT', 0AH,0DH, '$'
    LOAD_ERR11 DB 'WRONG FORMAT', 0AH,0DH, '$'
    
    RET_CODE db 'AL=  ',0ah, 0dh, '$'
    
  

    ;;;PARAM BLOCK
    PARAMS dw 0 
    dw DATA, offset CMD
;;;;;;;
 PATH   db 81h dup(0)
    CMD db 0, ''

DATA ENDS

CODE SEGMENT
	 ASSUME CS:CODE, DS:CODE, ES:CODE, SS:ASTACK     


MEMORY_FREE PROC NEAR
    pusha
    push ds
    push es
    
    mov dx, cs:KEEP_PSP 
    mov es, dx
    mov bx, offset last_byte
    shr bx, 4
    inc bx
    add bx, CODE
    sub bx, cs:KEEP_PSP
    mov ah, 4Ah
    int 21h
    
    jnc FREE_MEM_SUCCSESS
    jmp FREE_MEM_ERROR
    FREE_MEM_SUCCSESS:
        pop es
        pop ds
        popa
        ret
    FREE_MEM_ERROR:
    
    BM7:
    cmp ax, 7
    jne BM8
    mov dx, offset BLOCK_MIS7
    jmp end_fun
    
    BM8:
    cmp ax, 8
    jne BM9
    mov dx, offset BLOCK_MIS8
    jmp end_fun
    
    BM9:
    mov dx, offset BLOCK_MIS9
   
    end_fun:
    call print
    
    mov ah, 4ch
    mov al,0
    int 21h
MEMORY_FREE ENDP

NOT_LOADED_ERROR PROC NEAR
    LE1:
    cmp ax, 1
    jne LE2
    mov dx, offset LOAD_ERR1
    jmp NOT_LOADED
    
    LE2:
    cmp ax, 2
    jne LE5
    mov dx, offset LOAD_ERR2
    jmp NOT_LOADED
   
    LE5:
    cmp ax, 5
    jne LE8
    mov dx, offset LOAD_ERR5
    jmp NOT_LOADED
    
    LE8:
    cmp ax, 8
    jne LE10
    mov dx, offset LOAD_ERR8
    jmp NOT_LOADED
    
    LE10:
    cmp ax, 10
    jne LE11
    mov dx, offset LOAD_ERR10
    jmp NOT_LOADED
    
    LE11:
    mov dx, offset LOAD_ERR11
 
   NOT_LOADED:
    call print
    
    xor AL,AL
	mov AH,4Ch
	int 21H
NOT_LOADED_ERROR ENDP

RETURN_CODE PROC NEAR
    EXT0:
    cmp ah, 0
    jne EXT1
    mov dx, offset EXITED0
    jmp EXITED
    
    EXT1:
    cmp ah, 1
    jne EXT2
    mov dx, offset EXITED1
    jmp EXITED
    
    EXT2:
    cmp ah, 2
    jne EXT3
    mov dx, offset EXITED2
    jmp EXITED
    
    EXT3:
    mov dx, offset EXITED3
    
    EXITED:
    call print
    
    mov dx, DATA
    mov ds, dx
    mov dx, offset RET_CODE
    mov di, dx
    mov byte ptr [di+5], al
    call print 
    xor AL,AL
	mov AH,4Ch
	int 21H
RETURN_CODE ENDP

PRINT PROC NEAR 
    pusha
    push ds
    mov ax, DATA
    mov ds, ax
    mov ah, 09h
    int 21h
    pop ds
    popa
    ret
PRINT ENDP

CHILD_PATH proc near
    pusha
    push es
    push ds
    mov dx, cs:KEEP_PSP
    mov ds, dx
    mov dx, DATA
    mov es, dx
    mov dx, ds:[2ch]
    mov ds, dx 
    mov si, 0
    cycle:
    cmp word ptr ds:[si], 0
    je endcycle
    inc si
    jmp cycle
    endcycle:
    add si,4
    mov di, offset PATH
    loop:
    cmp byte ptr ds:[si], 0
    je endloop
    mov al, ds:[si]
    mov byte ptr es:[di], al
    inc si
    inc di
    jmp loop
    endloop:
   ;;;;name of loading prog
    CALL GET_NAME
    pop ds
    pop es
    popa
    ret
CHILD_PATH ENDP

GET_NAME PROC NEAR
    mov byte ptr es:[di-1], 'm'
    mov byte ptr es:[di-2], 'o'
    mov byte ptr es:[di-3], 'c'
    mov byte ptr es:[di-4], '.'
    mov byte ptr es:[di-5], '2'
ret
GET_NAME ENDP


BEGIN:
	push DS 
	sub AX,AX 
	push AX 
    mov cs:KEEP_PSP, ds
    
    call MEMORY_FREE
    call CHILD_PATH  
    mov bx, DATA
    mov es, bx
    mov ds, bx
    mov bx, offset PARAMS
    push ds
    mov cs:KEEP_SS, ss
    mov cs:KEEP_SP, sp
    mov dx, offset PATH
    mov ax, 4b00h
    int 21h
    mov ss, cs:KEEP_SS
    mov sp, cs:KEEP_SP
    pop ds
    jnc ret_codee
    call NOT_LOADED_ERROR
    ret_codee:
    mov ah, 4dh
    int 21h  
    call RETURN_CODE
    
    KEEP_PSP DW 0h
    KEEP_SS DW 0h
    KEEP_SP DW 0h
    last_byte:
CODE ENDS
END BEGIN
