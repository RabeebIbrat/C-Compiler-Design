TITLE: 1605055_COMPILER_GENERATED_ASM

.MODEL SMALL
.STACK 100H
.DATA

x_Scope1 DW ?;
y_Scope1 DW ?;
z_Scope1 DW ?;
a_Scope1 DW ?;
a_Scope2 DW ?;
b_Scope2 DW ?;
a_Scope4 DW 2 DUP (?)
c_Scope4 DW ?;
i_Scope4 DW ?;
j_Scope4 DW ?;
d_Scope4 DW ?;

temp_1 DW ?;
temp_2 DW ?;
temp_3 DW ?;
temp_4 DW ?;
temp_5 DW ?;

argList DW 100 DUP (?)
return_X DW ?;

B10 DW 10000, 1000, 100, 10, 1;
LEFTP DB ?;
NUMBER DW ?;
CR EQU 0DH;
LF EQU 0AH;

.CODE

CALL main;

PRINT_NUMBER PROC

MOV LEFTP,0;
MOV SI,0;

GET_DIGIT:

CMP SI,8;
JG PRINT_FINAL;

MOV DX,0;
MOV AX,NUMBER;
DIV B10+SI;

MOV DX,0;
MOV BX,10;
DIV BX;
MOV AX,DX;
ADD SI,2;

CMP AX,0;
JNE PRINT_DIGIT;

CMP LEFTP,0;
JNE PRINT_DIGIT;

JMP GET_DIGIT;

PRINT_DIGIT:

MOV LEFTP,1;

ADD AL,48;
MOV DL,AL;
MOV AH,2;
INT 21H;

JMP GET_DIGIT;

PRINT_FINAL:

CMP LEFTP,0;
JNE PRINT_DONE;

MOV DL,48;
MOV AH,2;
INT 21H;

PRINT_DONE:

MOV AH,2
MOV DL,LF;
INT 21H;

MOV DL, CR;
INT 21H;

RET

PRINT_NUMBER ENDP


var PROC

PUSH a_Scope2;
PUSH b_Scope2;

MOV AX,argList[0];
MOV a_Scope2,AX;
MOV AX,argList[2];
MOV b_Scope2,AX;

MOV AX,temp_1;
MOV return_X,AX;

POP b_Scope2;
POP a_Scope2;

var ENDP


foo PROC


MOV x_Scope1,2;

MOV AX,x_Scope1;
SUB AX,5;
MOV temp_2,AX;

MOV AX,temp_2;
MOV y_Scope1,AX;



foo ENDP


main PROC

MOV AX,@DATA;
MOV DS,AX;
MOV a_Scope4[0],1;

MOV a_Scope4[2],5;

MOV AX,a_Scope4[0];
ADD AX,a_Scope4[2];
MOV temp_3,AX;

MOV AX,temp_3;
MOV i_Scope4,AX;

MOV i_Scope4,0;


START_FOR_LABEL_2:

MOV AX,i_Scope4;
CMP AX,7;
JL REL_TRUE_LABEL_1;

MOV temp_4,0;
JMP REL_OP_DONE_LABEL_1;

REL_TRUE_LABEL_1:

MOV temp_4,1;

REL_OP_DONE_LABEL_1:


CMP temp_4,0;
JE END_FOR_LABEL_2;


MOV AX,i_Scope4;
MOV temp_5,AX;
INC i_Scope4;


JMP START_FOR_LABEL_2;

END_FOR_LABEL_2:

MOV AX,i_Scope4;
MOV NUMBER, AX;
CALL PRINT_NUMBER
MOV return_X,AX;


main ENDP

