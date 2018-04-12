STACK SEGMENT STACK
	DW 64 DUP (?)
STACK ENDS
;////////////////////////////////////////////////////////
DATA SEGMENT
	INT_ALR_LOADED DB 'User interruption is already loaded!',10,13,'$'
	INT_UNLOADED DB 'User interruption is unloaded!',10,13,'$'
	INT_LOADDED DB 'User interruption is loaded!',10,13,'$'
DATA ENDS
;////////////////////////////////////////////////////////
CODE SEGMENT
	ASSUME CS:CODE, DS:DATA, ES:DATA, SS:STACK
start: jmp MAIN
;---------------------------------------------------------------
PRINT_STR PROC
	push ax
	mov ah, 09h
	int 21h
	pop ax
	ret
PRINT_STR ENDP
;---------------------------------------------------------------
SET_CURS PROC ;установка позиции курсора
	push AX
	push BX
	push CX
	mov AH,02h
	mov BH,00h
	int 10h
	pop CX
	pop BX
	pop AX
	ret
SET_CURS ENDP
;---------------------------------------------------------------
GET_CURS PROC ;определение позиции и размера курсора 
	push AX
	push BX
	push CX
	mov AH,03h
	mov BH,00h
	int 10h
	pop CX
	pop BX
	pop AX
	ret
GET_CURS ENDP
;---------------------------------------------------------------
ROUT PROC FAR ;обработчик прерывания
	jmp ROUT_CODE
ROUT_DATA:
	SIGNATURE DB '0000'
	KEEP_CS DW 0
	KEEP_IP DW 0
	KEEP_PSP DW 0
	DELETE DB 0
	COUNTER DB '0000$'
ROUT_CODE:
	push AX
	push DX
	push DS
	push ES
	cmp DELETE, 1
	je ROUT_REC1
	;установка курсора
	call GET_CURS
	push DX
	mov DH,16h
	mov DL,25h
	call SET_CURS

ROUT_CALC:
	push SI
	push CX 
	push DS
	mov AX,SEG COUNTER
	mov DS,AX
	mov SI,offset COUNTER
	add SI,3h
	;(000*) 
	mov AH,[SI]
	inc AH
	mov [SI],AH
	cmp AH,3Ah
	jne END_CALC
	mov AH,30h
	mov [SI],AH
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
	push ES 
	push BP
	mov AX,SEG COUNTER
	mov ES,AX
	mov AX,offset COUNTER
	mov BP,AX
	mov AH,13h
	mov AL,00h
	mov CX,4h
	mov BH,0
	int 10h
	pop BP
	pop ES
	;возвращение курсора
	pop DX
	call SET_CURS
	jmp ROUT_END

ROUT_REC: ;восстановление вектора прерывания
	CLI ;запрещение прерывания
	mov DX,KEEP_IP
	mov AX,KEEP_CS
	mov DS,AX
	mov AH,25h 
	mov AL,1Ch 
	int 21h
	;освобождение памяти, занимаемой резидентом
	mov ES, KEEP_PSP 
	mov ES, ES:[2Ch]
	mov AH, 49h
	int 21h
	mov ES, KEEP_PSP
	mov AH, 49h
	int 21h
	STI ;разрешение прерывания
ROUT_END:
	pop ES
	pop DS
	pop DX
	pop AX 
	iret
ROUT ENDP
;---------------------------------------------------------------
CHECK_INT PROC
	mov AH,35h 
	mov AL,1Ch 
	int 21h 
			
	mov SI, offset SIGNATURE
	sub SI, offset ROUT
	
	mov AX,'00' ;сравнивание известных значений сигнатуры
	cmp AX,ES:[BX+SI]
	jne NOT_LOADED
	cmp AX,ES:[BX+SI+2]
	jne NOT_LOADED
	mov AX,0h
	ret
NOT_LOADED:
	mov AX,1h
	ret
CHECK_INT ENDP
;---------------------------------------------------------------	
SET_INTER_HANDLER PROC
	call SET_INTER
	mov DX,offset LAST_BYTE
	mov CL,4
	shr DX,CL
	inc DX
	add DX,CODE
	sub DX,KEEP_PSP
	xor AL,AL
	mov AH,31h 
	int 21h ;выход в DOS при оставлении программы в памяти резидентно 
SET_INTER_HANDLER ENDP
;---------------------------------------------------------------
UNLOADING_INT PROC
	push ES
	push AX
	mov AX,KEEP_PSP 
	mov ES,AX
	cmp byte ptr ES:[82h],'/' ;сравниваем аргументы
	jne NOT_UNLOAD 
	cmp byte ptr ES:[83h],'u'
	jne NOT_UNLOAD 
	cmp byte ptr ES:[84h],'n' 
	je UNLOAD
NOT_UNLOAD:
	pop AX
	pop ES
	mov dx,offset INT_ALR_LOADED
	call PRINT_STR
	ret
	;выгрузка пользовательского прерывания
UNLOAD:
	pop AX
	pop ES
	mov byte ptr ES:[BX+SI+10],1
	mov dx,offset INT_UNLOADED
	call PRINT_STR
	ret
UNLOADING_INT ENDP
;---------------------------------------------------------------
SET_INTER PROC ;установка написанного прерывания в поле векторов прерываний
	push DX
	push DS
	mov AH,35h
	mov AL,1Ch 
	int 21h
	mov KEEP_IP,BX 
	mov KEEP_CS,ES 
	mov DX,offset ROUT 
	mov AX,seg ROUT 
	mov DS,AX 
	mov AH,25h 
	mov AL,1Ch 
	int 21h
	pop DS
	mov DX,offset INT_LOADDED
	call PRINT_STR
	pop DX
	ret
SET_INTER ENDP 
;---------------------------------------------------------------
MAIN:
	mov ax,data
	mov ds,ax
	mov KEEP_PSP,es
	call CHECK_INT
	cmp AX,0h
	je UNLOADING
	call SET_INTER_HANDLER
UNLOADING:
	call UNLOADING_INT
	xor AL,AL
	mov AH,4Ch
	int 21H
LAST_BYTE:
CODE ENDS
END START