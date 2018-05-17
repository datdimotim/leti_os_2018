CODE      SEGMENT
          ASSUME         CS:CODE, DS:NOTHING, SS:NOTHING, ES:NOTHING

OVERLAY   PROC      FAR
          push      AX
          push      DI
          push      DS
          mov       AX,CS
          mov       DS,AX
          mov       DI,OFFSET STR_ADDR + 32
          call      WORD2HEX
          call      PUT_ADDRESS
          pop       DS
          pop       DI
          pop       AX
          RETF   
OVERLAY   ENDP

PUT_ADDRESS   PROC      NEAR
          push      AX
          push      DX
          mov       DX,OFFSET STR_ADDR
          mov       AH,09H
          int       21H
          pop       DX
          pop       AX
          ret
PUT_ADDRESS   ENDP

TETR2HEX  PROC      NEAR
          and       AL,0FH
          cmp       AL,09
          JBE       NEXT
          add       AL,07
NEXT:     add       AL,30H
          ret
TETR2HEX  ENDP

BYTE2HEX  PROC      NEAR
          push      CX
          mov       AH,AL
          call      TETR2HEX
          XCHG      AL,AH
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

STR_ADDR  DB        'Overlay 2. segment address:      H',0DH,0AH,'$'
CODE      ENDS
          END       OVERLAY