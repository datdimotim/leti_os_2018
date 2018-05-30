.286
SSEG SEGMENT stack
db 100h dup(?)
SSEG ENDS

DATA SEGMENT
	CB7 DB '04h: control block crached',0AH,0DH,'$'
    CB8 DB '04h: memory not enough ',0AH,0DH,'$'
    CB9 DB '04h: wrong address of control block',0AH,0DH,'$'
    
    NL1  DB '4B00: wrong function number', 0AH,0DH, '$'
    NL2  DB '4B00: file not found', 0AH,0DH, '$'
    NL5  DB '4B00: disk error', 0AH,0DH, '$'
    NL8  DB '4B00: memory not enough', 0AH,0DH, '$'
    NL10 DB '4B00: promt of environment icorrect', 0AH,0DH, '$'
    NL11 DB '4B00: wrong format', 0AH,0DH, '$'
    
    RC0 DB 0AH,0DH,'program exit normally', 0AH,0DH, '$'
    RC1 DB 0AH,0DH,'program exit by Ctrl-Break', 0AH,0DH, '$'
    RC2 DB 0AH,0DH,'program exit by divice error', 0AH,0DH, '$'
    RC3 DB 0AH,0DH,'program exit as resident', 0AH,0DH, '$'
    
    RET_CODE db 'al =  ',0ah, 0dh, '$'
    
    ;------------  PARAM_BLOCK  ------------------;
    PARAMS dw 0 ; сегментный адрес среды
    dw DATA, offset CMD_PROMT ;сегмент и смещение командной строки
    dd 0
    dd 0
    ;---------  END OF PARAM_BLOCK  --------------;
    CMD_PROMT db 0, ''
    PATH_PROMT db 81h dup(0)
DATA ENDS

CODE SEGMENT
	 ASSUME CS:CODE, DS:CODE, ES:CODE, SS:SSEG     


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
    jne nextNL5
    mov dx, offset NL2
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
    cmp ax, 10
    jne nextNL11
    mov dx, offset NL10
    jmp print_label_NL
    
    nextNL11:
    mov dx, offset NL10
 
    print_label_NL:
    call print
    
    xor AL,AL
	mov AH,4Ch
	int 21H
PRINT_NOT_LOAD_ERROR ENDP

PRINT_RETURN_CODE PROC NEAR
    nextRC0:
    cmp ah, 0
    jne nextRC1
    mov dx, offset RC0
    jmp print_label_RC
    
    nextRC1:
    cmp ah, 1
    jne nextRC2
    mov dx, offset RC1
    jmp print_label_RC
    
    nextRC2:
    cmp ah, 2
    jne nextRC3
    mov dx, offset RC2
    jmp print_label_RC
    
    nextRC3:
    mov dx, offset RC3
    
    print_label_RC:
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
PRINT_RETURN_CODE ENDP

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

init_child_path proc near
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
    
    mov byte ptr es:[di-1], 'm'
    mov byte ptr es:[di-2], 'o'
    mov byte ptr es:[di-3], 'c'
    mov byte ptr es:[di-5], '2'
    
    pop ds
    pop es
    popa
    ret
init_child_path endp

START:
	push DS 
	sub AX,AX 
	push AX 
    mov cs:KEEP_PSP, ds
    
    call FREE_MEMORY
    
    call init_child_path 
    
    mov bx, DATA
    mov es, bx
    mov ds, bx
    mov bx, offset PARAMS
    push ds
    mov cs:KEEP_SS, ss
    mov cs:KEEP_SP, sp
    mov dx, offset PATH_PROMT
    mov ax, 4b00h
    int 21h
    mov ss, cs:KEEP_SS
    mov sp, cs:KEEP_SP
    pop ds
    jnc continue
    call PRINT_NOT_LOAD_ERROR
    
    continue:
    mov ah, 4dh
    int 21h
    
    call PRINT_RETURN_CODE
    
    KEEP_PSP DW 0h
    KEEP_SS DW 0h
    KEEP_SP DW 0h
    last_byte:
CODE ENDS
END START