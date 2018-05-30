.286
SSEG SEGMENT stack
db 100h dup(?)
SSEG ENDS

DATA SEGMENT
	CB7 DB '04h: control block crached',0AH,0DH,'$'
    CB8 DB '04h: memory not enough ',0AH,0DH,'$'
    CB9 DB '04h: wrong address of control block',0AH,0DH,'$'
    
    NL1  DB '4B03: wrong function number', 0AH,0DH, '$'
    NL2  DB '4B03: file not found', 0AH,0DH, '$'
    NL3  DB '4B03: path error', 0AH,0DH, '$'
    NL4  DB '4B03: too many opened files', 0AH,0DH, '$'
    NL5  DB '4B03: not access', 0AH,0DH, '$'
    NL8  DB '4B03: memory not enough', 0AH,0DH, '$'
    NL10 DB '4B03: wrong environment', 0AH,0DH, '$'
    
    SZ2 DB '4Eh: file not found', 0AH,0DH, '$'
    SZ3 DB '4Eh: path not found', 0AH,0DH, '$'
    
    AM DB '48h: memory not allocate', 0ah, 0dh, '$'
    DAM DB '49h: memory not deallocate', 0ah, 0dh, '$'
    ;------------  PARAM_BLOCK  ------------------;
    PARAMS dw 0 , 0 ; сегментный адрес загрузки оверлея
    ;---------  END OF PARAM_BLOCK  --------------;
    PATH_PROMT db 81h dup(0)
    
    DTA_BUFFER db 43 dup(?)
DATA ENDS

CODE SEGMENT
	 ASSUME CS:CODE, DS:DATA, ES:DATA, SS:SSEG     


FREE_MEMORY PROC NEAR
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
    
    jnc free_memory_success
    jmp free_memory_error
    free_memory_success:
        pop es
        pop ds
        popa
        ret
    free_memory_error:
    
    next7:
    cmp ax, 7
    jne next8
    mov dx, offset CB7
    jmp print_label
    
    next8:
    cmp ax, 8
    jne next9
    mov dx, offset CB8
    jmp print_label
    
    next9:
    mov dx, offset CB9
   
    print_label:
    call print
    
    mov ah, 4ch
    mov al,0
    int 21h
FREE_MEMORY ENDP

PRINT_NOT_LOAD_ERROR PROC NEAR
    nextNL1:
    cmp ax, 1
    jne nextNL2
    mov dx, offset NL1
    jmp print_label_NL
    
    nextNL2:
    cmp ax, 2
    jne nextNL3
    mov dx, offset NL2
    jmp print_label_NL
   
    nextNL3:
    cmp ax, 3
    jne nextNL4
    mov dx, offset NL3
    jmp print_label_NL
    
    nextNL4:
    cmp ax, 4
    jne nextNL5
    mov dx, offset NL4
    jmp print_label_NL
    
    nextNL5:
    cmp ax, 5
    jne nextNL8
    mov dx, offset NL5
    jmp print_label_NL
    
    nextNL8:
    cmp ax, 8
    jne nextNL10
    mov dx, offset NL8
    jmp print_label_NL
    
    nextNL10:
    mov dx, offset NL10
 
    print_label_NL:
    call print
    
    xor AL,AL
	mov AH,4Ch
	int 21H
PRINT_NOT_LOAD_ERROR ENDP

PRINT PROC NEAR ; dx = OFFSET TO STR
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

init_child_path1 proc near
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
    
    cicl:
    cmp word ptr ds:[si], 0
    je break
    inc si
    jmp cicl
    break:
    
    add si,4
    mov di, offset PATH_PROMT
    
    cicl2:
    cmp byte ptr ds:[si], 0
    je break2
    mov al, ds:[si]
    mov byte ptr es:[di], al
    inc si
    inc di
    jmp cicl2
    break2:
    
    mov byte ptr es:[di-1], 'L'
    mov byte ptr es:[di-2], 'V'
    mov byte ptr es:[di-3], 'O'
    mov byte ptr es:[di-4], '.'
    mov byte ptr es:[di-5], '1'
    
    pop ds
    pop es
    popa
    ret
init_child_path1 endp

init_child_path2 proc near
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
    
    cicl_2:
    cmp word ptr ds:[si], 0
    je break_2
    inc si
    jmp cicl_2
    break_2:
    
    add si,4
    mov di, offset PATH_PROMT
    
    cicl_22:
    cmp byte ptr ds:[si], 0
    je break_22
    mov al, ds:[si]
    mov byte ptr es:[di], al
    inc si
    inc di
    jmp cicl_22
    break_22:
    
    mov byte ptr es:[di-1], 'L'
    mov byte ptr es:[di-2], 'V'
    mov byte ptr es:[di-3], 'O'
    mov byte ptr es:[di-4], '.'
    mov byte ptr es:[di-5], '2'
    
    pop ds
    pop es
    popa
    ret
init_child_path2 endp

GET_SIZE_OF_FILE PROC NEAR
    PUSH dx
    push cx
    PUSH DS
    
    mov dx, DATA
    mov ds, dx
    mov dx, offset PATH_PROMT
    mov cx, 0
    mov ah, 4Eh
    int 21h
    jnc sizeOfFile_success
    
    nextSZ2:
    cmp ax, 2
    jne nextSZ3
    mov dx, offset SZ2
    jmp print_label_SZ
    
    nextSZ3:
    mov dx, offset SZ3
    
    print_label_SZ:
    call PRINT
    
    mov ax, 0
    pop ds
    pop cx
    pop dx
    ret
    sizeOfFile_success:
    
    mov ax, [offset DTA_BUFFER+1Ah]
    ;mov dx, [offset DTA_BUFFER+1Ch]
    mov dx, 0
    
    shr ax, 4
    inc ax
    
    POP DS
    pop cx
    pop dx
    RET
GET_SIZE_OF_FILE ENDP

ALLOC_MEM PROC NEAR
    push bx
    mov bx, ax
    mov ah, 48h
    int 21h
    jnc continue_ALLOC
    
    mov dx, offset AM
    call print
    mov ah, 4ch
    int 21h
    
    continue_ALLOC:
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
    jnc del_next
    mov dx, offset DAM
    call PRINT 
    mov ah, 4ch
    mov al, 0
    int 21h
    del_next:
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
    call PRINT_NOT_LOAD_ERROR
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
    mov ax, offset exit_of_overlay
    push ax
    jmp dword ptr ds:PARAMS
    exit_of_overlay:
    pop es
    pop ds
    popa
    ret
RUN_OVL ENDP

START:
	push DS 
	sub AX,AX 
	push AX 
    mov cs:KEEP_PSP, ds
    
    call FREE_MEMORY
    
    call init_child_path1
    call GET_SIZE_OF_FILE
    cmp ax, 0
    je next_ovl
        call ALLOC_MEM
        call LOAD_OVL
        call RUN_OVL
        call DEALLOC_MEM
    next_ovl:
    
    call init_child_path2
    call GET_SIZE_OF_FILE
    cmp ax, 0
    je exit_of_prog
        call ALLOC_MEM
        call LOAD_OVL
        call RUN_OVL
        call DEALLOC_MEM
    exit_of_prog:
    
    mov ah, 4ch
    mov al, 0
    int 21h
    
    KEEP_PSP DW 0h
    last_byte:
CODE ENDS
END START