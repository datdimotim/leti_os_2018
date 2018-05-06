.286

STK       SEGMENT   STACK
          DW 100 DUP (0)
STK       ENDS

CODE      SEGMENT
          ASSUME         CS:CODE, DS:DATA, SS:STK, ES:NOTHING

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
puts      MACRO     STRING
          push      AX
          push      DX
          mov       DX,OFFSET STRING
          mov       AH,09H
          int       21H
          pop       DX
          pop       AX
          ENDM      
		  
MAKEPATH_2  MACRO     FILENAME_2,RESULTPATH
          push      ES
          push      BX
          push      DX
          push      DI
          push      SI
          mov       ES,ES:[002CH]
          xor       BX,BX
ROAD2ZERO_2:
		  mov       DX,ES:[BX]
          cmp       DX,0000H
          jz        READPATH_2
          inc       BX
          jmp       ROAD2ZERO_2
READPATH_2: 
	      add       BX,4
          mov       DI,OFFSET RESULTPATH
COPYPATH_2: 
          mov       DL,ES:[BX]
          mov       [DI],DL
          inc       DI
          inc       BX
          cmp       DL,00H
          jnz       COPYPATH_2
BACKPATH_2: 
          dec       DI
          mov       DL,[DI]
          cmp       DL,92    
          jne       BACKPATH_2
          mov       SI,OFFSET FILENAME_2
COPYNAME_2: 
          inc       DI
          mov       DL,[SI]
          mov       [DI],DL
          inc       SI
          cmp       DL,00H
          jnz       COPYNAME_2       
          pop       SI
          pop       DI
          pop       DX
          pop       BX
          pop       ES
          ENDM
  		  
FREE_MEMORY   PROC      NEAR
          push      BX
          push      AX
          mov       BX,OFFSET PROGEND
          mov       AH,4AH
          int       21H
          jnc       FREEEXIT
          mov       FREE_EXIT_CODE,1
          cmp       AX,07H
          jne       TESTERR8
          puts      STR_ERROR_7
          jmp       FREEEXIT
TESTERR8: cmp       AX,08H
          jne       TESTERR9
          puts      STR_ERROR_8
          jmp       FREEEXIT
TESTERR9: cmp       AX,09H
          jne       UNERRFREE
          puts      STR_ERROR_9
          jmp       FREEEXIT
UNERRFREE:puts      STR_UNKNOWN_ERROR
FREEEXIT: pop       AX
          pop       BX
          ret
FREE_MEMORY   ENDP

READ_OVL  PROC      NEAR
          push      BP
          push      AX
          push      BX
          push      DX
          push      CX
          mov       AH,1AH
          mov       DX,OFFSET DTA_BUFFER
          int       21H
          mov       AH,4EH
          mov       DX,OFFSET FULLPATH
          mov       CX,0
          int       21H
          jnc       BYTE2PAR
          mov       READ_EXIT_CODE,1
          cmp       AX,12H
          jne       TESTERR3
          puts      STR_ERROR_2
          jmp       READEXIT
TESTERR3: cmp       AX,02H
          jne       UNERRREAD
          puts      STR_ERROR_3
          jmp       READEXIT
UNERRREAD:puts      STR_UNKNOWN_ERROR
          jmp       READEXIT
BYTE2PAR:
          mov       BP,OFFSET DTA_BUFFER
          mov       BX,DS:[BP+1AH]
          mov       AX,DS:[BP+1CH] 
          shr       BX,4          
          shl       AX,12         
          add       BX,AX         
          inc       BX             
          mov       AX,DS:[BP+1CH]
          and       AX,0FFF0H
          cmp       AX,0000H
          jz        REQ_MEM
          mov       READ_EXIT_CODE,1
          puts      STR_ERROR_8
          jmp       READEXIT  
REQ_MEM:
          mov       AH,48H
          int       21H
          jnc       READSAVE
          mov       READ_EXIT_CODE,1
          puts      STR_ERROR_8
          jmp       READEXIT
READSAVE: mov       OVERLAY_SEG,AX
          mov       OVR_SEG,AX        
          mov       RELOC_FACTOR,AX
READEXIT: pop       CX
          pop       DX
          pop       BX
          pop       AX
          pop       BP
          ret
READ_OVL   ENDP

LOAD_OVL   PROC      NEAR
          push      AX
          push      BX
          push      DX
          push      ES
          mov       DX,OFFSET FULLPATH  
          push      DS                 
          pop       ES                  
          mov       BX,OFFSET PARAM_BLOCK    
          mov       AX,4B03H            
          int       21H
          jc        LOAD_ERR
          puts      STR_LOADED
          call      DWORD PTR OVERLAY_ADDR
          jmp       LOADEXIT
LOAD_ERR: mov       LOAD_EXIT_CODE,1
          cmp       AX,01H
          jne       ERROR2
          puts      STR_ERROR_1
          jmp       LOADEXIT
ERROR2:   cmp       AX,02H
          jne       ERROR3
          puts      STR_ERROR_2
          jmp       LOADEXIT
ERROR3:   cmp       AX,03H
          jne       ERROR4
          puts      STR_ERROR_3
          jmp       LOADEXIT
ERROR4:   cmp       AX,04H
          jne       ERROR5
          puts      STR_ERROR_4
          jmp       LOADEXIT
ERROR5:   cmp       AX,05H
          jne       ERROR8
          puts      STR_ERROR_5
          jmp       LOADEXIT
ERROR8:   cmp       AX,08H
          jne       ERRORA
          puts      STR_ERROR_8
          jmp       LOADEXIT
ERRORA:   cmp       AX,0AH
          jne       UNERRLOAD
          puts      STR_ERROR_A
          jmp       LOADEXIT
UNERRLOAD:puts      STR_UNKNOWN_ERROR
LOADEXIT: pop       ES
          pop       DX
          pop       BX
          pop       AX
          ret
LOAD_OVL   ENDP

CLEAN_MEMORY  PROC      NEAR
          push      AX
          push      ES
          mov       AX,OVERLAY_SEG
          mov       ES,AX
          mov       AH,49H
          int       21H
          jc        CLEANERR
          puts      STR_CLEANED
          jmp       CLEANEXIT
CLEANERR: mov       CLEAN_EXIT_CODE,1
          puts      STR_CLEAN_ERROR
CLEANEXIT:pop       ES
          pop       AX
          ret
CLEAN_MEMORY  ENDP

MAIN      PROC      NEAR
          mov       AX,DATA
          mov       DS,AX
          call      FREE_MEMORY
          cmp       FREE_EXIT_CODE,0
          jne       NEXT
          MAKEPATH  FILE_OVL_1,FULLPATH
          mov       CX,1
          call      READ_OVL
          cmp       READ_EXIT_CODE,0
          jne       NEXT
          call      LOAD_OVL
          call      CLEAN_MEMORY
          cmp       LOAD_EXIT_CODE,0
          jne       NEXT
          cmp       CLEAN_EXIT_CODE,0
          jne       NEXT
		  
NEXT:	  MAKEPATH_2  FILE_OVL_2,FULLPATH
		  mov 		READ_EXIT_CODE,0
		  mov		LOAD_EXIT_CODE,0
		  mov		CLEAN_EXIT_CODE,0
          mov       CX,1
          call      READ_OVL
          cmp       READ_EXIT_CODE,0
          jne       EXIT
          call      LOAD_OVL
          call      CLEAN_MEMORY
          cmp       LOAD_EXIT_CODE,0
          jne       EXIT
          cmp       CLEAN_EXIT_CODE,0
          jne       EXIT
EXIT:     xor       AL,AL
          mov       AH,4CH
          int       21H
          ret
MAIN      ENDP
PROGEND:
CODE      ENDS

DATA      SEGMENT          
          STR_ERROR_1       DB   'ERROR: Invalid function number',0DH,0AH,'$'
          STR_ERROR_2       DB   'ERROR: File not found',0DH,0AH,'$'
          STR_ERROR_3       DB   'ERROR: Path not found',0DH,0AH,'$'
          STR_ERROR_4       DB   'Too many open files (no handles left)',0DH,0AH,'$'
          STR_ERROR_5       DB   'ERROR: Access denied',0DH,0AH,'$'
          STR_ERROR_7       DB   'ERROR: Memory control blocks destroyed',0DH,0AH,'$'
          STR_ERROR_8       DB   'ERROR: Insufficient memory',0DH,0AH,'$'
          STR_ERROR_9       DB   'ERROR: Invalid memory block address',0DH,0AH,'$'
          STR_ERROR_A       	DB   'ERROR: Invalid environment',0DH,0AH,'$'
          STR_UNKNOWN_ERROR     DB   'ERROR: Unknown',0DH,0AH,'$'       
          STR_CLEAN_ERROR     	DB   'ERROR: Cleaning NOT successful',0DH,0AH,'$'         
          STR_LOADED     		DB   'Overlay loaded successfully',0DH,0AH,'$'
          STR_CLEANED    		DB   'Memory cleaning successful',0DH,0AH,'$'
          FILE_OVL_1           	DB   'OVL1.OVL',0
		  FILE_OVL_2           	DB   'OVL2.OVL',0
          FULLPATH      DB   128 DUP (0)
          DTA_BUFFER     DB   43 DUP (0)
          PARAM_BLOCK    EQU  $    
          OVERLAY_SEG    DW   ?  
          RELOC_FACTOR   DW   ?    
          OVERLAY_ADDR   EQU  $ 
          OVR_OFFSET     	DW   0   
          OVR_SEG          	DW   ? 
          FREE_EXIT_CODE   	DB   0 
          READ_EXIT_CODE   	DB   0
          LOAD_EXIT_CODE   	DB   0
          CLEAN_EXIT_CODE  	DB   0
DATA      ENDS
          END       MAIN