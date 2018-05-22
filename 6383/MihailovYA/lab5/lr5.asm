.Model small
.DATA
string db "Message$"
strld db 13, 10, "Resident loaded$", 13, 10
struld db 13, 10, "Resident unloaded$"
strald db 13, 10, "Resident is already loaded$"
PSP dw ?
isUd db ?
isloaded db ?
sg dw ?
num db 0

signat db "12345"

KEEP_CS DW ? ; ��� �������� ��������
KEEP_IP DW ? ; � �������� ������� ����������
.STACK 400h
.CODE
resID dw 0ff00h
;-----------------------------------
ROUT PROC FAR
	mov cs:[KEEP_AX],ax
	mov cs:[KEEP_SS],ss
	mov cs:[KEEP_SP],sp

	cli
	
	mov ax,cs:[M_S]
	mov ss,ax
	mov sp,cs:[M_P]
	
	sti
	
	mov cs:[typeKey], 0
	in al, 60h
	cmp al, 10h  ;\\ 
	jl oldint9 ;   q w e r t y u i o p 
	cmp al, 19h ;//
	jle do_req1
	inc cs:[typeKey]
	cmp al, 49 ; N
	je do_req
	inc cs:[typeKey]
	cmp al, 14 ; backspace
	je do_req
	do_req1:
		push ax
		push es
		xor ax, ax
		mov es, ax
		mov al, es:[417h]
		pop es
		and al, 1000b ; �����/������ sft ����� ��� ������� cps lock?
		pop ax
		jnz do_req
	oldint9:
		cli
		
		mov ax,cs:[KEEP_SS]
		mov ss,ax
		mov sp,cs:[KEEP_SP]
		
		sti
		
		mov ax,cs:[KEEP_AX]
		
		jmp dword ptr cs:[Int9_vect];
	do_req: 
		push ax
		;��������� ��� ��������� ��� ��������� ����������� ����������
		in al, 61h   ;����� �������� ����� ���������� �����������
		mov ah, al     ; ��������� ���
		or al, 80h    ;���������� ��� ���������� ��� ����������
		out 61h, al    ; � ������� ��� � ����������� ����
		xchg ah, al    ;������� �������� �������� �����
		out 61h, al    ;� �������� ��� �������
		mov al, 20h     ;������� ������ "����� ����������"
		out 20h, al     ; ����������� ���������� 8259
	l16h:
		pop ax
		mov ah, 05h  ; ��� �������
		cmp cs:[typeKey], 0
		je key1
		cmp cs:[typeKey], 1
		je key2
		cmp cs:[typeKey], 2
		je key3
	key1:
		push ax
		push es
		xor ax, ax
		mov es, ax
		mov al, es:[417h]
		pop es
		and al, 1000b ; �����/������ sft ����� ��� ������� cps lock?
		jnz isalt
		pop ax
		jmp dword ptr cs:[Int9_vect];
	isalt:
		pop ax
		mov cl, 0B0h
		add cl, al
		sub cl, 0Fh ;���� ����� q-p � ����� alt ������� ������� �������������
		jmp writeKey 
	key2:
		push ax
		push es
		xor ax, ax
		mov es, ax
		mov al, es:[417h]
		pop es
		and al, 01000011b ; �����/������ sft ����� ��� ������� cps lock?
		jnz big
		pop ax
		mov cl, 'n'
		jmp writeKey
	big:
		pop ax
		mov cl, 'N' ; ����� ������ � ����� ����������
		jmp writeKey
	key3:
		mov cl, 'D'
		jmp notcls
	writeKey:
		mov ch,00h ; 
		int 16h ;
		or al, al ; �������� ������������ ������
		jnz clsbuf ; ���� ���������� ���� skip
		jmp notcls
		; �������� ������
	clsbuf:  ; �������� ����� � ���������
		push es
		CLI	;��������� ����������
		xor ax, ax
		MOV es, ax	
		MOV al, es:[41AH];\\	
		MOV es:[41CH], al;- head=tail 	
		STI	;��������� ����������
		pop es
	notcls:
		cli
		
		mov ax,cs:[KEEP_SS]
		mov ss,ax
		mov sp,cs:[KEEP_SP]
		
		sti
		
		IRET		
		Int9_vect dd ?		
		typeKey db 0 ; 0 if q-p , 1 if n , 2 if del
		
		KEEP_SS dw 0
		KEEP_SP dw 0
		KEEP_AX dw 0
		M_P dw 0
		M_S dw 0
ROUT  ENDP  
;-----------------------------------
IsUnload PROC
	;Tail of command line
	push es
	push ax
	mov ax, cs:[PSP]
	mov es, ax
	mov cl, es:[80h]
	mov dl, cl
	xor ch, ch
	test cl, cl	
	jz ex2
	xor di, di
	readChar:
		inc di
		mov al, es:[81h+di]
		inc di
		cmp al, '/'
		jne ex2
		mov al, es:[81h+di]
		inc di
		cmp al, 'u'
		jne ex2
		mov al, es:[81h+di]
		cmp al, 'n'
		jne ex2
		mov isUd, 1 ; if is unloading resident
	ex2:
		pop ax
		pop es
		ret
IsUnload ENDP
;-----------------------------------
IsAlreadyLoad PROC
	push es
	mov ax, 3509h ; ������� ��������� �������
	int 21h
	mov dx, es:[bx-2]
	pop es
	cmp dx, resId
	je ad
	jmp exd
	ad:
		mov isloaded, 1
	exd:
		ret
IsAlreadyLoad ENDP
;-----------------------------------
UnLoad proc
	push es
	mov ax, sg
	mov es, ax
	mov DX, word ptr es:Int9_vect
	mov ax, word ptr es:Int9_vect+2
	mov KEEP_IP, dx
	mov KEEP_CS, ax
	pop es
	CLI
	push ds
	mov dx, KEEP_IP
	mov ax, KEEP_CS
	mov ds, ax
	mov ah, 25h
	mov al, 09h
	int 21h          
	pop ds
	STI
		ret
Unload endp
;-----------------------------------
MakeResident proc
	lea dx, strld
	call WRITE
	
	
	mov dx, ss
	sub dx, CS:[PSP]
	mov cl,4
	shl dx, cl		
	add dx, 410h	
	shr dx, cl	
	
	mov  CS:[M_S], SS
	mov  CS:[M_P], sp
	mov Ax, 3100h
	int 21h
	ret
MakeResident Endp
;-----------------------------------
WRITE PROC
	push ax
	mov ah, 09h
	int 21h
	pop ax
	ret
WRITE ENDP
;-----------------------------------
Main PROC  FAR 
	mov ax, ds
	mov ax, @DATA		  
	mov ds, ax
	mov ax, es
	mov cs:[PSP], ax

	call isAlreadyLoad
	
	call isUnload
	
	cmp isloaded, 1
	je a
	mov ax, 3509h ; ������� ��������� �������
	int 21h
	mov KEEP_IP, bx  ; ����������� ��������
	mov KEEP_CS, es  ; � �������� ������� ����������
	mov word ptr int9_vect+2, es
	mov word ptr int9_vect, bx

	push ds
	mov dx, OFFSET ROUT ; �������� ��� ��������� � DX
	mov ax, SEG ROUT    ; ������� ���������
	mov ds, ax          ; �������� � DS
	mov ax, 2509h         ; ������� ��������� �������
	int 21H             ; ������ ����������
	pop ds
	call MakeResident
	a:
		cmp isUd, 1
		jne b
		call UnLoad
		lea dx, struld
		call WRITE
		mov ah, 4ch                        
		int 21h   
	b:
		lea dx, strald
		call WRITE
		mov ah, 4ch                        
		int 21h                             
Main ENDP

TEMP PROC
TEMP ENDP

END Main
		  
