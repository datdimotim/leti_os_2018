.286

ASTACK       SEGMENT   STACK
          DW 100 DUP (0)
ASTACK       ENDS

CODE      SEGMENT
          ASSUME         CS:CODE, DS:DATA, SS:ASTACK, ES:NOTHING

MAKEPATH  MACRO     FILE,PATH
          push      ES
          push      BX
          push      DX
          push      DI
          push      SI
          mov       ES,ES:[2Ch] ; в es сегментный адрес среды//
          xor       BX,BX
ZILK_1:	  mov       DX,ES:[BX]
          cmp       DX,0000h
          jz        READPATH
          add       BX, 1 ;//
          jmp       ZILK_1
READPATH: add       BX,4
          mov       DI,OFFSET PATH
PATH_ZIKL_1:   
		  mov       DL,ES:[BX]
          mov       [DI],DL
          inc       DI
          inc       BX
          cmp       DL,00h
          jnz       PATH_ZIKL_1
PATH_ZIKL_2: dec       DI
          mov       DL,[DI]
          cmp       DL,92  ; '\'  
          jne       PATH_ZIKL_2
          mov       SI,OFFSET FILE
; добавляем имя запускаемой программы
PUTNAME: 	
		  inc       DI
          mov       DL,[SI]
          mov       [DI],DL
          inc       SI
          cmp       DL,00h
          jnz       PUTNAME       
          pop       SI
          pop       DI
          pop       DX
          pop       BX
          pop       ES
          ENDM
print      MACRO     STRING
          push      AX
          push      DX
          mov       DX,OFFSET STRING
          mov       AH,09h
          int       21h
          pop       DX
          pop       AX
          ENDM      
		  
MAKEPATH_2  MACRO     FILE_2,PATH
          push      ES
          push      BX
          push      DX
          push      DI
          push      SI
          mov       ES,ES:[2Ch]
          xor       BX,BX
ZILK_2_1:
		  mov       DX,ES:[BX]
          cmp       DX,0000h
          jz        READPATH_2
          inc       BX
          jmp       ZILK_2_1
READPATH_2: 
	      add       BX,4
          mov       DI,OFFSET PATH
PATH_ZIKL_2_1: 
          mov       DL,ES:[BX]
          mov       [DI],DL
          inc       DI
          inc       BX
          cmp       DL,00H
          jnz       PATH_ZIKL_2_1
PATH_ZIKL_2_2: 
          dec       DI
          mov       DL,[DI]
          cmp       DL,92    
          jne       PATH_ZIKL_2_2
          mov       SI,OFFSET FILE_2
PUTNAME_2: 
          inc       DI
          mov       DL,[SI]
          mov       [DI],DL
          inc       SI
          cmp       DL,00h
          jnz       PUTNAME_2       
          pop       SI
          pop       DI
          pop       DX
          pop       BX
          pop       ES
          ENDM
  		  
FREE_MEM   PROC      NEAR
          push      BX
          push      AX
          mov       BX,OFFSET PROGEND
          mov       AH,4Ah
          int       21h
          jnc       FREE_MEM_EXIT
          mov       FREE_EXIT_CODE,1
          cmp       AX,07h
          jne       TESTERR8
          print     STR_ERROR_7
          jmp       FREE_MEM_EXIT
TESTERR8: cmp       AX,08h
          jne       TESTERR9
          print     STR_ERROR_8
          jmp       FREE_MEM_EXIT
TESTERR9: cmp       AX,09h
          jne       UNERRFREE
          print     STR_ERROR_9
          jmp       FREE_MEM_EXIT
UNERRFREE:print     STR_UNKNOWN_ERROR
FREE_MEM_EXIT: 
		  pop       AX
          pop       BX
          ret
FREE_MEM   ENDP

READ_OVL  PROC      NEAR
          push      BP
          push      AX
          push      BX
          push      DX
          push      CX
          mov       AH,1Ah
          mov       DX,OFFSET DTA_BUFFER
          int       21h
          mov       AH,4Eh
          mov       DX,OFFSET FULLPATH
          mov       CX,0
          int       21h
          jnc       BYTE_TO_PAR
          mov       READ_EXIT_CODE,1
          cmp       AX,12h
          jne       TESTERR3
          print     STR_ERROR_2
          jmp       READEXIT
TESTERR3: cmp       AX,02h
          jne       UNERRREAD
          print     STR_ERROR_3
          jmp       READEXIT
UNERRREAD:print     STR_UNKNOWN_ERROR
          jmp       READEXIT
BYTE_TO_PAR:
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
          print      STR_ERROR_8
          jmp       READEXIT  
REQ_MEM:
          mov       AH,48h
          int       21h
          jnc       READSAVE
          mov       READ_EXIT_CODE,1
          print     STR_ERROR_8
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
          mov       AX,4B03h            
          int       21h
          jc        LOAD_ERR
          print     STR_LOADED
          call      DWORD PTR OVERLAY_ADDR
          jmp       LOADEXIT
LOAD_ERR: mov       LOAD_EXIT_CODE,1
          cmp       AX,01h
          jne       ERROR2
          print     STR_ERROR_1
          jmp       LOADEXIT
ERROR2:   cmp       AX,02h
          jne       ERROR3
          print     STR_ERROR_2
          jmp       LOADEXIT
ERROR3:   cmp       AX,03h
          jne       ERROR4
          print     STR_ERROR_3
          jmp       LOADEXIT
ERROR4:   cmp       AX,04h
          jne       ERROR5
          print     STR_ERROR_4
          jmp       LOADEXIT
ERROR5:   cmp       AX,05h
          jne       ERROR8
          print     STR_ERROR_5
          jmp       LOADEXIT
ERROR8:   cmp       AX,08h
          jne       ERRORA
          print     STR_ERROR_8
          jmp       LOADEXIT
ERRORA:   cmp       AX,0Ah
          jne       UNERRLOAD
          print     STR_ERROR_A
          jmp       LOADEXIT
UNERRLOAD:print     STR_UNKNOWN_ERROR
LOADEXIT: pop       ES
          pop       DX
          pop       BX
          pop       AX
          ret
LOAD_OVL   ENDP

CLEAN_MEM  PROC      NEAR
          push      AX
          push      ES
          mov       AX,OVERLAY_SEG
          mov       ES,AX
          mov       AH,49h
          int       21h
          jc        CLEANERR
          print     STR_CLEANED
          jmp       CLEANEXIT
CLEANERR: mov       CLEAN_EXIT_CODE,1
          print     STR_CLEAN_ERROR
CLEANEXIT:pop       ES
          pop       AX
          ret
CLEAN_MEM  ENDP

MAIN      PROC      NEAR
          mov       AX,DATA
          mov       DS,AX
          call      FREE_MEM
          cmp       FREE_EXIT_CODE,0
          jne       NEXT
          MAKEPATH  FILE_OVL_1,FULLPATH
          mov       CX,1
          call      READ_OVL
          cmp       READ_EXIT_CODE,0
          jne       NEXT
          call      LOAD_OVL
          call      CLEAN_MEM
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
          call      CLEAN_MEM
          cmp       LOAD_EXIT_CODE,0
          jne       EXIT
          cmp       CLEAN_EXIT_CODE,0
          jne       EXIT
EXIT:     xor       AL,AL
          mov       AH,4Ch
          int       21h
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