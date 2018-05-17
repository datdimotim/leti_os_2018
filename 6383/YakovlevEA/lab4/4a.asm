ASSUME CS:CODE, DS:DATA, SS:SSTACK
;----------------------------------------------------------------------
CODE SEGMENT
;----------------------------------------------------------------------
DATA SEGMENT
	resNotSet db "Resident didnt loaded now!", 0dh, 0ah, '$'
	resUnload db "Resident unloaded!", 0dh, 0ah, '$'
	resAlrSet db "Resident already loaded!", 0dh, 0ah, '$'
	resLoad db "Resident loaded!", 0dh, 0ah, '$'
	
	ourPSP dw 0	
DATA ENDS
;----------------------------------------------------------------------
SSTACK SEGMENT STACK 
	DW 64 DUP(?)
SSTACK ENDS
;----------------------------------------------------------------------
ROUT PROC FAR
	jmp start
	PSP_AD1 dw 0  
	PSP_AD2 dw 0
	KEEP_CS dw 0                           
	KEEP_IP dw 0                           
	INTER_ADR dw 1234h       
	COUNTER db 'My current call count: 0000  $' 
	
	;;;;;;;;;;;;;;;;;;;
start:
	
	;;;;;;;;;;;;;;;;;;;;;
	mov  CS:KEEP_AX, AX
mov  CS:KEEP_SS, SS
mov  CS:KEEP_SP, SP

mov  AX, SEG NEW_STACK
mov  SS, AX
mov  SP, offset QWE
	;;;;;;pusha
	push ax      
	push bx
	push cx
	push dx
	push ES	

	;?oaiea iiceoee eo?ni?a
	mov ah, 03h
	mov bh, 00h
	int 10h
	push dx 

	;Onoaiiaea eo?ni?a
	mov ah, 02h
	mov bh, 00h
	mov dx, 0210h
	int 10h

	push si
	push cx
	push ds
	mov ax, SEG COUNTER
	mov ds, ax
	mov si, offset COUNTER
	add si, 1Ah

	mov ah,[si]
	inc ah
	mov [si], ah
	cmp ah, 3Ah
	jne end_count
	mov ah, 30h
	mov [si], ah	

	mov bh, [si - 1] 
	inc bh
	mov [si - 1], bh
	cmp bh, 3Ah                    
	jne end_count
	mov bh, 30h
	mov [si - 1], bh

	mov ch, [si - 2]
	inc ch
	mov [si - 2], ch
	cmp ch, 3Ah
	jne end_count
	mov ch, 30h
	mov [si - 2], ch

	mov dh, [si - 3]
	inc dh
	mov [si - 3], dh
	cmp dh, 3Ah
	jne end_count
	mov dh, 30h
	mov [si - 3],dh
	
end_count:
	;Auaiaei no?ieo ia ye?ai
    	pop ds
    	pop cx
	pop si	

	push es
	push bp	
	mov ax, SEG COUNTER
	mov es, ax
	mov ax, offset COUNTER
	mov bp, ax

	mov ah, 13h
	mov al, 00h
	mov cx, 1Dh
	mov bh, 0
	int 10h
	pop bp
	pop es

	pop dx

	mov ah, 02h
	mov bh, 0h
	int 10h

	pop dx
	pop cx
	pop bx
	pop ax  
   	
	pop  ES
	;popa
	mov  AX, CS:KEEP_SS
mov  SS, AX
mov  SP, CS:KEEP_SP

	mov al, 20h
	out 20h, al
	
mov  AX, CS:KEEP_AX
	
	;;;
	
	iret
	
	
	;;;;;;
	
;;;;;;;;;;;;;;
	KEEP_SP		dw 0h
	KEEP_SS		dw 0h
	KEEP_AX		dw 0h
	
	NEW_STACK	db 20h DUP(0)
	
ROUT ENDP
QWE:
;---------------------------------------------------------------------------
unfree_mem:
;---------------------------------------------------------------------------
IS_LOADED PROC NEAR
	push bx
	push dx
	push es

	mov ah, 35h	;iieo?aiea aaeoi?a
	mov al, 1Ch	; i?a?uaaiee
	int 21h

	mov dx, es:[bx + 11]
	cmp dx, 1234h ; i?iaa?ea ia niaiaaaiea eiaa i?a?uaaiey
	je to_set
	mov al, 00h
	jmp end_set


to_set:
	mov al, 01h
	jmp end_set

end_set:
	pop es
	pop dx
	pop bx

	ret
IS_LOADED ENDP
;--------------------------------------------------------------------------
;--------------------------------------------------------------------------
IS_UNLOADED PROC NEAR
	push es
	
	mov ax, ourPSP
	mov es, ax

	mov bx, 0082h

	mov al, es:[bx]
	cmp al, '/'
	jne end_metka

	mov al, es:[bx+1]
	cmp al, 'u'
	jne end_metka

	mov al, es:[bx+2]
	cmp al, 'n'
	jne end_metka

	mov al, 0001h

end_metka:
	pop es
	ret
IS_UNLOADED ENDP
;------------------------------------------------------------------------
;------------------------------------------------------------------------
RES_LOAD PROC NEAR
	push ax
	push bx
	push dx
	push es

	mov ah, 35h
	mov al, 1Ch
	int 21h

	mov KEEP_IP, bx
	mov KEEP_CS, es

	push ds
	mov dx, offset ROUT
	mov ax, seg ROUT
	mov ds, ax

	mov ah, 25h
	mov al, 1Ch
	int 21h
	pop ds

	mov dx, offset resLoad
	call PRINT

	pop es
	pop dx
	pop bx
	pop ax

	ret
RES_LOAD ENDP
;-------------------------------------------------------------------
;-------------------------------------------------------------------
RES_UNLOAD PROC NEAR
	push ax
	push bx
	push dx
	push es
	
	mov ah, 35h
	mov al, 1Ch
	int 21h

	cli
	push ds            
	mov dx, es:[bx + 9]   
	mov ax, es:[bx + 7]   
		
	mov ds, ax
	mov ah, 25h
	mov al, 1Ch
	int 21h
	pop ds
	sti
	
	mov dx, offset resUnload
	call PRINT
	;/////////////////
	push es
	mov cx,es:[bx+3]
	mov es,cx
	mov ah,49h
	int 21h
	
	pop es
	mov cx,es:[bx+5]
	mov es,cx
	int 21h
	;///////
	pop es
	pop dx
	pop bx
	pop ax
	
	mov ah, 4Ch
	int 21h
	
	ret
RES_UNLOAD ENDP
;----------------------------------------------------------------
;----------------------------------------------------------------
PRINT PROC NEAR
	push ax
	mov ah, 09h
	int	21h
	pop ax
	ret
PRINT ENDP
;---------------------------------------------------------------
;---------------------------------------------------------------
BEGIN PROC FAR
	push ds
	call IS_LOADED
	cmp al, 01h
	je start_prog
	
	mov bx, 02Ch
	mov ax, [bx]
	mov PSP_AD2, ax
	mov PSP_AD1, ds 

start_prog:
	mov dx, ds 

	sub ax, ax    
	xor bx, bx

	mov ax, DATA  
	mov ds, ax    
	
	mov ourPSP, dx 
	xor dx, dx				

	call IS_UNLOADED   
	cmp al, 01h
	je unload_block

	call IS_LOADED   
	cmp al, 01h
	jne not_load_block
	
	mov dx, offset resAlrSet	
	call PRINT
	jmp exit_block

not_load_block:
	call RES_LOAD
	
	mov dx, offset unfree_mem
	mov cl, 04h
	shr dx, cl
	add dx, 1Bh

	mov ax, 3100h
	int 21h
         
unload_block:
	call IS_LOADED
	cmp al, 00h
	je not_set_block
	call RES_UNLOAD
	jmp exit_block

not_set_block:
	mov dx, offset resNotSet
	call PRINT
    jmp exit_block
	
exit_block:
	mov ah, 4Ch
	int 21h

BEGIN ENDP
;-----------------------------------------------------------------------
CODE ENDS
;-----------------------------------------------------------------------
END BEGIN
