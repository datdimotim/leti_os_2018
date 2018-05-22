code segment
	assume cs:code, ds:data, ss:Tstack
	
start_mem:
	PSP dw 0
	KEEP_CS dw 0
	KEEP_IP dw 0
	Int9 dd 0
    Scancode_1 db 2
    Scancode_2 db 3
    Scancode_3 db 4
    Scancode_4 db 5
    Scancode_5 db 6
    Scancode_6 db 7
    Scancode_7 db 8
    Scancode_8 db 9
    Scancode_9 db 10
    Scancode_0 db 11
	
	KEEP_AX dw 0
	KEEP_SS dw 0
	KEEP_SP dw 0
	MY_STACK dw 100 DUP(?)
	end_of_my_stack:

push_main macro
	mov     CS:KEEP_AX, AX														
	mov     CS:KEEP_SS, SS														
	mov     CS:KEEP_SP, SP														
																				
	mov     AX, SEG MY_STACK													
	mov     SS, AX																
	mov     SP, offset end_of_my_stack											

	push 	ax
	push 	bx
	push 	cx
	push 	dx
endm

pop_main macro
	pop 	dx
	pop 	cx
	pop 	bx
	pop 	ax
	
	mov     ax, CS:KEEP_SS														
	mov     ss, ax																
	mov     SP, CS:KEEP_SP																																					
	mov     ax, CS:KEEP_AX	

endm

my_int proc far
	jmp 	body
	Int_Tag dw 1234h
body:
	push_main
	in		al, 60h
	
	mov		ch, 00h
	
	cmp		al, cs:[Scancode_1]
	jne		next1
	mov		cl, '!'
	jmp		do_req
next1:	
	cmp		al, cs:[Scancode_2]
	jne		next2
	mov		cl, '@'
	jmp		do_req
next2:	
	cmp		al, cs:[Scancode_3]
	jne		next3
	mov		cl, '#'
	jmp		do_req
next3:	
	cmp		al, cs:[Scancode_4]
	jne		next4
	mov		cl, '$'
	jmp		do_req
next4:	
	cmp		al, cs:[Scancode_5]
	jne		next5
	mov		cl, '%'
	jmp		do_req
next5:	
	cmp		al, cs:[Scancode_6]
	jne		next6
	mov		cl, '^'
	jmp		do_req
next6:
	cmp		al, cs:[Scancode_7]
	jne		next7
	mov		cl, '&'
	jmp		do_req
next7:	
	cmp		al, cs:[Scancode_8]
	jne		next8
	mov		cl, '*'
	jmp		do_req
next8:	
	cmp		al, cs:[Scancode_9]
	jne		next9
	mov		cl, '('
	jmp		do_req
next9:
	cmp		al, cs:[Scancode_0]
	jne		int9do
	mov		cl, ')'
	jmp		do_req
	
int9do:
	pop_main
	jmp		cs:[Int9]

do_req:
	in 		al, 61h
	mov 	ah, al
	or 		al, 80h
	out 	61h, al
	xchg 	ah, al
	out 	61H, al
	mov 	al, 20h
	out 	20h, al
	
	mov 	ah, 05h
	int 	16h 
	or 		al, al 
	jnz 	skip 
	jmp 	to_quit	
;Для очистки буфера надо просто установить значение
;ячейки 0040:001A равным значению ячейки 0040:001C.
skip:	
	push 	es
	push 	si
	mov 	ax, 0040h
	mov 	es, ax
	mov 	si, 001ah
	mov 	ax, es:[si] 
	mov 	si, 001ch
	mov 	es:[si], ax	
	pop		si
	pop		es

to_quit:	
	pop_main
	mov 	al, 20h
	out 	20h, al
	iret
my_int endp

end_mem:

old_int_save proc near
	push_main
	push 	es
	push 	di
	mov		ah, 35h
	mov		al,	09h
	int 	21h
	mov 	cs:KEEP_IP, bx
	mov 	cs:KEEP_CS, es
	mov word ptr Int9+2, es
	mov word ptr Int9, bx
	pop 	di
	pop 	es
	pop_main
	ret
old_int_save endp

set_new_int proc near
	push_main
	push 	ds
	mov 	dx, offset my_int
	mov 	ax, seg my_int
	mov 	ds, ax
	mov		ah, 25h
	mov		al, 09h
	int 	21h
	pop 	ds
	pop_main
	ret
set_new_int endp

load_my_int proc near	
	mov 	dx, seg code	
	add 	dx, (end_mem-start_mem)
	mov 	cl, 4
	shr 	dx, cl ;div 16
	inc 	dx
	mov 	ah, 31h
	int 	21h
	ret
load_my_int endp

delete_my_int proc near
	cli
	push_main
	push 	ds
	push 	es
	push 	di
	mov		ah,35h
	mov		al,09h
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
	mov		ah, 25h
	mov		al, 09h
	int 	21h
	pop 	di
	pop 	es
	pop 	ds
	pop_main
	sti
	ret
delete_my_int endp

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
	mov		al,	09h
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
	mov 	ah, 09h
    int 	21h
	jmp 	exit
	
delete_my_int_main_m:
	call 	delete_my_int
	jmp 	exit
	
not_inst:
	mov		dx, offset Not_Inst_Mess
	mov 	ah, 09h
    int 	21h
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
