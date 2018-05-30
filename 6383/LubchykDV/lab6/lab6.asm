AStack SEGMENT STACK
	DW 12 DUP(?)
AStack ENDS

DATA SEGMENT
param	dw	7	dup(?)
filepath	db	50	dup(0)
save_ss	dw	?
save_sp	dw	?
s_mem_no_free	db	'ERROR: memory not free.','$'
s_load_error	db	'ERROR: Lab2 not load.','$'
nbuffer	db	'000000','$'
sreson1	db	'CTRL+C','$'
sreson2	db	'Device error','$'
sreson3	db	'31h','$'
sreson4	db	'Normal completion','$'
DATA ENDS

CODE SEGMENT
	ASSUME CS:CODE,DS:DATA,SS:AStack
TETR_TO_HEX	PROC	near
	and	AL,0Fh
	cmp	AL,09
	jbe	NEXT
	add	AL,07
NEXT:
	add	AL,30h

	ret
TETR_TO_HEX ENDP

BYTE_TO_HEX	PROC	near
	push	CX
	mov	AH,AL
	call TETR_TO_HEX
	xchg	AL,AH
	mov	CL,4

	shr	AL,CL
	call	TETR_TO_HEX
	pop	CX

	ret
BYTE_TO_HEX	ENDP

WRD_TO_HEX PROC near
	push	BX
	mov	BH,AH
	call	BYTE_TO_HEX
	mov [DI],AH
	dec DI
	mov	[DI],AL
	dec	DI
	mov	AL,BH
	call	BYTE_TO_HEX
	mov	[DI],AH
	dec	DI
	mov	[DI],AL
	pop	BX

	ret
WRD_TO_HEX ENDP

PRINT_HEX PROC	near
	push DI
	push AX
	lea DI,NBUFFER
	mov word ptr [DI],0
	inc	DI
	mov word ptr [DI],0
	inc DI
	mov word ptr [DI],0
	inc	DI
	mov word ptr [DI],0
	inc	DI
	mov word ptr [DI],0
	lea DI,NBUFFER
	add	DI,4
	mov [DI],WORD PTR '$'		
	dec DI
	call	WRD_TO_HEX
	call	PRINT
	pop AX
	pop DI
	ret
PRINT_HEX ENDP

print	proc
	push ax
  mov ah,9
  xchg dx,di
  int 21h
  xchg dx,di
  pop ax

  ret
print	endp

print_symb	proc
	push ax
	mov	ah,02h
	int	21h
	pop	ax

	ret
print_symb	endp

freemem	proc
	push	bx
	push	ax
	push	cx

	lea	bx,end_code
	mov	cl,04h
	add	bx,5FFFh
	shr	bx,cl					; деление на 16
	mov ah,4Ah
	int	21h

	jnc	free
	lea di,s_mem_no_free
	call PRINT

	jmp EXIT

free:
	pop	cx
	pop	ax
	pop	bx

	ret
freemem	endp

path	proc
	push	es
	push	bx
	push	dx
	push	di

	mov es,es:[2Ch]
	xor bx,bx
  env:
	mov dx,es:[bx]
	cmp dx,0100h
	jz fpath
	cmp dh,00h
	jnz next_env
	inc bx
	jmp env
  next_env:
	mov dl,dh
	xor dh,dh
	inc	bx
	jmp	env
  fpath:
	add bx,3
	xor dx,dx
	lea di,filepath
  path_l:
	mov dl,es:[bx]
	cmp dl,00h
	jz end_get_path
	mov	[di],dl
	inc di
	inc bx
	jmp path_l
  end_get_path:	
	sub di,5 
	mov	[di],word ptr '2'
	inc	di
	mov	[di],word ptr '.'
	inc	di
	mov	[di],word ptr 'c'
	inc	di
	mov	[di],word ptr 'o'
	inc	di
	mov	[di],word ptr 'm'
	inc	di
	mov [di],word ptr 0
	pop	di
	pop	bx
	pop	dx
	pop	es

	ret
path	endp

reson proc
	mov ah, 4dh
	int 21h
	cmp ah, 1
	jnz	reson2
	lea di,sreson1
	call print
	jmp exit_reson

  reson2:
	cmp ah, 2
	jnz	reson3
	lea di,sreson2
	call print
	jmp exit_reson

  reson3:
	cmp ah, 3
	jnz	reson4
	lea di,sreson3
	call print
	jmp exit_reson

  reson4:
	lea di,sreson4
	call print
 	mov	dl,':'
 	call print_symb
	xor ah,ah
	call print_hex
	jmp exit_reson
  exit_reson:
	ret
reson endp

MAIN	PROC	FAR

	push DS
	xor AX,AX
	push AX
	mov AX,DATA
	mov	DS,AX

	call freemem
	lea	bx,param
	call path
	lea	dx,filepath
	mov	ax,ds
	mov	es,ax
	xor ax,ax
	mov save_sp,sp
	mov save_ss,ss
	mov ax,4b00h
	int	21h
	mov sp,save_sp
	mov	ss,save_ss
  jnc nlerr
	lea	di,s_load_error
	call print
  jmp exit
  nlerr:
 	mov	dl,0ah
 	call print_symb
	call reson
EXIT:
	xor	AL,AL
	mov	AH,4Ch
	int	21H

MAIN  ENDP


DW 20 DUP(?)
END_CODE:
CODE ENDS
END MAIN
