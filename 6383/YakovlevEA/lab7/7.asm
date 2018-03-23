;______________________________________________________________
OVERLAY_SEGMENT SEGMENT
OVERLAY_SEGMENT ENDS
;______________________________________________________________
;______________________________________________________________
DATA SEGMENT
	SEGADD db 0DH, 0AH, "Segment address of overlay: ", '$'
	NO_FILE db 0DH, 0AH, "File not found. ", '$'
	NO_MEMORY db 0DH, 0AH, "Low memory.", '$'
	FILE_NAME DB 50 dup(0)
	parameters	dw seg OVERLAY_SEGMENT
					dw seg OVERLAY_SEGMENT
	DTA db 43 dup(?)
	TEMP_SS dw ?
	TEMP_SP dw ?
	entry dd 0
	amount db 5
	NOT_MEMORY db 0
DATA ENDS
;______________________________________________________________
;______________________________________________________________
SStack SEGMENT STACK
	DW 64 DUP(?)
SStack ENDS
;______________________________________________________________
;______________________________________________________________
CODE SEGMENT
	ASSUME CS:CODE, DS:DATA, SS:SStack
;______________________________________________________________
writeString PROC near
	push ax
	mov ah, 09h
	int 21h
	pop ax
	ret
writeString ENDP
;______________________________________________________________
;______________________________________________________________
fileNameTest PROC
sub di, 5
	mov dl, 'O'
	mov [di], dl
	inc di
	mov dl, 'V'
	mov [di], dl
	inc di
	mov dl, 'E'
	mov [di], dl
	inc di
	mov dl, 'R'
	mov [di], dl
	inc di
	mov dl, 'L'
	mov [di], dl
	inc di
	mov dl, 'A'
	mov [di], dl
	inc di
	mov dl, 'Y'
	mov [di], dl
	inc di
	mov dl, '.'
	mov [di], dl
	inc di
	mov dl, 'o'
	mov [di], dl
	inc di
	mov dl, 'v'
	mov [di], dl
	inc di
	mov dl, 'l'
	mov [di], dl
	inc di
	mov dl, 0h
	mov [di], dl
	inc di
	mov dl, '$'
	mov [di], dl
	ret
fileNameTest ENDP
;______________________________________________________________
;______________________________________________________________
clearMem PROC
	mov bx, OVERLAY_SEGMENT
	mov ax, es
	sub bx, ax
	mov cl, 4
	shr bx, cl
	inc bx
	mov ah, 4Ah
	int 21h
	ret
clearMem ENDP
;______________________________________________________________
;______________________________________________________________
memForDTA PROC
	mov dx, offset DTA
	mov ah, 1Ah
	int 21h
	mov cx, 0
	mov dx, offset FILE_NAME
	mov ah, 4Eh
	int 21h
	mov si, offset DTA
	mov dx, word ptr[si+1Ch]
	mov ax, word ptr[si+1Ah]
	mov bx, 10h
	div bx
	mov bx, ax
	inc bx
	mov ah, 48h
	int 21h
	ret
memForDTA ENDP
;______________________________________________________________
;______________________________________________________________
downloadProgram PROC
	push ds
	mov ax, ds
	mov es, ax
	mov bx, offset parameters
	lea dx, FILE_NAME
	call writeString
	mov ax, 4b03h
	int 21h
	pop ds
	ret
downloadProgram ENDP
;______________________________________________________________
;______________________________________________________________
clearOverlayMem PROC
	push es
	mov ah, 49h
	mov ax, parameters
	mov es, ax
	pop es
	ret
clearOverlayMem ENDP
;______________________________________________________________
;______________________________________________________________
fileNotFound PROC
	lea dx, NO_FILE
	call writeString
	lea dx, FILE_NAME
	call writeString
	ret
fileNotFound ENDP
;______________________________________________________________
;______________________________________________________________
doOverlay PROC
	push ds
	mov TEMP_SS, ss
	mov TEMP_SP, sp
	call DWORD PTR entry
	mov ss, TEMP_SS
	mov sp, TEMP_SP
	pop ds
	ret
doOverlay ENDP
;______________________________________________________________
;______________________________________________________________
Main PROC
	mov ax, DATA
	mov ds, ax
	mov es, es:[2Ch]
	
	sub si, si
	mov di, offset FILE_NAME
way1: 
	cmp byte ptr es:[si], 00h
	je way2
	inc si
	jmp way3
way2:   
	inc si
way3:       
	cmp word ptr es:[si], 0000h
	jne way1
	add si, 4
way4:
	cmp byte ptr es:[si], 00h
	je change
	mov dl, es:[si]
	mov [di], dl
	inc si
	inc di
	jmp way4
change:
	call fileNameTest
	call clearMem
	jc error_memory
	jmp DTA_buf
error_memory:
	mov dx, offset NO_MEMORY
	call writeString
	mov NOT_MEMORY, 1 
	jmp nxt
DTA_buf:
    call memForDTA
nxt:
	cmp NOT_MEMORY, 1
	je exit
	
nxt_overlay:
	cmp amount, 0
	je exit 
	mov parameters, ax
	mov parameters+2, ax
	mov word ptr entry+2, ax
	
	lea dx, SEGADD
	call writeString
	call downloadProgram
	jc NOT_FILE
	
	call doOverlay
	call clearOverlayMem
	jmp contr
NOT_FILE:
	call fileNotFound
	jmp exit
contr:
	dec amount
	jmp nxt_overlay
	
exit:
	mov ah, 02h
	mov dl, 0Ah
	int 21h
	mov  ah, 4ch                         
	int  21h  
MAIN ENDP
;______________________________________________________________
;______________________________________________________________
TEMP PROC near
TEMP ENDP
;______________________________________________________________
CODE ENDS  
;______________________________________________________________ 
END main
;______________________________________________________________