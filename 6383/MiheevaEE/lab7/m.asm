.286
SSEG SEGMENT stack
db 100h dup(?)
SSEG ENDS

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


    SZ2 DB 'FILE NOT FOUND', 0AH,0DH, '$'
    SZ3 DB 'PATH NOT FOUND', 0AH,0DH, '$'
    
    MEM_ALLOC DB 'MEM NOT ALLOCATED', 0ah, 0dh, '$'
    MEM_DEALLOC DB 'MEM NOT DEALLOCATED', 0ah, 0dh, '$'
    
    RET_CODE db 'AL=  ',0ah, 0dh, '$'
    
    ALLOC_M DB 'MEM NOT ALLOCATED', 0ah, 0dh, '$'
    DEALLOC_M DB 'MEM NOT DEALLOCETED', 0ah, 0dh, '$'
    ;------------  PARAM_BLOCK  ------------------;
    PARAMS dw 0 , 0 ; сегментный адрес загрузки оверлея
    ;---------  END OF PARAM_BLOCK  --------------;
    CMD_PROMT db 0, ''
    PATH_PROMT db 81h dup(0)
    
    DTA_BUFFER db 43 dup(?)
DATA ENDS

CODE SEGMENT
	 ASSUME CS:CODE, DS:DATA, ES:DATA, SS:SSEG     


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

CHILD_PATH1 proc near
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
    mov di, offset PATH_PROMT
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
    CALL GET_NAME1
    pop ds
    pop es
    popa
    ret
CHILD_PATH1 ENDP

GET_NAME1 PROC NEAR
    mov byte ptr es:[di-1], 'l'
    mov byte ptr es:[di-2], 'v'
    mov byte ptr es:[di-3], 'o'
    mov byte ptr es:[di-4], '.'
    mov byte ptr es:[di-5], '0'
ret
GET_NAME1 ENDP


CHILD_PATH2 proc near
    pusha
    push es
    push ds
    mov dx, cs:KEEP_PSP
    mov ds, dx
    mov dx, DATA
    mov es, dx
    mov dx, ds:[2ch]
    mov ds, dx ; es - среда
    mov si, 0
    
    cycle2:
    cmp word ptr ds:[si], 0
    je break2
    inc si
    jmp cycle2
    break2:
    
    add si,4
    mov di, offset PATH_PROMT
    
    loop2:
    cmp byte ptr ds:[si], 0
    je breaker
    mov al, ds:[si]
    mov byte ptr es:[di], al
    inc si
    inc di
    jmp loop2
    breaker:
    
    ;;;;name of loading prog
    CALL GET_NAME2
    pop ds
    pop es
    popa
    ret
    
    pop ds
    pop es
    popa
    ret
CHILD_PATH2 endp

GET_NAME2 PROC NEAR
    mov byte ptr es:[di-1], 'l'
    mov byte ptr es:[di-2], 'v'
    mov byte ptr es:[di-3], 'o'
    mov byte ptr es:[di-4], '.'
    mov byte ptr es:[di-5], '1'
ret
GET_NAME2 ENDP
    
GET_SIZE_OF_FILE PROC NEAR
    PUSH dx
   push cx
    PUSH DS
    ;pusha
    mov dx, DATA
    mov ds, dx
    mov dx, offset PATH_PROMT
    mov cx, 0
    mov ah, 4Eh
    int 21h
    jnc file_size_good
    
    nextSZ2:
    cmp ax, 2
    jne nextSZ3
    mov dx, offset SZ2
    jmp print_SZ
    
    nextSZ3:
    mov dx, offset SZ3
    
    print_SZ:
    call PRINT
	call OVL2
    jmp enddd
    ;mov ah, 4ch
    ;int 21h
    file_size_good:
    
    mov ax, [offset DTA_BUFFER+1Ah]
    mov dx, 0
call OVL1
call OVL2
    enddd:
    shr ax, 4
    inc ax
    POP DS
    pop cx
    pop dx
    RET
GET_SIZE_OF_FILE ENDP


GET_SIZE_OF_FILE1 PROC NEAR
    PUSH dx
    push cx
    PUSH DS
    
    mov dx, DATA
    mov ds, dx
    mov dx, offset PATH_PROMT
    mov cx, 0
    mov ah, 4Eh
    int 21h
    jnc file_size_good1
    
    nextSZ21:
    cmp ax, 2
    jne nextSZ31
    mov dx, offset SZ2
    jmp print_SZ1
    
    nextSZ31:
    mov dx, offset SZ3
    
   print_SZ1:
    call PRINT
    
    mov ah, 4ch
    int 21h
   file_size_good1:
    
    mov ax, [offset DTA_BUFFER+1Ah]
    mov dx, 0
    
    shr ax, 4
    inc ax
    
    POP DS
    pop cx
    pop dx
    RET
GET_SIZE_OF_FILE1 ENDP


ALLOC_MEM PROC NEAR
    push bx
    mov bx, ax
    mov ah, 48h
    int 21h
    jnc ALLOCC
    
    mov dx, offset ALLOC_M
    call print
    mov ah, 4ch
    int 21h
    
   ALLOCC:
    pop bx
    ret
ALLOC_MEM ENDP

DEALLOC_MEM PROC NEAR
    pusha
    push dx
    push es
    mov dx, DATA
    mov ds, dx
    mov ah, 49h
    mov dx, ds:PARAMS+2
    mov es, dx
    int 21h
    jnc rem_con
    mov dx, offset DEALLOC_M
    call PRINT 
    mov ah, 4ch
    mov al, 0
    int 21h
    rem_con:
    pop es
    pop dx
    popa
    ret
DEALLOC_MEM ENDP

LOAD_OVL PROC NEAR
    pusha
    push ds
    push es
    mov bx, DATA
    mov ds, bx
    mov es, bx
    mov ds:PARAMS+2, ax
    
    mov bx, offset PARAMS+2
    mov dx, offset PATH_PROMT
    mov ax, 4B03h
    int 21h
    jnc continue
    call NOT_LOADED_ERROR
    continue:
    pop es
    pop ds
    popa
    ret
LOAD_OVL ENDP

RUN_OVL PROC NEAR
    pusha
    push ds
    push es
    mov dx, DATA
    mov ds, dx
    push cs
    mov ax, offset exit_from_ovl
    push ax
    jmp dword ptr ds:PARAMS
    exit_from_ovl:
    pop es
    pop ds
    popa
    ret
RUN_OVL ENDP

OVL1 PROC NEAR
     
    call ALLOC_MEM
    call LOAD_OVL
    call RUN_OVL
    call DEALLOC_MEM
    ret
OVL1 ENDP

OVL2 PROC NEAR
    ;call MEMORY_FREE
    call CHILD_PATH2
    call GET_SIZE_OF_FILE1
    call ALLOC_MEM
    call LOAD_OVL
    call RUN_OVL
    call DEALLOC_MEM

mov ah, 4ch
    mov al, 0
    int 21h
    ret
OVL2 ENDP

BEGIN:
	push DS 
	sub AX,AX 
	push AX 
    mov cs:KEEP_PSP, ds
    
call MEMORY_FREE
    call CHILD_PATH1
    call GET_SIZE_OF_FILE

  
    
    mov ah, 4ch
    mov al, 0
    int 21h
    
    KEEP_PSP DW 0h
    last_byte:
CODE ENDS
END BEGIN
