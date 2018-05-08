.286
REQ_KEY equ 13h ;скан-код буквы R
 

CODE SEGMENT
	ASSUME CS:CODE, DS:DATA, SS:STACK_S	
	
INTERRUPT PROC far
mov  CS:KEEP_AX, AX

	in   AL, 60h		
	cmp  AL, REQ_KEY		
	je   do_req

		mov  AX, CS:KEEP_AX
		jmp  dword ptr CS:[KEEP_IP]
		
do_req:
;;;
;
mov  CS:KEEP_SS, SS
mov  CS:KEEP_SP, SP

mov  AX, SEG NEW_STACK
mov  SS, AX
mov  SP, offset QWE
pusha      

	in   AL, 61h			 
	or   AL, 80h			
	out  61h, AL		
	and  AL, 7Fh			
	out  61h, AL			
	mov  AL, 20h		
	out  20h, AL		 
		
	push DX
		mov  AX, 40h		
		mov  DS, AX			
		mov  AX, DS:[17h]	
	pop  DX
		
	mov  CL, 'R'
	and  AX, 04h			;зажатие Ctrl
	je   skip
		mov  CL, 'O'
			
skip:
	mov  AH, 05h			
	and  CH, 0					
	int  16h					
	
	or  AL, AL					
	jz  INT_EXIT
	
		cli						
		push DS					
			mov  AX, 40h		
			mov  DS, AX			
								
			mov  AX, DS:[1Ah]	
			mov  DS:[1Ch], AX	
		pop  DS					
		sti						
		jmp  skip
		
		
INT_EXIT:		
popa 

mov  AX, CS:KEEP_SS  
mov  SS, AX
mov  SP, CS:KEEP_SP 

	mov al, 20h
	out 20h, al
	
mov  AX, CS:KEEP_AX  

	iret	 ;выход
	
	nop
	INT_KEY		db 'sfsdgihodh;9/8652lhkadfglhkjfgjgdxh/86451!', 0ah, '$'
	KEEP_IP		dw 0h
	KEEP_CS 	dw 0h
	KEEP_PSP	dw 0h
	
	KEEP_SP		dw 0h
	KEEP_SS		dw 0h
	KEEP_AX		dw 0h
	
	NEW_STACK	db 1Ah DUP(0)	
	
INTERRUPT	ENDP
QWE:		
	
	
MAIN PROC far
	push DS
		mov  CS:KEEP_PSP, DS
	and  AX, 0
	push AX
	mov  AX, DATA
	mov  DS, AX

	mov  ah, 35h					
	mov  al, 09h					
	int  21h						
	
	mov  DI, BX						
	mov  DI, offset ES:INT_KEY		
	mov  SI, offset KEY				
	mov  CX, 42							
	repe cmpsb						
	cmp  CX, 0						
	jz   nqwe 						
	
	mov  DX, offset INT_SET
	mov  AH, 09h
	int  21h
	mov  CS:KEEP_IP, BX
	mov  CS:KEEP_CS, ES
	push DS
		mov  DX, offset INTERRUPT 	
		mov  AX, SEG    INTERRUPT 	
		mov  DS, AX				  	
		mov  AH, 25h 			  	
		mov  AL, 09h 			  	
		int  21h 				  	
	pop  DS
	
	
	
	mov  DX, offset QWE			
	shr  DX, 4					
	inc  DX						
	add  DX, CODE				
	sub  DX, CS:KEEP_PSP		
	mov  AH, 31h				
	int  21h					

nqwe:
	push ES
		mov  ES, CS:KEEP_PSP	
		mov  DI, 82h			
		mov  SI, offset TCL_KEY	
		mov  CX, 3				
	
		repe cmpsb				
		cmp  CX, 0				
		jne  alr_inst			
	pop  ES
	
	mov  DX, offset INT_RES
	mov  AH, 09h
	int  21h	
	
	CLI
	push DS
		mov  DX, ES:KEEP_IP
		mov  AX, ES:KEEP_CS
		mov  DS, AX
		mov  AH, 25h 			
		mov  AL, 09h 			
		int  21h 				
	pop  DS
	STI
	
	mov  ES, ES:KEEP_PSP		
	
	push ES						
		mov  ES, ES:[2Ch]		
		mov  AH, 49h  			
		int  21h				
	pop  ES						
	int  21h					
	
	jmp exit
	
alr_inst:
	mov  DX, offset INT_ALR		
	mov  AH, 09h				
	int 21h						
	
exit:
	mov  AH, 4Ch
	int  21h

MAIN ENDP
CODE ENDS

DATA SEGMENT
	KEY		db 'sfsdgihodh;9/8652lhkadfglhkjfgjgdxh/86451!', 0ah, '$'
	INT_ALR	db 'Custom interrupt already installed', 0Ah, '$'
	INT_SET	db 'Setting the custom interrupt', 0Ah, '$'
	INT_RES	db 'Restore system interrupt', 0Ah, '$'
	TCL_KEY	db '/un'
DATA ENDS

STACK_S SEGMENT STACK
	DW 100h DUP(?)
STACK_S ENDS

END MAIN