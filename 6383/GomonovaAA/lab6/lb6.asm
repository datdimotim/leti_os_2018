.model small
.data
st_docher_uspeh db 13, 10, "Process was end successfully, code: $"
st_file_otst db 13, 10, "ERROR: No file", 13, 10, "$"
st_docher_ctrlc db 13, 10, "Process was end with ctrl+c$"
psp dw ?
filename db 50 dup(0)
eol db "$"
param dw 7 dup(?)
vrem_ss dw ?
vrem_sp dw ?
fmemerr db 0
.stack 100h
.code
TETR_TO_HEX   PROC  near
	and      AL,0Fh
	cmp      AL,09
	jbe      NEXT
	add      AL,07
	NEXT:      add      AL,30h
	ret
TETR_TO_HEX   ENDP

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

WRITE PROC
	push ax
	mov ah, 09h
	int 21h
	pop ax
	ret
WRITE ENDP
freeMem PROC
	mov bx, es			;
	neg bx				;
	
	mov ax, SS			;
	add bx, ax
	
	add bx, 16			; bx = (@stack-@PSP) + size_of_stack/4
	
	mov ah, 4Ah ; освобождение памяти
	int 21h
	jc err
	jmp noterr
	err:
		mov fmemerr, 1
	noterr:
		ret
freeMem ENDP

exitProg PROC
	mov ah, 4Dh
	int 21h
	cmp ah, 1
	je errchild
	lea bx, st_docher_uspeh
	mov [bx], ax
	lea dx, st_docher_uspeh
	
	call WRITE
	call byte_to_Hex
	push ax
	mov dl, ' '
	mov ah, 2h
	int 21h
	pop ax
	push ax
	mov dl, al
	mov ah, 2h
	int 21h
	pop ax
	mov dl, ah
	mov ah, 2h
	int 21h
	jmp exget
	errchild:
		lea dx, st_docher_ctrlc
		call WRITE
	exget:
		ret
exitProg ENDP
;----------------------------------------------
Main proc
	mov ax, @data
	mov ds, ax
	push si
	push di
	push es
	push dx
	mov es, es:[2Ch]
	xor si, si
	lea di, filename
	env_char: 
		cmp byte ptr es:[si], 00h
		je env_crlf
		inc SI
		jmp env_next
	env_crlf:   
		inc si
	env_next:       
		cmp word ptr es:[si], 0000h
		jne env_char
		add si, 4         
	abs_char:
		cmp byte ptr es:[si], 00h
		je vot
		mov dl, es:[si]
		mov [di], dl
		inc si
		inc di
		jmp abs_char        
	vot:
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
		mov dl, eol
		mov [di], dl
		pop dx
		pop es
		pop di
		pop si
		call freeMem
		cmp fmemerr, 0
		jne ex
		push ds
		pop es
		lea dx, filename 
		lea bx, param 
		mov vrem_ss, ss
		mov vrem_sp, sp
		mov ax, 4b00h
		int 21h
		mov ss, vrem_ss
		mov sp, vrem_sp
		jc erld
		jmp noterld
	erld:
		lea dx, st_file_otst
		call WRITE
		lea dx, filename
		call WRITE
		jmp ex
	noterld:
		call exitProg
	ex:
		mov ah, 4Ch
		int 21h
main ENDP
PROGEND PROC
PROGEND ENDP
end main
		  
