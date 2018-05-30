.286

ASTACK       SEGMENT   STACK
          DW 100 DUP (0)
ASTACK       ENDS

DATA      SEGMENT          
          ERROR_INVLD_NUM_FUN       DB   'Invalid function number!',0DH,0AH,'$'
          ERROR_FILE_NOT_FOUND       DB   'File not found!',0DH,0AH,'$'
          ERROR_PATH_NOT_FOUND       DB   'Path not found!',0DH,0AH,'$'
          ERROR_A_LOT_OPEN_FILES       DB   'Too many open files (no handles left)!',0DH,0AH,'$'
          ERROR_ACCESS_DENIED       DB   'Access denied!',0DH,0AH,'$'
          ERROR_MCB_DESTRYOED       DB   'MCB destroyed!',0DH,0AH,'$'
          ERROR_INSUFFICIENT_MEM       DB   'Insufficient memory',0DH,0AH,'$'
          ERROR_INVLD_MEM_ADDR       DB   'Invalid memory block address',0DH,0AH,'$'
          ERROR_INVLD_ENV       	DB   'Invalid environment',0DH,0AH,'$'
          ERROR_UNKNOWN     DB   'Unknown',0DH,0AH,'$'       
          ERROR_CLEANING_SMTHN_WRNG     	DB   'Cleaning not successful',0DH,0AH,'$'         
          OVERLAY_LOADED     		DB   'Overlay loaded!',0DH,0AH,'$'
          MEM_CLEANED    		DB   'Memory cleaning...',0DH,0AH,'$'
          FILE_OVL_1           	DB   'OVL1.OVL',0
		  FILE_OVL_2           	DB   'OVL2.OVL',0
          FULLPATH      DB   128 DUP (0)
          DTA_BUFFER     DB   43 DUP (0)
          PARAMETR_BLOCK    EQU  $    
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

CODE      SEGMENT
          ASSUME         CS:CODE, DS:DATA, SS:ASTACK, ES:NOTHING

PREPARE_PATH  MACRO     FILE,PATH
          push      ES
          push      BX
          push      DX
          push      DI
          push      SI
          mov       ES,ES:[2Ch] 
          xor       BX,BX
CYCLE_1:	  mov       DX,ES:[BX]
          cmp       DX,0000h
          jz        READPATH
          add       BX, 1 ;//
          jmp       CYCLE_1
READPATH: add       BX,4
          mov       DI,OFFSET PATH
PATH_CYCLE_1:   
		  mov       DL,ES:[BX]
          mov       [DI],DL
          inc       DI
          inc       BX
          cmp       DL,00h
          jnz       PATH_CYCLE_1
PATH_CYCLE_2: dec       DI
          mov       DL,[DI]
          cmp       DL,92  ; '\'  
          jne       PATH_CYCLE_2
          mov       SI,OFFSET FILE

GET_NAME: 	
		  inc       DI
          mov       DL,[SI]
          mov       [DI],DL
          inc       SI
          cmp       DL,00h
          jnz       GET_NAME       
          pop       SI
          pop       DI
          pop       DX
          pop       BX
          pop       ES
          ENDM
PRINT_STR      MACRO     STRING
          push      AX
          push      DX
          mov       DX,OFFSET STRING
          mov       AH,09h
          int       21h
          pop       DX
          pop       AX
          ENDM      
		  
PREPARE_PATH_2  MACRO     FILE_2,PATH
          push      ES
          push      BX
          push      DX
          push      DI
          push      SI
          mov       ES,ES:[2Ch]
          xor       BX,BX
CYCLE_2:
		  mov       DX,ES:[BX]
          cmp       DX,0000h
          jz        READPATH_2
          inc       BX
          jmp       CYCLE_2
READPATH_2: 
	      add       BX,4
          mov       DI,OFFSET PATH
PATH_CYCLE_3: 
          mov       DL,ES:[BX]
          mov       [DI],DL
          inc       DI
          inc       BX
          cmp       DL,00H
          jnz       PATH_CYCLE_3
PATH_CYCLE_4: 
          dec       DI
          mov       DL,[DI]
          cmp       DL,92    
          jne       PATH_CYCLE_4
          mov       SI,OFFSET FILE_2
GET_NAME_2: 
          inc       DI
          mov       DL,[SI]
          mov       [DI],DL
          inc       SI
          cmp       DL,00h
          jnz       GET_NAME_2       
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
          jne       LOOP_1
          PRINT_STR     ERROR_MCB_DESTRYOED
          jmp       FREE_MEM_EXIT
LOOP_1: cmp       AX,08h
          jne       LOOP_2
          PRINT_STR     ERROR_INSUFFICIENT_MEM
          jmp       FREE_MEM_EXIT
LOOP_2: cmp       AX,09h
          jne       UNERRFREE
          PRINT_STR     ERROR_INVLD_MEM_ADDR
          jmp       FREE_MEM_EXIT
UNERRFREE:PRINT_STR     ERROR_UNKNOWN
FREE_MEM_EXIT: 
		  pop       AX
          pop       BX
          ret
FREE_MEM   ENDP

READ_SIZE_OF_OVL  PROC      NEAR
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
          jne       LOOP_3
          PRINT_STR     ERROR_FILE_NOT_FOUND
          jmp       READEXIT
LOOP_3: cmp       AX,02h
          jne       UNERRREAD
          PRINT_STR     ERROR_PATH_NOT_FOUND
          jmp       READEXIT
UNERRREAD:PRINT_STR     ERROR_UNKNOWN
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
          PRINT_STR      ERROR_INSUFFICIENT_MEM
          jmp       READEXIT  
REQ_MEM:
          mov       AH,48h
          int       21h
          jnc       READSAVE
          mov       READ_EXIT_CODE,1
          PRINT_STR     ERROR_INSUFFICIENT_MEM
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
READ_SIZE_OF_OVL   ENDP

LOAD_OVL   PROC      NEAR
          push      AX
          push      BX
          push      DX
          push      ES
          mov       DX,OFFSET FULLPATH  
          push      DS                 
          pop       ES                  
          mov       BX,OFFSET PARAMETR_BLOCK    
          mov       AX,4B03h            
          int       21h
          jc        LOAD_ERR
          PRINT_STR     OVERLAY_LOADED
          call      DWORD PTR OVERLAY_ADDR
          jmp       LOADEXIT
LOAD_ERR: mov       LOAD_EXIT_CODE,1
          cmp       AX,01h
          jne       ERR_NOT_FOUND_FILE
          PRINT_STR     ERROR_INVLD_NUM_FUN
          jmp       LOADEXIT
ERR_NOT_FOUND_FILE:   cmp       AX,02h
          jne       ERR_NOT_FOUND_PATH
          PRINT_STR     ERROR_FILE_NOT_FOUND
          jmp       LOADEXIT
ERR_NOT_FOUND_PATH:   cmp       AX,03h
          jne       ERR_MANY_FILES
          PRINT_STR     ERROR_PATH_NOT_FOUND
          jmp       LOADEXIT
ERR_MANY_FILES:   cmp       AX,04h
          jne       ERR_ACCESS_DENIED
          PRINT_STR     ERROR_A_LOT_OPEN_FILES
          jmp       LOADEXIT
ERR_ACCESS_DENIED:   cmp       AX,05h
          jne       ERR_INSUF_MEM
          PRINT_STR     ERROR_ACCESS_DENIED
          jmp       LOADEXIT
ERR_INSUF_MEM:   cmp       AX,08h
          jne       ERR_INVLD_ENV
          PRINT_STR     ERROR_INSUFFICIENT_MEM
          jmp       LOADEXIT
ERR_INVLD_ENV:   cmp       AX,0Ah
          jne       UNERRLOAD
          PRINT_STR     ERROR_INVLD_ENV
          jmp       LOADEXIT
UNERRLOAD:PRINT_STR     ERROR_UNKNOWN
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
          PRINT_STR     MEM_CLEANED
          jmp       CLEANEXIT
CLEANERR: mov       CLEAN_EXIT_CODE,1
          PRINT_STR     ERROR_CLEANING_SMTHN_WRNG
CLEANEXIT:pop       ES
          pop       AX
          ret
CLEAN_MEM  ENDP

BEGIN      PROC      NEAR
          mov       AX,DATA
          mov       DS,AX
          call      FREE_MEM
          cmp       FREE_EXIT_CODE,0
          jne       NEXT
          PREPARE_PATH  FILE_OVL_1,FULLPATH
          mov       CX,1
          call      READ_SIZE_OF_OVL
          cmp       READ_EXIT_CODE,0
          jne       NEXT
          call      LOAD_OVL
          call      CLEAN_MEM
          cmp       LOAD_EXIT_CODE,0
          jne       NEXT
          cmp       CLEAN_EXIT_CODE,0
          jne       NEXT
		  
NEXT:	  PREPARE_PATH_2  FILE_OVL_2,FULLPATH
		  mov 		READ_EXIT_CODE,0
		  mov		LOAD_EXIT_CODE,0
		  mov		CLEAN_EXIT_CODE,0
          mov       CX,1
          call      READ_SIZE_OF_OVL
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
BEGIN      ENDP
PROGEND:
CODE      ENDS

          END       BEGIN