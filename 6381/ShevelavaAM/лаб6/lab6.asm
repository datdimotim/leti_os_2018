.model small

.data

lab2_ended_success db 13, 10, 13, 10, "Process was end successfully with code  $"
lab2_ended_ctrlc db 13, 10, "Process was end with ctrl+c$"
file_not_exist db 13, 10, "Error! File doesn't exist ", 13, 10, "$"
name_file db 50 dup(0)
end_of_line db "$"
enter_ db 13, 10, "$"
parameters dw 7 dup(?)
save_ss dw ?
save_sp dw ?
error_free_mem db 0

.stack 100h

.code
;----------------------------------------------
TETR_TO_HEX   PROC  near
		and      AL,0Fh
		cmp      AL,09
		jbe      NEXT_
		add      AL,07
NEXT_:	add      AL,30h
		ret
TETR_TO_HEX   ENDP
;----------------------------------------------
BYTE_TO_HEX   PROC  near
; байт в AL переводится в два символа шестн. числа в AX
		push     CX
		mov      AH,AL
		call     TETR_TO_HEX
		xchg     AL,AH
		mov      CL,4
		shr      AL,CL
		call     TETR_TO_HEX ;в AL старшая цифра
		pop      CX          ;в AH младшая
		ret
BYTE_TO_HEX  ENDP
;----------------------------------------------
WRITE PROC
		push ax
		mov ah, 09h
		int 21h
		pop ax
		ret
WRITE ENDP
;----------------------------------------------
FREE_MEMORY PROC
		lea bx, end_of_programm
		mov ax, es
		sub bx, ax
		mov cl, 4
		shr bx, cl   	 ;в bx размер памяти в параграфах
		mov ah, 4Ah     
		int 21h
		jc error_
		jmp no_error
error_:
		mov error_free_mem, 1
no_error:
		ret
FREE_MEMORY ENDP
;----------------------------------------------
EXIT_PROGRAMM PROC
		mov ah, 4dh
		int 21h
		cmp ah, 1   
		je error_end_lab2
		lea dx, enter_
		call WRITE
		lea bx, lab2_ended_success
		mov [bx], ax
		lea dx, lab2_ended_success
		call WRITE
		call byte_to_Hex
		push ax
		mov dl, al
		mov ah, 2h
		int 21h
		pop ax
		mov dl, ah
		mov ah, 2h
		int 21h
		jmp theend
error_end_lab2:
		lea dx, lab2_ended_ctrlc
		call WRITE
theend:
		ret
EXIT_PROGRAMM ENDP
;----------------------------------------------
MAIN proc

		mov ax, @data
		mov ds, ax
	
		push si
		push di
		push es
		push dx
		mov es, es:[2Ch]			;адрес среды
		xor si, si
		lea di, name_file
read_string: 
		cmp byte ptr es:[si], 00h
		je next
		inc si
		jmp find_end
next:
		inc si
find_end:       
		cmp word ptr es:[si], 0000h
		jne read_string
		add si, 4
path_loop:
		cmp byte ptr es:[si], 00h
		je change_last_symbols
		mov dl, es:[si]
		mov [di], dl
		inc si
		inc di
		jmp path_loop
change_last_symbols:
		sub di, 5
		mov dl, '2'
		mov [di], dl
		add di, 2
		mov dl, 'c'
		mov [di], dl
		inc di
		mov dl, 'o'
		mov [di], dl
		inc di
		mov dl, 'm'
		mov [di], dl
		inc di
		mov dl, 0h
		mov [di], dl
		inc di
		mov dl, end_of_line
		mov [di], dl
		pop dx
		pop es
		pop di
		pop si
		call FREE_MEMORY
		cmp error_free_mem, 0
		jne exit_
		push ds
		pop es
		lea dx, name_file		;в dx имя файла с кодом 0 на конце
		lea bx, parameters		;es:bx на блок параметров запуска
		mov save_ss, ss
		mov save_sp, sp
		mov ax, 4b00h			
		int 21h
		mov ss, save_ss
		mov sp, save_sp
		jc error_load
		jmp not_error_load
error_load:
		lea dx, file_not_exist
		call WRITE
		lea dx, name_file
		call WRITE
		jmp exit_
not_error_load:
		call EXIT_PROGRAMM
exit_:
		mov ah, 4Ch
		int 21h
MAIN ENDP
;----------------------------------------------
end_of_programm:
;----------------------------------------------
end MAIN
		  
