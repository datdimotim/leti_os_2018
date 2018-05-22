ISTACK SEGMENT STACK
	dw 100h dup (?)
ISTACK ENDS

CODE SEGMENT
	ASSUME CS:CODE, DS:DATA, ES:DATA, SS:STACK
START: JMP 	Main
;-------------------------------------------------------------------------
PRINT_A_STR	PROC	FAR
		push	AX
		mov		AH,09H
		int		21H
		pop		AX
		ret
PRINT_A_STR	ENDP
;-------------------------------------------------------------------------
; ��������� ����������� ����������
ROUT 		PROC 	FAR

jmp RoutCode

;������
Signature 		DB 'AAAA'
KeepIP 			DW 0
KeepCS 			DW 0
KeepPSP			DW 0
	
RoutCode:
		push 	AX
		push 	DX
		push 	DS
		push 	ES
		
		;��������� scan-���
		mov 	AH,2H		; ���������  ��������� ����������
		int 	16H
		cmp 	AL,2		; ����� Shift �����
		jz 		RoutStandart
		cmp 	AL,1		; ������ Shift �����
		jz		RoutStandart
		in 		AL,60H
		cmp 	AL, 02H ; ������� - 1
		jz 		UserRout_1 
		cmp 	AL, 03H ; ������� - 2
		jz 		UserRout_2
		cmp 	AL, 04H ; ������� - 3
		jz 		UserRout_3
		
		;���� ������ ������ ����-���, ��� � ����������� ����������
		jmp 	RoutStandart 

UserRout_1:
		mov 	CL,'A'
		call 	UserRout
		jmp		R_END
UserRout_2:
		mov 	CL,'B'
		call 	UserRout
		jmp		R_END
UserRout_3:
		mov 	CL,'C'
		call 	UserRout
		jmp		R_END
	
RoutStandart:
		pushf
		call DWORD PTR CS:KeepIP
				
R_END:
		pop 	ES
		pop 	DS
		pop 	DX
		pop 	AX 
		iret
ROUT 	ENDP
;-------------------------------------------------------------------------
;���������������� ����������
UserRout	PROC
	mov 	AX, 0040h
	mov 	ES, AX
		
	in 		AL, 61H   
	mov 	AH, AL     
	or 		AL, 80H    
	out 	61H, AL    
	xchg 	AH, AL    
	out 	61H, AL    
	mov 	AL, 20H     
	out 	20H, AL     

RoutPushToBuff:
	mov 	AH,05H
	mov 	CH,00H
	int 	16H
	or 		AL, AL
	jz _END 
	
	CLI
		mov AX,ES:[1AH]
		mov ES:[1CH],AX 
	STI
	jmp RoutPushToBuff
_END: 	ret
UserRout	ENDP
;-------------------------------------------------------------------------
; ��������� ���������� 
SetINT 	PROC
		push 	DS
		mov 	AH, 35H
		mov 	AL, 09H
		int 	21H
		
		mov 	KeepIP, BX
		mov 	KeepCS, ES
		
		;���������
		mov 	DX, OFFSET ROUT 
		mov 	AX, SEG ROUT
		mov 	DS, AX
		mov 	AH, 25H
		mov 	AL, 09H
		int 	21H
		pop 	DS
		ret
SetINT 	ENDP 
;-------------------------------------------------------------------------
;�������������� ������������ ������� ����������
RecoverRout PROC
		push 	DS
		CLI	
			mov 	DX, ES:[BX+SI+4] ;ip
			mov 	AX, ES:[BX+SI+6] ;cs
			mov 	DS, AX
			mov 	AX, 2509H
			int 	21H 			 ;��������������� ������
			push 	ES
			;����������� ������:
			;����� ���������� �����
			mov 	ES, ES:[BX+SI+8] ;psp
			mov 	ES, ES:[2CH]
			mov 	AH, 49H         
			int 	21H
			pop 	ES
			;����� ����������� ���������
			mov 	ES, ES:[BX+SI+8]
			mov 	AH, 49H
			int 	21H	
		STI
		pop 	DS
		ret
RecoverRout ENDP 
;-------------------------------------------------------------------------
CheckSignature 	PROC
		; �������� 09h
		mov 	AH, 35H
		mov 	AL, 09H
		int 	21H 
	
		mov 	SI, OFFSET Signature
		sub 	SI, OFFSET ROUT 
	
		mov 	AX, 'AA'
		cmp 	AX, ES:[BX+SI]
		jne 	MarkNotLoaded
		cmp 	AX, ES:[BX+SI+2]
		jne 	MarkNotLoaded
		jmp 	MarkLoaded 
	
MarkNotLoaded:
		;��������� ���������������� ������� ����������
		mov 	DX, OFFSET Loaded
		call 	PRINT_A_STR
		call 	SetINT
		;���������� ������������ ���������� ������ ��� ����������� ���������:
		mov 	DX, OFFSET END_BYTE 
		mov 	CL, 4
		shr 	DX, CL
		inc 	DX	 				
		add 	DX, CODE 			
		sub 	DX, KeepPSP 		
		
		xor 	AL, AL
		mov 	AH, 31H
		int 	21H 
		
MarkLoaded:
		;Check for /un
		push 	ES
		push 	BX
		mov 	BX, KeepPSP
		mov 	ES, BX
		cmp 	BYTE PTR ES:[82H],'/'
		jne 	NoDelete
		cmp 	BYTE PTR ES:[83H],'u'
		jne 	NoDelete
		cmp 	BYTE PTR ES:[84H],'n'
		je 		DELETE
		
NoDelete:
		pop 	BX
		pop 	ES
	
		mov 	DX, OFFSET AlreadyLoaded
		call 	PRINT_A_STR
		ret

;���� un - ������� ���������������� ����������
DELETE:
		pop 	BX
		pop 	ES
		call	RecoverRout
		mov 	DX, OFFSET Unloaded
		call 	PRINT_A_STR
		ret
CheckSignature 	ENDP
;-------------------------------------------------------------------------
Main:
		mov 	AX, data
		mov 	DS, AX
		mov 	CS:KeepPSP, ES
	
		call 	CheckSignature
	
		xor 	AL,AL
		mov 	AH,4CH
		int 	21H
	
END_BYTE:
		ret
CODE ENDS

DATA SEGMENT
	Loaded DB 'User interruption is already loaded',0DH,0AH,'$'
	AlreadyLoaded DB 'User interruption is successfully unloaded',0DH,0AH,'$'
	Unloaded DB 'User interruption is loaded',0DH,0AH,'$'
DATA ENDS

STACK SEGMENT STACK
	dw 512 dup (?)
STACK ENDS
 END START