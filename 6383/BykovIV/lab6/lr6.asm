.286

SSTACK       SEGMENT   STACK
			DW 64H DUP (0)
SSTACK       ENDS

ENVIROMENT_      SEGMENT        'ENVIRONMENT'
                         DB   'Bykov',0
                         DB   'Ilya',0
                         DB   '6383. Lab 6',0
          ENVEND         DB   0
ENVIROMENT_      ENDS

CODE      SEGMENT
          ASSUME         CS:CODE, DS:DATA, SS:SSTACK, ES:NOTHING
          KEEP_SS        DW   0
          KEEP_SP        DW   0
          KEEP_ERR       DW   0
          
TETR2HEX  PROC      NEAR
          and       AL,0FH
          cmp       AL,09
          jbe       NEXT
          add       AL,07
NEXT:     add       AL,30H
          ret
TETR2HEX  ENDP


BYTE2HEX  PROC      NEAR
          push      CX
          mov       AH,AL
          call      TETR2HEX
          xchg      AL,AH
          mov       CL,4
          shr       AL,CL
          call      TETR2HEX      
          pop       CX             
          ret
BYTE2HEX  ENDP


WORD2HEX  PROC      NEAR
          push      BX
          mov       BH,AH
          call      BYTE2HEX
          mov       [DI],AH
          dec       DI
          mov       [DI],AL
          dec       DI
          mov       AL,BH
          call      BYTE2HEX
          mov       [DI],AH
          dec       DI
          mov       [DI],AL
          pop       BX
          ret
WORD2HEX  ENDP


BYTE2DEC  PROC      NEAR
          push      CX
          push      DX
          push      AX
          xor       AH,AH
          xor       DX,DX
          mov       CX,10
LOOP_BD:  div       CX
          or        DL,30H
          mov       [SI],DL
          dec       SI
          xor       DX,DX
          cmp       AX,10
          jae       LOOP_BD
          cmp       AL,00H
          JE        END_L
          or        AL,30H
          mov       [SI],AL
END_L:    pop       AX
          pop       DX
          pop       CX
          ret
BYTE2DEC  ENDP

MAKEPATH  MACRO     FILENAME,RESULTPATH
          push      ES
          push      BX
          push      DX
          push      DI
          push      SI
          mov       ES,ES:[002CH]
          xor       BX,BX
ROAD2ZERO:mov       DX,ES:[BX]
          cmp       DX,0000H
          jz        READPATH
          inc       BX
          jmp       ROAD2ZERO
READPATH: add       BX,4
          mov       DI,OFFSET RESULTPATH
COPYPATH: mov       DL,ES:[BX]
          mov       [DI],DL
          inc       DI
          inc       BX
          cmp       DL,00H
          jnz       COPYPATH
BACKPATH: dec       DI
          mov       DL,[DI]
          cmp       DL,92
          jne       BACKPATH
          mov       SI,OFFSET FILENAME
COPYNAME: inc       DI
          mov       DL,[SI]
          mov       [DI],DL
          inc       SI
          cmp       DL,00H
          jnz       COPYNAME
          pop       SI
          pop       DI
          pop       DX
          pop       BX
          pop       ES
          ENDM	  
FORMATRES PROC      NEAR
          push      SI
          push      AX
          mov       SI,OFFSET STR_CODE_RETURN+21
          mov       [SI],AL
          call      BYTE2HEX          
          mov       SI,OFFSET STR_CODE_RETURN+26
          mov       [SI],AL
          mov       [SI+1],AH
          pop       AX
          pop       SI
          ret
FORMATRES ENDP


puts      MACRO     STRING
          push      AX
          push      DX
          mov       DX,OFFSET STRING
          mov       AH,09H
          int       21H
          pop       DX
          pop       AX
          ENDM

; Точка входа
MAIN      PROC      NEAR
          mov       AX,DATA
          mov       DS,AX
          mov       BX,OFFSET PROGEND
          mov       AH,4AH
          int       21H
          jnc       PREPARE
          cmp       AX,07H
          jne       TESTERR8
          puts      STR_ERROR_7
          jmp       EXIT
TESTERR8: cmp       AX,08H
          jne       TESTERR9
          puts      STR_ERROR_8
          jmp       EXIT
TESTERR9: cmp       AX,09H
          jne       UNERRFREE
          puts      STR_ERROR_9
          jmp       EXIT
UNERRFREE:puts      STR_UNKNOWN_ERROR
          jmp       EXIT
PREPARE:  
		 MAKEPATH  FILE,FULLPATH
          push      DS
          push      ES
          mov       KEEP_SS,SS
          mov       KEEP_SP,SP
		  push      DS
          pop       ES
          mov       DX,OFFSET FULLPATH
          mov       BX,OFFSET ENV
          mov       AH,4BH
          mov       AL,00H
          int       21H
          mov       SS,KEEP_SS
          mov       SP,KEEP_SP
          pop       ES
          pop       DS
          jc        ERROR1
          mov       AH,4DH
          int       21H
          call      FORMATRES
          puts      STR_CODE_RETURN
          cmp       AH,00H
          jne       RET1
          puts      STR_RETURN_0
          jmp       EXIT
RET1:     cmp       AH,01H
          jne       RET2
          puts      STR_RETURN_1
          jmp       EXIT
RET2:     cmp       AH,02H
          jne       RET3
          puts      STR_RETURN_2
          jmp       EXIT
RET3:     cmp       AH,03H
          jne       UNRET
          puts      STR_RETURN_3
          jmp       EXIT
UNRET:    puts      STR_UNKNOWN_RETURN
          jmp       EXIT
ERROR1:   cmp       AX,01H
          jne       ERROR2
          puts      STR_ERROR_1
          jmp       EXIT
ERROR2:   cmp       AX,02H
          jne       ERROR3
          puts      STR_ERROR_2
          jmp       EXIT
ERROR3:   cmp       AX,03H
          jne       ERROR5
          puts      STR_ERROR_3
          jmp       EXIT
ERROR5:   cmp       AX,05H
          jne       ERROR8
          puts      STR_ERROR_5
          jmp       EXIT
ERROR8:   cmp       AX,08H
          jne       ERRORA
          puts      STR_ERROR_8
          jmp       EXIT
ERRORA:   cmp       AX,0AH
          jne       ERRORB
          puts      STR_ERROR_A
          jmp       EXIT
ERRORB:   cmp       AX,0BH
          jne       UNERR
          puts      STR_ERROR_B
          jmp       EXIT
UNERR:    puts      STR_UNKNOWN_ERROR
EXIT:     xor       AL,AL
          mov       AH,4CH
          int       21H
          ret
MAIN      ENDP
PROGEND:
CODE      ENDS

DATA      SEGMENT
          STR_SUCCESS      			DB   'Free: success',0DH,0AH,'$'
          STR_ERROR_1       		DB   'ERR: Invalid function number',0DH,0AH,'$'
          STR_ERROR_2       		DB   'ERR: File not found',0DH,0AH,'$'
          STR_ERROR_3       		DB   'ERR: Path not found',0DH,0AH,'$'
          STR_ERROR_5       		DB   'ERR: Access denied',0DH,0AH,'$'
          STR_ERROR_7       		DB   'ERR: Memory control blocks destroyed',0DH,0AH,'$'
          STR_ERROR_8       		DB   'ERR: Insufficient memory',0DH,0AH,'$'
          STR_ERROR_9       		DB   'ERR: Invalid memory block address',0DH,0AH,'$'
          STR_ERROR_A       		DB   'ERR: Invalid environment',0DH,0AH,'$'
          STR_ERROR_B       		DB   'ERR: Invalid format',0DH,0AH,'$'
          STR_UNKNOWN_ERROR      	DB   'ERR: Unknown',0DH,0AH,'$'
          STR_RETURN_0       		DB   'Return 0: Exit success',0DH,0AH,'$'
          STR_RETURN_1       		DB   'Return 1: Ctrl-Break',0DH,0AH,'$'
          STR_RETURN_2       		DB   'Return 2: Device error',0DH,0AH,'$'
          STR_RETURN_3       		DB   'Return 3: 31H exit',0DH,0AH,'$'
          STR_UNKNOWN_RETURN      	DB   'Return ?: unknown',0DH,0AH,'$'
          STR_CODE_RETURN     		DB   'Process return key: " " -   H',0DH,0AH,'$'

          FILE           DB   'LR2.COM',0
          FULLPATH       DB   128 DUP (0)
          CMDLINE        DB   24," MY LINE TAIL FROM LAB6",0DH 
          
          ENV            DW   ENVIROMENT_
                         DW   OFFSET CMDLINE
                         DW   SEG CMDLINE
                         DD   0       
                         DD   0              
DATA      ENDS

          END       MAIN
		  