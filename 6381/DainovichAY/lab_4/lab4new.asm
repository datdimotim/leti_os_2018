INT_STACK SEGMENT STACK
	DW 64 DUP (?)
INT_STACK ENDS
;---------------------------------------------------------------
CODE SEGMENT
 ASSUME CS:CODE, DS:DATA, ES:DATA, SS:STACK
START: JMP MAIN
;---------------------------------------------------------------
setCurs PROC ;��������� ������� �������; ��������� �� ������ 25 ������ ������ ���������
	push AX
	push BX
	push CX
	mov AH,02h
	mov BH,00h
	int 10h ;����������
	pop CX
	pop BX
	pop AX
	ret
setCurs ENDP
;---------------------------------------------------------------
getCurs PROC ;�������, ������������ ������� � ������ ������� 
	push AX
	push BX
	push CX
	mov AH,03h ;03h ������ ������� � ������ �������
	mov BH,00h ;BH = ����� ��������
	int 10h ;����������
	;�����: DH, DL = ������� ������, ������� �������
	;CH, CL = ������� ���������, �������� ������ �������
	pop CX
	pop BX
	pop AX
	ret
getCurs ENDP
;---------------------------------------------------------------
ROUT PROC FAR ;���������� ����������
	jmp ROUT_CODE
ROUT_DATA:
	SIGNATURE DB '0000' ;���������, ��������� ���, ������� �������������� ��������
	KEEP_CS DW 0 ;��� �������� ��������
	KEEP_IP DW 0 ;� �������� ����������
	KEEP_PSP DW 0 ;� PSP
	DELETE DB 0 ;����������, �� ������� ������������, ���� ��������� ���������� ��� ���
	KEEP_SS DW 0
	KEEP_AX DW 0	
	KEEP_SP DW 0
	COUNTER DB 'Total number of interrupts: 0000 $' ;�������
ROUT_CODE:
	mov KEEP_AX, AX ;��������� ax
	mov KEEP_SS, SS ;��������� ����
	mov KEEP_SP, SP
	mov AX, seg INT_STACK ;������������� ����������� ����
	mov SS, AX
	mov SP, 64h
	mov AX, KEEP_AX
	push DX ;���������� ���������� ���������
	push DS
	push ES
	;��������� ����������
	cmp DELETE, 1
	je ROUT_REC1
	;��������� �������
	call getCurs ;�������� ������� ��������� ������� 
	push DX ;���������� ��������� ������� � �����
	mov DH,16h ;DH, DL - ������, ������� (������ �� 0) 
	mov DL,25h
	call setCurs ;������������� ������

ROUT_CALC:	
	;������� ���������� ����������
	push SI ;���������� ���������� ���������
	push CX 
	push DS
	mov AX,SEG COUNTER
	mov DS,AX
	mov SI,offset COUNTER ;��� ��������� ��������
	add SI,1Fh ;�������� �� ��������� �����
	;(000*) 
	mov AH,[SI] ;�������� �����
	inc AH ;����������� � �� 1
	mov [SI],AH ;����������
	cmp AH,3Ah ;���� �� ������ 9
	jne END_CALC ;�����������
	mov AH,30h ;��������
	mov [SI],AH ;���������� � ��������� �� ����������� �����
	;(00*0) 
	mov BH,[SI-1] 
	inc BH 
	mov [SI-1],BH
	cmp BH,3Ah                   
	jne END_CALC 
	mov BH,30h 
	mov [SI-1],BH 
	;(0*00) 
	mov CH,[SI-2] 
	inc CH 
	mov [SI-2],CH 
	cmp CH,3Ah  
	jne END_CALC 
	mov CH,30h 
	mov [SI-2],CH 
	;(*000) 
	mov DH,[SI-3] 
	inc DH 
	mov [SI-3],DH
	cmp DH,3Ah
	jne END_CALC
	mov DH,30h
	mov [SI-3],DH
ROUT_REC1:
	cmp DELETE, 1
	je ROUT_REC
END_CALC:
    pop DS
    pop CX
	pop SI
	;����� ��������-������ �� �����
	push ES 
	push BP
	mov AX,SEG COUNTER
	mov ES,AX
	mov AX,offset COUNTER
	mov BP,AX ;ES:BP = ����� 
	mov AH,13h ;������� 13h ���������� 10h
	mov AL,00h ;����� ������
	mov CX,20h ;����� ������
	mov BH,0 ;����� ��������
	int 10h
	pop BP
	pop ES
	
	;����������� �������
	pop DX
	call setCurs
	jmp ROUT_END

	;�������������� ������� ����������
ROUT_REC:
	CLI ;���������� ����������
	mov DX,KEEP_IP
	mov AX,KEEP_CS
	mov DS,AX ;DS:DX = ������ ����������: ����� ��������� ��������� ����������
	mov AH,25h 
	mov AL,1Ch 
	int 21h ;��������������� ������
	;������������ ������, ���������� ����������
	mov ES, KEEP_PSP 
	mov ES, ES:[2Ch] ;ES = ���������� ����� (��������) �������������� ����� ������ 
	mov AH, 49h ;������� 49h ���������� 21h    
	int 21h ;������������ ��������������� ����� ������
	mov ES, KEEP_PSP ;ES = ���������� ����� (��������) �������������� ����� ������ 
	mov AH, 49h ;������� 49h ���������� 21h  
	int 21h	;������������ ��������������� ����� ������
	STI ;���������� ����������
ROUT_END:
	pop ES ;�������������� ���������
	pop DS
	pop DX
	mov SS, KEEP_SS
	mov SP, KEEP_SP
	mov AX, KEEP_AX
	iret
ROUT ENDP
LAST_BYTE:
;---------------------------------------------------------------
PRINT PROC NEAR ;����� �� ����� 
	push ax
	mov ah, 09h
	int 21h
	pop ax
	ret
PRINT ENDP
;---------------------------------------------------------------
CHECK_INT PROC ;�������� ����������
	;��������, ����������� �� ���������������� ���������� � �������� 1Ch
	mov AH,35h 
	mov AL,1Ch 
	int 21h 
			
	
	mov SI, offset SIGNATURE 
	sub SI, offset ROUT 
	
	mov AX,'00' ;������� ��������� �������� ���������
	cmp AX,ES:[BX+SI] 
	jne NOT_LOADED 
	cmp AX,ES:[BX+SI+2] 
	jne NOT_LOADED 
	jmp LOADED ;���� �������� ���������, �� �������� ����������
	
NOT_LOADED: ;��������� ����������������� ����������
	call SET_INT ;��������� ��������� ����������������� ����������
	;���������� ������������ ���������� ������ ��� ����������� ���������
	mov DX,offset LAST_BYTE ;������ � ������ �� ������
	mov CL,4 ;������� � ���������
	shr DX,CL
	inc DX	;������ � ����������
	add DX,CODE ;���������� ����� �������� CODE
	sub DX,KEEP_PSP ;�������� ����� �������� PSP
	xor AL,AL
	mov AH,31h 
	int 21h ;��������� ������ ���������� ������
			;(dx - ���������� ����������) � ������� � DOS, �������� ��������� � ������ ���������� 
		
LOADED: ;�������, ���� �� � ������ /un , ����� ����� ���������
	push ES
	push AX
	mov AX,KEEP_PSP 
	mov ES,AX
	cmp byte ptr ES:[82h],'/' ;���������� ���������
	jne NOT_UNLOAD 
	cmp byte ptr ES:[83h],'u'
	jne NOT_UNLOAD 
	cmp byte ptr ES:[84h],'n' 
	je UNLOAD ;���������
NOT_UNLOAD: ;���� �� /un
	pop AX
	pop ES
	mov dx,offset ALR_LOADED
	call PRINT
	ret
	;�������� ����������������� ����������
UNLOAD: ;���� /un
	pop AX
	pop ES
	mov byte ptr ES:[BX+SI+10],1 ;DELETE = 1
	mov dx,offset UNLOADED ;����� ���������
	call PRINT
	ret
CHECK_INT ENDP
;---------------------------------------------------------------
SET_INT PROC ;��������� ����������� ���������� � ���� �������� ����������
	push DX
	push DS
	mov AH,35h ;������� ��������� �������
	mov AL,1Ch 
	int 21h
	mov KEEP_IP,BX 
	mov KEEP_CS,ES 
	mov DX,offset ROUT 
	mov AX,seg ROUT 
	mov DS,AX 
	mov AH,25h 
	mov AL,1Ch 
	int 21h ;������ ����������
	pop DS
	mov DX,offset IS_LOADDED ;����� ���������
	call PRINT
	pop DX
	ret
SET_INT ENDP 
;---------------------------------------------------------------
MAIN:
	mov AX,DATA
	mov DS,AX
	mov KEEP_PSP,ES ;���������� PSP
	call CHECK_INT ;�������� ����������
	xor AL,AL
	mov AH,4Ch ;����� 
	int 21H
	CODE ENDS
	
STACK SEGMENT STACK
	DW 64 DUP (?)
STACK ENDS
;---------------------------------------------------------------
DATA SEGMENT
	ALR_LOADED DB 'User interruption is already loaded!',0DH,0AH,'$'
	UNLOADED DB 'User interruption is unloaded!',0DH,0AH,'$'
	IS_LOADDED DB 'User interruption is loaded!',0DH,0AH,'$'
DATA ENDS
	END START
	
	