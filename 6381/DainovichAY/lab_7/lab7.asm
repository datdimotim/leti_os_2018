  data segment
    PSP			dw 	?
    path 		db 100 dup (?)
    dta 		db 43 dup (?)	
    overlay 	dw 0
    epb 		dw ?
    _ss 		dw ?
    _sp 		dw ?
    Count 		db 0
    Way 		db 'Way: $'
    Adress 		db 'Overlay segment address: $'
    Error1 		db 'Error! File not found.$'
    Error2 		db 'Error! Path not found.$'
    file_ov1 	db 'ovr1.com',0
    file_ov2 	db 'ovr2.com',0
    NewLine 	db 13, 10, '$'   
  data ends
  
  stack segment
    dw 128 dup(0)
  stack ends
  
  code segment 
    assume ds:data, ss:stack, cs:code, es:nothing
    .386 ;для Extended регистров


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
   
endl proc near
    push 	ax
    push 	dx
    mov		dx, offset NewLine
    mov 	ah, 09h
    int 	21h
    pop 	dx
    pop 	ax
    ret
   endl endp

start:
    
	mov 	ax, data
	mov 	ds, ax
	mov 	PSP, es
	
	mov		es, es:[002Ch]
	xor		bx, bx

;мотаем до пути
next:
	mov 	dl, byte PTR es:[bx] 
	cmp 	dl, 0h
	je 		first_0
	inc 	bx
	jmp 	next
first_0:
	inc 	bx
	mov 	dl, byte PTR es:[bx] 
	cmp 	dl, 0h
	je 		second_0
	jmp 	next

second_0:		
	add		bx,3	
	
;переписываем путь	
	push	si
	mov		si, offset path
next1:	
	mov 	dl, byte PTR es:[bx]
	mov		[si], dl
	inc		si
	inc		bx
	cmp		dl, 0
	jne		next1
	
;удаляем имя файла
next2:
	mov		al, [si]
	cmp		al, '\'
	je		next3
	dec		si
	jmp		next2
	
next3:	
	inc		si
;дописываем имя файла 
	push	di
	mov		di, offset file_ov1
next4:
	mov		ah, [di]
	mov		[si], ah
	inc		si
	inc		di
	cmp		ah, 0
	jne		next4
	mov 	ah,'$'
	mov 	[si],ah
	pop		di
	
	call 	endl
	mov	 	dx, offset Way
	call 	print
	mov 	dx, offset path
	call 	print
	call 	endl
	
	mov 	ax, PSP
	mov 	es, ax
	mov 	bx, offset last_byte
	shr 	bx, 4 
	add 	bx, 50
	mov 	ah, 4Ah
	int 	21h 
	
	mov 	dx, offset dta 
	mov 	ah, 1Ah
	int 	21h ;устанавливаем адрес для DTA
	
Again:	
	mov 	dx, offset path
	mov 	ah, 4Eh
	mov 	cx, 0h
	int 	21h 
	
jnc no_err 
	cmp 	ax, 2 
	jne 	err1 
	mov 	dx, offset Error1
	call 	print
	call	endl
	jmp	 	exit

err1:	
	cmp 	ax, 3 
	jne 	err2
	mov 	dx, offset Error2
	call 	print
	call	endl
	jmp 	exit
	
err2:	
	cmp 	ax, 18 
	jne 	exit
	mov 	dx, offset Error1
	call 	print
	call	endl
	jmp 	exit		
		
no_err: 		
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
	
	mov 	dx, offset Adress
	call 	print
;!!!Вызов оверлея
	push 	ds	
	call 	dword ptr overlay
	call 	endl
	pop 	ds

;освобождение памяти	
	mov 	ax, epb
	mov 	es, ax
	mov 	ah, 49h
	int 	21h	
	
	mov 	al, Count
	cmp 	al, 1
	je 		exit
	call 	endl
	mov 	di, 0
	
next5:
	mov		al, [si]
	cmp		al, '\'
	je		next6
	dec		si
	jmp		next5
	
next6:	
	inc		si	
;дописываем имя файла 
	push	di
	mov		di, offset file_ov2
next7:
	mov		ah, [di]
	mov		[si], ah
	inc		si
	inc		di
	cmp		ah, 0
	jne		next7
	mov 	ah,'$'
	mov 	[si],ah
	pop		di
	pop 	si	
	
	mov 	Count, 1
	mov 	dx, offset Way
	call 	print
	mov	 	dx, offset path
	call 	print
	call	endl
	
	jmp 	Again
	
;Выход в DOS

exit:
	xor 	al, al
	mov 	ah, 4Ch
	int 	21h
last_byte:	
  code ends
    end start
