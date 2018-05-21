com_segment     SEGMENT
           ASSUME  CS:com_segment, DS:com_segment, ES:NOTHING, SS:NOTHING
		   org 100h
START:     JMP     BEGIN

string_key db 13, 10, "Press any key...$"
name_ db 13, 10, "Name: $"
head db 13, 10, "MCB #0   $"
empty db "Empty area $"
umb_driver db "Area belongs to OS XMS UMB driver $"
driver_memory db "Area of excluded upper driver memory $"
ms_dos db "Area belongs to MS DOS $"
umb_386MAX_occur db "Area occuped by control block 386MAX UMB $"
umb_386MAX_block db "Area blocked 386MAX $"
umb_386MAX_belong db "Area belongs 386MAX UMB$"
size_ db 13, 10, "Size: $"
owner db 13, 10, "Owner: $"
addr_ db 13, 10, "Addres:           $"
size_av_mem db 13, 10, "Size of available memory: $"
size_ext_mem db 13, 10, "Size of extended memory: $"
owner_ db 13, 10, "Owner:         $"
byte_ db " byte $"
enter_ db 13, 10,"$"
free db 13, 10, "Memory is freeing $"
not_free_mem db 13, 10, "Can't free mermory$"
free_mem_sucs db 13, 10, "Memory is free sucsessful!$"
not_get_mem db 13, 10, "Can't get mermory$"
get db 13, 10, "Getting mermory...$"
get_mem_sucs db 13, 10, "Memory is getting sucsessful!$"


;-------------------------------
PRINT_SIZE PROC
	mov bx,10h
	mul bx
	mov bx,0ah
	xor cx,cx
del:
	div bx
	push dx
	inc cx
	xor dx,dx
	cmp ax, 0
	jnz del
write_symb:
	pop dx
	or dl,30h
	mov ah,02h
	int 21h
	loop write_symb
	ret
PRINT_SIZE ENDP
;------------------------------
CLRSCR PROC
	push ax
	lea dx, string_key
	call WRITE
	mov ah, 01h
	int 21h
	mov ax, 3 
	int 10h
	pop ax
	ret
CLRSCR ENDP
;-------------------------------
FREE_MEM   PROC  near
    push ax
    push bx
    push cx
    push dx
    lea dx, free
    call WRITE

    lea bx, end_
    mov cl, 04h
    add bx, 10Fh
    shr bx, cl
    mov ah, 4Ah
    int 21h
    jnc good
    lea dx, not_free_mem
    call WRITE
    jmp the_end
	
good:
    lea dx, free_mem_sucs
    call WRITE

    pop dx
    pop cx
    pop bx
    pop ax
    ret
FREE_MEM   ENDP
;-------------------------------
GET_MEM   PROC  near
           push ax
           push bx
           push dx
           lea dx, get
           call WRITE
           mov bx, 1000h
           mov ah, 48h
           int 21h
           jnc good2
           lea dx, not_get_mem
           call WRITE
           jmp the_end
good2:
           lea dx, get_mem_sucs
           call WRITE
           pop dx
           pop bx
           pop ax
           ret
GET_MEM    ENDP
;-------------------------------
MEM_INFO PROC
	mov AL, 30h
    out 70h, AL
    in AL, 71h
    mov BL, AL
    mov AL, 31h
    out 70h, AL
    in AL, 71h

	mov bh, al   ;вывод размера расширенной памяти
	mov ax, bx
	lea dx, size_ext_mem
    call WRITE
	call PRINT_SIZE
	lea dx, byte_
    call WRITE

	mov ah, 52h
	int 21h
	mov ax, es:[bx-2]
	mov es, ax   ;в es адрес первого МСВ
	xor cx, cx
	inc cx       ;номер МСВ

	lea dx, enter_
	call WRITE
next_MCB:
	lea si, head
	add si, 8
	mov al, cl
	push cx
	call byte_to_dec
	lea dx, head
	call WRITE
	
	mov ax, es
	lea di, addr_
	add di, 14
	call wrd_to_hex
	lea dx, addr_
	call WRITE
	
	xor ah, ah
	mov al, es:[0]
	push ax
	mov ax, es:[1]
	cmp ax, 0000h
	je l1
	cmp ax, 0006h
	je l2
	cmp ax, 0007h
	je l3
	cmp ax, 0008h
	je l4
	cmp ax, 0FFFAh
	je l5
	cmp ax, 0FFFDh
	je l6
	cmp ax, 0FFFEh
	je l7
	lea di, owner_
	add di, 12
	call wrd_to_hex
	lea dx, owner_
	call WRITE
	jmp go
l1:
	lea dx, owner
	call WRITE
	lea dx, empty
	call WRITE
	jmp go
l2:
	lea dx, owner
	call WRITE
	lea dx, umb_driver
	call WRITE
	jmp go
l3:
	lea dx, owner
	call WRITE
	lea dx, driver_memory
	call WRITE
	jmp go
l4:
	lea dx, owner
	call WRITE
	lea dx, ms_dos
	call WRITE
	jmp go
l5:
	lea dx, owner
	call WRITE
	lea dx, umb_386MAX_occur
	call WRITE
	jmp go
l6:
	lea dx, owner
	call WRITE
	lea dx, umb_386MAX_block
	call WRITE
	jmp go
l7:
	lea dx, owner
	call WRITE
	lea dx, umb_386MAX_belong
	call WRITE

go:

	mov ax,es:[3]	
	lea dx, size_
	call WRITE
	call PRINT_SIZE
	lea dx, byte_
	call WRITE
	
	lea dx , name_ 
	call WRITE
	mov cx, 8
	xor di, di
write_:
	mov dl, es:[di+8]
	mov ah, 02h
	int 21h
	inc di
	loop write_	
	
	mov ax, es:[3]	
	mov bx, es
	add bx, ax
	inc bx
	mov es, bx
	pop ax
	pop cx
	inc cx
	cmp al, 5ah
	je exit
	cmp al, 4dh 
	jne err
	lea dx, enter_
	call WRITE
	call CLRSCR
	jmp next_MCB
	
err:
exit:

	ret
MEM_INFO ENDP
;-------------------------------
WRITE   PROC
        push ax
        mov ah,09h
        int 21h
        pop ax
        ret
WRITE   ENDP
;-------------------------------
TETR_TO_HEX   PROC  near
           and      AL,0Fh
           cmp      AL,09
           jbe      NEXT
           add      AL,07
NEXT:      add      AL,30h
           ret
TETR_TO_HEX   ENDP
;-------------------------------
BYTE_TO_HEX   PROC  near
           push     CX
           mov      AH,AL
           call     TETR_TO_HEX
           xchg     AL,AH
           mov      CL,4
           shr      AL,CL
           call     TETR_TO_HEX 
           pop      CX          
           ret
BYTE_TO_HEX  ENDP
;-------------------------------
WRD_TO_HEX   PROC  near
           push     BX
           mov      BH,AH
           call     BYTE_TO_HEX
           mov      [DI],AH
           dec      DI
           mov      [DI],AL
           dec      DI
           mov      AL,BH
           call     BYTE_TO_HEX
           mov      [DI],AH
           dec      DI
           mov      [DI],AL
           pop      BX
           ret
WRD_TO_HEX ENDP
;--------------------------------------------------
BYTE_TO_DEC   PROC  near
           push     CX
           push     DX
           xor      AH,AH
           xor      DX,DX
           mov      CX,10
loop_bd:   div      CX
           or       DL,30h
           mov      [SI],DL
		   dec		si
           xor      DX,DX
           cmp      AX,10
           jae      loop_bd
           cmp      AL,00h
           je       end_l
           or       AL,30h
           mov      [SI],AL
		   
end_l:     pop      DX
           pop      CX
           ret
BYTE_TO_DEC    ENDP
;-------------------------------
BEGIN:
          mov ah,4Ah        ;определение размера доступной памяти
		  mov bx,0FFFFh
	      int 21h

		  mov ax,bx
		  lea dx,size_av_mem
		  call WRITE
		  call PRINT_SIZE ;вывод размера доступной памяти		  
		  lea dx, byte_
		  call WRITE
		  
		  call GET_MEM
		  call FREE_MEM
		  call MEM_INFO

; выход в DOS
the_end:
           xor     AL, AL
           mov     AH, 4Ch
           int     21H
dw 128 dup(0)		   
end_:		   
com_segment    ENDS
           END     START