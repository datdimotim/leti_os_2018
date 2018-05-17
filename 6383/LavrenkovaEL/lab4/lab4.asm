code segment
	assume cs:code, ds:data, ss:Tstack
start_mem:
	PSP dw 0
	KEEP_CS dw 0
	KEEP_IP dw 0
	Counter dw 0
	Message db 'Interrupt was called        times$'
	
	KEEP_AX dw 0
	KEEP_SS dw 0
	KEEP_SP dw 0
	
	MY_STACK dw 20 DUP(?)
	end_of_my_stack:

push_reg macro
	push 	ax
	push 	bx
	push 	cx
	push 	dx
endm

pop_reg macro
	pop 	dx
	pop 	cx
	pop 	bx
	pop 	ax
endm

GetCurs	proc near
	push 	ax
	push 	bx
	push 	cx
	mov 	ah, 03h
	mov 	bh, 0
	mov 	bl, 7
	int 	10h
	pop 	cx
	pop 	bx
	pop 	ax
	ret
GetCurs	endp
	
SetCurs	proc near
	push 	ax
	push 	bx
	push	cx
	mov 	ah,	02h
	mov 	bh,	0
	mov 	bl, 07
	int 	10h
	pop		cx
	pop 	bx 
	pop 	ax
	ret
SetCurs	endp

wrd_to_dec proc near
    push 	cx
    push 	dx
    mov  	cx, 10
wloop_bd:   
    div 	cx
    or  	dl, 30h
    mov 	[si], dl
    dec 	si
	xor 	dx, dx
    cmp 	ax, 10
    jae 	wloop_bd
    cmp 	al, 00h
    je 		wend_l
    or 		al, 30h
    mov 	[si], al
wend_l:      
    pop 	dx
    pop 	cx
    ret
   wrd_to_dec endp

my_int proc far
	jmp 	body
	Int_Tag dw 1234h
body:
	mov     CS:KEEP_AX, AX														
	mov     CS:KEEP_SS, SS														
	mov     CS:KEEP_SP, SP														
																				
	mov     AX, SEG MY_STACK													
	mov     SS, AX																
	mov     SP, offset end_of_my_stack											
	
	push_reg
	push 	si
	push 	ds
	
	mov 	ax,	seg code
	mov 	ds,	ax
	inc 	cs:Counter
	mov 	si, offset cs:Message
	add 	si, 26
	push	ax
	push	dx
	xor		dx,dx
	mov		ax,Counter
	call	wrd_to_dec
	pop		dx
	pop		ax
	call 	GetCurs
	push 	dx
	dec 	dh
	mov 	dl, 0
	call 	SetCurs
		
	push_reg
	push 	bp
	push 	es
	mov 	ax, seg code
	mov 	es, ax
	mov 	bp, offset es:Message
	
	mov 	cx,	33
	mov		ah, 13h
	mov		al, 01h
	mov		bh, 0
	mov		bl, 07h
	
	call 	GetCurs
	int 	10h

	pop 	es
	pop 	bp
	pop_reg
	pop 	dx
	
	call 	SetCurs
	pop 	ds
	pop 	si
	pop_reg
	
	
	mov     ax, CS:KEEP_SS														
	mov     ss, ax																
	mov     SP, CS:KEEP_SP															
																				
	mov 	al, 20h
	out 	20h, al
	
	mov     ax, CS:KEEP_AX	
	
	iret
my_int endp

end_mem:

old_int_save proc near
	push_reg
	push 	es
	push 	di
	mov		ah, 35h
	mov		al,	1Ch
	int 	21h
	mov 	cs:KEEP_IP, bx
	mov 	cs:KEEP_CS, es
	pop 	di
	pop 	es
	pop_reg
	ret
old_int_save endp

set_new_int proc near
	push_reg
	push 	ds
	mov 	dx, offset my_int
	mov 	ax, seg my_int
	mov 	ds, ax
	mov		ah, 25h
	mov		al, 1Ch
	int 	21h
	pop 	ds
	pop_reg
	ret
set_new_int endp

load_my_int proc near	
	mov     dx, offset end_mem
	mov 	cl, 4
	shr 	dx, cl ;div 16
	inc 	dx
	add     dx, CODE
	sub     dx, PSP
	mov 	ah, 31h
	int 	21h
	ret
load_my_int endp

delete_my_int proc near
	cli
	push_reg
	push 	ds
	push 	es
	push 	di
	mov		ah,35h
	mov		al,1Ch
	int 	21h
	mov 	ax, es:[2]
	mov 	cs:KEEP_CS, ax
	mov 	ax, es:[4]
	mov 	cs:KEEP_IP, ax
	mov 	ax, es:[0]
	mov 	cx, ax
	mov 	es, ax
	mov 	ax, es:[2Ch]
	mov 	es, ax
	xor 	ax, ax
	mov 	ah, 49h
	int 	21h
	mov 	es, cx
	xor 	ax, ax
	mov 	ah, 49h
	int 	21h
	mov 	dx, cs:KEEP_IP
	mov 	ax, cs:KEEP_CS
	mov 	ds, ax
	mov 	ax, 251Ch	
	int 	21h
	pop 	di
	pop 	es
	pop 	ds
	pop_reg
	sti
	ret
delete_my_int endp

;вывод строки
print proc near
    push 	ax
    push 	dx
    mov 	ah, 09h
    int 	21h
    pop 	dx
    pop 	ax
    ret
   print endp

main proc near

	push 	ds
	mov 	ax, seg data
	mov 	ds, ax
	pop 	cs:PSP
	
	mov 	es, cs:PSP
	mov 	al, es:[80h]
	cmp 	al, 4
	jne 	Empty_Tail

	mov 	al, byte PTR es:[82h]	
	cmp 	al, '/'
	jne		Empty_Tail
	mov 	al, byte PTR es:[83h]
	cmp 	al, 'u'
	jne		Empty_Tail
	mov 	al, byte PTR es:[84h]
	cmp 	al, 'n'
	jne		Empty_Tail
		
	mov 	IsDelete, 1

Empty_Tail:
	mov		ah, 35h
	mov		al,	1Ch
	int 	21h
	mov 	ax, es:[bx+3]
	cmp 	ax, 1234h
	je 		already_inst
	
	cmp 	IsDelete, 1
	je 		not_inst
	
	call 	old_int_save
	call 	set_new_int
	call 	load_my_int
	
	jmp 	exit
	
already_inst:
	cmp 	IsDelete, 1
	je 		delete_my_int_main_m
	mov		dx, offset Inst_Mess
	call	print	
	jmp 	exit
	
delete_my_int_main_m:
	call 	delete_my_int
	jmp 	exit
	
not_inst:
	mov		dx, offset Not_Inst_Mess
	call	print	
	jmp		exit
	
exit:
	xor 	al, al
	mov 	ah, 4Ch
	int 	21h
	ret
main endp

code ends

data segment
	IsDelete 		db 0
	Inst_Mess		db 'Interrupt is already installed!', 10, 13, '$'
	Not_Inst_Mess 	db 'Interrupt is not installed!', 10, 13, '$'
data ends

Tstack segment stack
	dw 128 dup (?)
Tstack ends


end main