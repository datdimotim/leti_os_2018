  overlay segment
overlay_fun proc far
       assume cs:overlay
	mov 	ax, cs
	
	mov		ax,cs

	push 	BX 
	mov 	BH, AH 
	call 	Byte_To_Hex
	mov 	ch, AH 
	mov 	cl, AL 
	mov 	AL, BH 
	call 	Byte_To_Hex
	mov 	dh, AH 
	mov 	dl, AL 
	pop	 	BX

	mov		ah, 02h
	int		21h	
	mov 	dl, dh
	int 	21h
	mov 	dl, cl
	int 	21h
	mov 	dl, ch
	int 	21h

	retf	
   overlay_fun endp
   
Tetr_To_Hex PROC near
	and 	AL, 0Fh 
	cmp 	AL, 09 
	jbe 	NEXT 
	add 	AL, 07 
NEXT: 
	add 	AL, 30h 
	ret 
   Tetr_To_Hex ENDP 

Byte_To_Hex PROC near 
	push 	CX 
	mov 	AH, AL 
	call 	Tetr_To_Hex 
	xchg 	AL, AH 
	mov 	CL, 4 
	shr 	AL, CL 
	call 	Tetr_To_Hex 
	pop 	CX 
	ret 
   Byte_To_Hex ENDP 

  overlay ends
	end 
