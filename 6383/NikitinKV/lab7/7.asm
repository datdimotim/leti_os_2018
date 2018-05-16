DATA SEGMENT
	PSP			dw 	?
	path 		db 100 dup (?)
	dta 		db 43 dup (?)	
	overlay 	dw 0
	epb 		dw ?
	_ss 		dw ?
	_sp 		dw ?
	Count 		db 0
	OVL_FOUND 	db 'Ovl is here! $'
	ADRESS 		db 'Overlay segment address: $'
	ERR1 		db 'Error! File not found.$'
	ERR2 		db 'Error! Path not found.$'
	OVL1 	    db 'ovl1.ovl',0
	OVL2 	db 'ovl2.ovl',0
	EMPTYLINE 	db 13, 10, '$'   
DATA ENDS

STACK SEGMENT STACK
	DW 100 DUP (0)
STACK ENDS

CODE SEGMENT 
ASSUME DS:DATA, SS:STACK, CS:CODE, ES:NOTHING
.386

PRINT proc near
push 	ax
push 	dx
mov 	ah, 09h
int 	21h
pop 	dx
pop 	ax
ret
PRINT endp

ENDL proc near
push 	ax
push 	dx
mov		dx, offset EMPTYLINE
mov 	ah, 09h
int 	21h
pop 	dx
pop 	ax
ret
ENDL endp

JOBS:
mov 	ax, data
mov 	ds, ax
mov 	PSP, es
mov		es, es:[002Ch]
xor		bx, bx

STEP:
mov 	dl, byte PTR es:[bx] 
cmp 	dl, 0h
je 		FIRST_
inc 	bx
jmp 	STEP
FIRST_:
inc 	bx
mov 	dl, byte PTR es:[bx] 
cmp 	dl, 0h
je 		SECOND_
jmp 	STEP

SECOND_:		
add		bx,3	

push	si
mov		si, offset path
STEP1:	
mov 	dl, byte PTR es:[bx]
mov		[si], dl
inc		si
inc		bx
cmp		dl, 0
jne		STEP1

STEP2:
mov		al, [si]
cmp		al, '\'
je		STEP3
dec		si
jmp		STEP2

STEP3:	
inc		si 
push	di
mov		di, offset OVL1
STEP4:
mov		ah, [di]
mov		[si], ah
inc		si
inc		di
cmp		ah, 0
jne		STEP4
mov 	ah,'$'
mov 	[si],ah
pop		di

call 	ENDL
mov	 	dx, offset OVL_FOUND
call 	PRINT
call 	ENDL

mov 	ax, PSP
mov 	es, ax
mov 	bx, offset last_byte
shr 	bx, 4 
add 	bx, 50
mov 	ah, 4Ah
int 	21h 

mov 	dx, offset dta 
mov 	ah, 1Ah
int 	21h 

CYCLE:	
mov 	dx, offset path
mov 	ah, 4Eh
mov 	cx, 0h
int 	21h 

jnc NO_ERROR
cmp 	ax, 2 
jne 	ERROR1 
mov 	dx, offset ERR1
call 	PRINT
call	ENDL
jmp	 	TODOS

ERROR1:	
cmp 	ax, 3 
jne 	ERROR2
mov 	dx, offset ERR2
call 	PRINT
call	ENDL
jmp 	TODOS

ERROR2:	
cmp 	ax, 18 
jne 	TODOS
mov 	dx, offset ERR1
call 	PRINT
call	ENDL
jmp 	TODOS		
	
NO_ERROR: 		
mov 	ebx, dword ptr [ offset dta + 1Ah ] 
shr 	ebx, 4 
inc 	ebx 

mov 	ah, 48h 
int 	21h
mov 	epb, ax 
mov 	ax, ds
mov 	es, ax 
mov 	bx, offset epb
mov 	dx, offset path
mov 	_sp, sp
mov 	_ss, ss

mov 	ax, 4B03h
int 	21h			

mov 	ax, data
mov 	ds, ax
mov 	ss, _ss
mov 	sp, _sp

mov 	dx, offset ADRESS
call 	PRINT
push 	ds	
call 	dword ptr overlay
call 	ENDL
pop 	ds

mov 	ax, epb
mov 	es, ax
mov 	ah, 49h
int 	21h	

mov 	al, Count
cmp 	al, 1
je 		TODOS
call 	ENDL
mov 	di, 0

STEP5:
mov		al, [si]
cmp		al, '\'
je		STEP6
dec		si
jmp		STEP5

STEP6:	
inc		si	
push	di
mov		di, offset OVL2
STEP7:
mov		ah, [di]
mov		[si], ah
inc		si
inc		di
cmp		ah, 0
jne		STEP7
mov 	ah,'$'
mov 	[si],ah
pop		di
pop 	si	
mov 	Count, 1
mov 	dx, offset OVL_FOUND

call 	PRINT
call	ENDL

jmp 	CYCLE


TODOS:
xor 	al, al
mov 	ah, 4Ch
int 	21h
last_byte:	
CODE ENDS
END JOBS