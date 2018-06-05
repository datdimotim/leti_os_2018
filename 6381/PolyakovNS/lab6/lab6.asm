DATA SEGMENT
	ERROR_FREEING		db 'Error when freeing memory: $'
	ERROR_MCM 			db 'MCB is destroyed$'
	ERROR_NO_MEM 		db 'Not enough memory for function processing$'
	ERROR_WRONG_ADDR 	db 'Wrong addres of memory block$'
	ERROR_NUKNOWN		db 'Unknown error$'
		
	ERROR_WRONG_NUM			db 'Function number is wrong$'
	ERROR_FILE_NOT_FOUND	db 'File is not found$'
	ERROR_DISK				db 'Disk error$'
	ERROR_NO_MEM2			db 'Not enough memory$'
	ERROR_WRONG_ENV			db 'Wrong environment string$'
	ERROR_WRONG_FORMAT		db 'Wrong format$'

	END_NORM	db 'Normal end$'
	END_CTRL_С	db 'End by Ctrl-C$'
	END_ERROR	db 'End by device error$'
	END_31h		db 'End by 31h function$'
	END_NUKNOWN	db 'End by unknown reason$'
	END_CODE	db 'End code: $'
		
	STRENDL db 13,10,'$'
	PAR_BLOCK 	dw 0 
				dd ? 
				dd 0 
				dd 0 
	PROG_PATH	db 20h dup(0)
	KEEP_SS dw 0
	KEEP_SP dw 0
DATA ENDS

CODE SEGMENT
 ASSUME CS:CODE, DS:DATA, ES:DATA, SS:STACKSEG
;---------------------------------------
PRINT PROC near
	push ax
	mov AH,09h
	int 21h
	pop ax
	ret
PRINT ENDP
;---------------------------------------
TETR_TO_HEX PROC near
	and AL,0Fh
	cmp AL,09
	jbe NEXT
	add AL,07
NEXT: add AL,30h
	ret
TETR_TO_HEX ENDP
;---------------------------------------
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
;---------------------------------------
FREE_MEM PROC
		mov ax,STACKSEG 
		mov bx,es
		sub ax,bx 
		add ax,10h 
		mov bx,ax
		mov ah,4Ah
		int 21h
		jnc MEM_FREED	

		mov dx,offset ERROR_FREEING
		call PRINT
		cmp ax,7
		mov dx,offset ERROR_MCM
		je FREE_MEM_PRINT_ERROR
		cmp ax,8
		mov dx,offset ERROR_NO_MEM
		je FREE_MEM_PRINT_ERROR
		cmp ax,9
		mov dx,offset ERROR_WRONG_ADDR
		
		FREE_MEM_PRINT_ERROR:
		call PRINT
		mov dx,offset STRENDL
		call PRINT
	
		xor AL,AL
		mov AH,4Ch
		int 21H
	
	MEM_FREED:
	ret
FREE_MEM ENDP
;---------------------------------------
CREATE_BLOCK PROC
	mov ax, es:[2Ch]
	mov PAR_BLOCK,ax 
	mov PAR_BLOCK+2,es 
	mov PAR_BLOCK+4,80h 
	ret
CREATE_BLOCK ENDP
;---------------------------------------
RUN_PROG PROC
	mov dx,offset STRENDL
	call PRINT
	mov es,es:[2ch]
	mov si,0
next1:
	mov dl,es:[si]
	cmp dl,0
	je end_path
	inc si
	jmp next1
	
end_path:
	inc si
	mov dl,es:[si]
	cmp dl,0
	jne next1
	add si,3
	lea di,PROG_PATH
	
next2:
	mov dl, es:[si]
	cmp dl,0
	je end_copy
	mov [di],dl
	inc di
	inc si
	jmp next2
	
end_copy:
	sub di,8
	
	mov [di], byte ptr 'l'	
	mov [di+1], byte ptr 'a'
	mov [di+2], byte ptr 'b'
	mov [di+3], byte ptr '2'
	mov [di+4], byte ptr '.'
	mov [di+5], byte ptr 'c'
	mov [di+6], byte ptr 'o'
	mov [di+7], byte ptr 'm'

	mov dx,offset PROG_PATH
	
	mov KEEP_SP, sp
	mov KEEP_SS, ss
		
	mov ax,ds
	mov es,ax
	mov bx,offset PAR_BLOCK
	
	mov ax,4b00h
	int 21h
	jnc NO_ERRORS
	
	push ax
	mov ax,DATA
	mov ds,ax
	pop ax
	mov SS,KEEP_SS
	mov SP,KEEP_SP
	
	cmp ax,1
	mov dx,offset ERROR_WRONG_NUM
	je PRINT_ERROR
	cmp ax,2
	mov dx,offset ERROR_FILE_NOT_FOUND
	je PRINT_ERROR
	cmp ax,5
	mov dx,offset ERROR_DISK
	je PRINT_ERROR
	cmp ax,8
	mov dx,offset ERROR_NO_MEM2
	je PRINT_ERROR
	cmp ax,10
	mov dx,offset ERROR_WRONG_ENV
	je PRINT_ERROR
	cmp ax,11
	mov dx,offset ERROR_WRONG_FORMAT	
	je PRINT_ERROR
	mov dx,offset ERROR_NUKNOWN
PRINT_ERROR:
	call PRINT
	mov dx,offset STRENDL
	call PRINT
	
	xor al,al
	mov ah,4Ch
	int 21H
		
NO_ERRORS:
	mov ax,4d00h
	int 21h
	cmp ah,0
	mov dx,offset END_NORM
	je PRINT_NORMAL_END
	cmp ah,1
	mov dx,offset END_CTRL_С
	je PRINT_NORMAL_END
	cmp ah,2
	mov dx,offset END_ERROR
	je PRINT_NORMAL_END
	cmp ah,3
	mov dx,offset END_31h
	je PRINT_NORMAL_END
	mov dx,offset END_NUKNOWN

PRINT_NORMAL_END:
	call PRINT
	mov dx,offset STRENDL
	call PRINT

	mov dx,offset END_CODE
	call PRINT
	call BYTE_TO_HEX
	push ax
	mov ah,2
	mov dl,al
	int 21h
	pop ax
	xchg ah,al
	mov ah,2
	mov dl,al
	int 21h
	mov dx,offset STRENDL
	call PRINT

	ret
RUN_PROG ENDP
;---------------------------------------
MAIN PROC FAR
	mov ax,data
	mov ds,ax
	
	call FREE_MEM
	call CREATE_BLOCK
	call RUN_PROG
	
	xor al,al
	mov ah,4Ch
	int 21H
	ret
MAIN ENDP
CODE ENDS

STACKSEG SEGMENT STACK
	dw 80h dup (?) 
STACKSEG ENDS
END MAIN