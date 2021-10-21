TITLE: OFFLINE A2

.MODEL SMALL
.STACK 100H
.DATA

CR EQU 0DH;
LF EQU 0AH;

INPT DB ?;
NUM DW ?;
SUM DW 0;

;TEMP STORAGE FOR SI, DI
S1 DW ?;
D1 DW ?;

;DIGIT EXTRACTION VARS
B10 DW 10000, 1000, 100, 10, 1;
LEFTP DB ?;

.CODE

MAIN PROC
    ;INITIALIZING DATA SEGMENT
    MOV AX,@DATA;
    MOV DS,AX;
    
    
PROG_LOOP:  ;PROGRAM LOOPING
    
    MOV CX,0;
    MOV SUM,0;
    
DIGIT1_INPUT:
    MOV AH,1;
    INT 21H;
    SUB AL,'0';
    MOV AH,0;
    ADD CX,AX;

DIGIT_INPUT:      
    MOV AH,1;
    INT 21H;
    CMP AL,CR;
    
    JE INPUT_DONE;
    
    ;CX *= 10;
    MOV INPT,AL;    
    MOV AX,10D;
    MUL CX;
    MOV CX,AX;
    
    ;CX += DIGIT
    MOV AL, INPT;
    SUB AL,'0';
    MOV AH,0;
    ADD CX, AX;
    
    JMP DIGIT_INPUT;


INPUT_DONE:
    
    ;[TERMINATE IF CX IS ZERO]
    CMP CX,0;
    JE END_PROG; 
    
    MOV NUM,CX;
    
    MOV SI,1;
    
LOOP_SI:
    
    CMP SI,NUM;
    JGE END_LOOP_SI; 
    
    ;DI = SI + 1
    ADD SI,1;
    MOV DI,SI;
    SUB SI,1;
        
LOOP_DI:
    
    CMP DI,NUM;
    JG END_LOOP_DI;
    
    MOV S1,SI;
    MOV D1,DI;
    
    JMP ADD_GCD;
    
GCD_ADDED:

    MOV SI,S1;
    MOV DI,D1;        
    
    ADD DI,1;
    JMP LOOP_DI; 
    
END_LOOP_DI:
    
    ADD SI,1;
    JMP LOOP_SI;
        
    
END_LOOP_SI:


;[GCD CALCULATION]

JMP SKIP_GCD_PART;    

ADD_GCD:

    CMP SI,DI;
    JGE GCD_NO_SWAP;
    
    ;SWAP IF SI < DI
    XCHG SI,DI; 
    
GCD_NO_SWAP:
    
    CMP DI,0;
    JE GCD_ADDING;  GCD IS SI
    
    ;(SI,DI) -> (SI%DI,DI)
    MOV DX,0;
    MOV AX,SI;
    
    DIV DI;
    MOV SI,DX;
    JMP ADD_GCD;
    
    
;[ADDING THE GCD]

JMP SKIP_GCD_PART;        

GCD_ADDING:

    ADD SUM,SI;
    JMP GCD_ADDED;    

SKIP_GCD_PART:    

;PRINTING THE SUM

    ;GET TO NEW LINE
    MOV AH,2;
    MOV DL,LF;
    INT 21H;
    MOV DL,CR;
    INT 21H;
    
    
    MOV LEFTP,0;
    MOV SI,0;

GET_DIGIT:

    CMP SI,8;
    JG PRINT_FINAL;
    
    MOV DX,0;
    MOV AX,SUM;
    DIV B10+SI;
    
    ;[QUOTIENT IN AX]
    
    MOV DX,0;
    MOV BX,10;
    DIV BX;
    MOV AX,DX;
    ;[REMAINDER IN AX] 
    
    ADD SI,2;
    
    ;CHECK IF DIGIT IS ZERO AND LEFTMOST
    CMP AX,0;
    JNE PRINT_DIGIT;
    
    CMP LEFTP,0;
    JNE PRINT_DIGIT;
    
    JMP GET_DIGIT;  
    
    
PRINT_DIGIT:
    
    MOV LEFTP,1;
    
    ADD AL,48;
    ;[REMAINDER AS CHAR IN AL, AH = 0]
    
    ;PRINT DIGIT
    MOV DL,AL;
    MOV AH,2;
    INT 21H;
    
    JMP GET_DIGIT;

PRINT_FINAL:
    
	;IF NOTHING PRINTED, PRINT 0
	CMP LEFTP,0;
	JNE PRINT_DONE;
	
	MOV DL,48;
    MOV AH,2;
    INT 21H;

PRINT_DONE:
    
    ;NEW LINE
    MOV AH,2
    MOV DL,LF;
    INT 21H;
    
    MOV DL, CR;
    INT 21H;
    
;LOOPING THE PROGRAM    

JMP PROG_LOOP;

END_PROG:    
    
MAIN ENDP

END MAIN