TESTPC	SEGMENT
		ASSUME  CS:TESTPC, DS:TESTPC, ES:NOTHING, SS:NOTHING
		ORG     100H
START:		jmp     BEGIN

;Данные
addr_not_aval	db	13,10,'The segment address not available memory is $'
addr_env		db	13,10,'The environment adress is $'
tail			db	13,10,'The comand tail line is $'
cont			db	13,10,'The contents of the environment in the symbolic form is $'
path			db	13,10,'The path of loadable module is $'
emptyST			db            '0000$'
newST			db	13,10,'$'

;Процедуры
WriteMsg PROC NEAR
	push	AX
	mov	AH, 09h
	int 	21h
	pop 	ax
	ret
WriteMsg ENDP

;----------------------------------------

TETR_TO_HEX		PROC  NEAR
			and	AL, 0Fh
			cmp	AL, 09
			jbe	NEXT
			add	AL, 07
NEXT:			
			add	AL, 30h
			ret
TETR_TO_HEX		ENDP

;-----------------------------------------

BYTE_TO_HEX		PROC  NEAR
			push	CX
			mov	AH, AL
			call	TETR_TO_HEX
			xchg	AL, AH
			mov	CL, 4
			shr	AL, CL
			call	TETR_TO_HEX
			pop	CX
			ret
BYTE_TO_HEX		ENDP

;------------------------------------------

WRD_TO_HEX		PROC  NEAR
			push	BX
			mov	BH, AH
			call	BYTE_TO_HEX
			mov	[DI], AH
			dec	DI
			mov	[DI], AL
			dec	DI
			mov	AL, BH
			call	BYTE_TO_HEX
			mov	[DI], AH
			dec	DI
			mov	[DI], AL
			pop	BX
			ret
WRD_TO_HEX		ENDP

;-------------------------------------------

BYTE_TO_DEC		PROC  NEAR
			push	CX
			push	DX
			xor	AH, AH
			xor	DX, DX
			mov	CX, 10
loop_bd:		
			div	CX
			or	DL, 30h
			mov	[SI], DL
			dec	SI
			xor	DX, DX
			cmp	AX, 10
			jae	loop_bd
			cmp	AL, 00h
			je	end_l
			or	AL, 30h
			mov	[SI], AL
end_l:			
			pop	DX
			pop	CX
			ret
BYTE_TO_DEC		ENDP

;--------------------------------------------

addr_not_aval1	PROC NEAR


			push	AX
			push 	DX
			mov		AH, 09h
			mov 	DX, offset addr_not_aval
			call	WriteMsg
			mov 	AX, ES:[0002h]		
			mov 	DI, offset emptyST
			add 	DI, 3
			call 	WRD_TO_HEX
			mov 	AH, 09h
			mov 	DX, offset emptyST
			call	WriteMsg
			pop	DX
			pop	AX
			ret
addr_not_aval1	ENDP

;----------------------------------------------

addr_env1		PROC NEAR

			push	AX
			push 	DX

			mov		AH, 09h
			mov 	DX, offset addr_env
			call	WriteMsg
			mov 	AX, DS:[2Ch]		
			mov 	DI, offset emptyST
			add 	DI, 3
			call 	WRD_TO_HEX
			mov 	AH, 09h
			mov 	DX, offset emptyST
			call	WriteMsg

			pop	DX
			pop	AX
			ret
addr_env1		ENDP

;-----------------------------------------------

tail1		PROC NEAR
			
			push	AX
			push 	BX
			push 	CX
			push 	DX

			mov		AH, 09h
			mov 	DX, offset tail
			call 	WriteMsg
			xor 	CX, CX
			xor 	BX, BX
			mov 	CL, BYTE PTR ES:[80h]
			mov 	BX, 80h
			cmp 	CX, 0H
			je		emp				 
return:		
			inc 	BX
			mov 	DL, BYTE PTR ES:[BX]
			mov 	AH, 02h
			int 	21h
			loop	return

emp:		
			pop		DX
			pop		CX
			pop		BX
			pop		AX
			ret			
tail1		ENDP

;---------------------------------------------------

cont1		PROC NEAR

			push	AX
			push 	DX
						
			mov	AH, 09h
			mov 	DX, offset newST
			call 	WriteMsg
			mov 	DX, offset cont
			call 	WriteMsg
			mov 	DX, offset newST
			call 	WriteMsg
			push 	ES:[002Ch]
			pop 	ES
			xor 	BX, BX
			mov 	DL, BYTE PTR ES:[BX]
nextS:		
			cmp 	DL, 0h
			je 	zero
			mov 	AH, 02h
			int 	21h
			inc 	BX
			mov 	DL, BYTE PTR ES:[BX]
			jmp 	nextS
zero:			
			mov 	AH, 09h
			mov 	DX, offset newST
			call 	WriteMsg
			inc 	BX
			mov 	DL, BYTE PTR ES:[BX]
			cmp 	DL, 0h
			je 	end2
			jmp 	nextS

end2:			
			add 	BX, 3
			pop	DX
			pop	AX
			ret
cont1		ENDP

;----------------------------------------------------

way1	PROC NEAR				
			push	AX
			push 	CX
			push 	DX

			mov	AH, 09h
			mov 	DX, offset path
			call 	WriteMsg
			mov 	AH, 02h
contin:			
			mov 	DL,	BYTE PTR ES:[BX]
			cmp 	DL, 0h
			je	end3
			int 	21h 
			inc	BX
			jmp 	contin

end3:			
			pop	DX
			pop	CX
			pop	AX
			ret
way1	ENDP

;---------------------------CODE-----------------------

BEGIN:					
			call 	addr_not_aval1	
			call 	addr_env1		
			call 	tail1		
			call 	cont1		
			call 	way1
			
			
pushB:    
			mov 	AH, 10h
			int 	16h
			cmp 	AL, 0Dh
			jne 	pushB
                        		
close:
			mov 	AX, 4C00h
			int 	21H
			
			
TESTPC	ENDS
		END    START