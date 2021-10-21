%{
#include <iostream>
#include <cstdlib>
#include <cstring>
#include <cmath>
#include <string>
#include <deque>
#include "sync.h"
#include "symbol_table.h"
#define YYSTYPE Sync*

using namespace std;

string tempVarName = "temp_";  //name for temporary variables
string returnVar = "return_X";  //variable for storing function return value
string arg_array = "argList";  //array for function argument passing
int arg_max = 100;  //function argument max size
string labelSuffix = "_LABEL_";  //suffix to be added at the end of a label
string scopeText = "_Scope";  //text for scope in variable name
//string scopeTextF = "_SCOPE";  //text for scope in function label
string data_reg = "AX";  //register used for temporary data storage
string data_reg_2 = "BX";  //register used for temporary data storage
string mulop_reg = "BX";  //register used for temporary data storage during multiplication and division <THIS CANNOT BE AX or DX>
string index_reg = "SI";  //register used for array indexing
string index_reg_2 = "DI";  //register used for array indexing
bool comments = false;  //comment flag for asm code
bool asmDebug = true;  //decides if asmFolder for debugging will be created

FILE *fpsrc, *fplog, *fperr;

int yyparse(void);
int yylex(void);
extern FILE *yyin;

extern int line_count;
int error_count = 0;

int labelCount=0;
int tempCount=0;

string newTemp() {
	tempCount++;
	return ( tempVarName + to_string(tempCount) );
}

string newLabel() {
	labelCount++;
	return ( labelSuffix + to_string(labelCount) );
}

bool isNumber(string name) {
	char start = name.c_str()[0];
	if(start <= '9' && start >= '0')
		return true;
	else
		return false;
}

int bucketSize = 50;
SymbolTable *table = new SymbolTable(bucketSize);
//bool skipEnterScope = false;

deque<string> *func_type_list = NULL;
deque<string> *func_name_list = NULL;

deque<string> *asm_var_list = new deque<string>;
deque<int> *asm_var_size_list = new deque<int>;
deque<string> *asm_var_stack = new deque<string>;
string paramCode = "";  //for parameter receiving code in function body
int arg_counter = 0;  //counts arguments and helps sending them before function calling

void asmVarPrint(Sync* src, string fileName) {
	if(asmDebug) {
		if(src->varIndex == "<none>")
			src->printAsm(fileName, line_count, "variable usage: " + src->varName + "\n");
		else
			src->printAsm(fileName, line_count, "variable usage: " + src->varName + "\n"
						+ "variable index: " + src->varIndex + "\n");
	}
}

void asmPrint(Sync* src, string fileName) {
	if(asmDebug) {
		src->printAsm(fileName, line_count);
		asmVarPrint(src,fileName);
	}
}

void yyerror(char *s)
{
	//write your code
}

%}

%token CONST_DOUBLE CONST_CHAR CONST_INT CONST_FLOAT
%token VOID INT FLOAT CHAR DOUBLE ID
%token RETURN MAIN PRINTLN
%token ADDOP MULOP INCOP DECOP
%token ASSIGNOP RELOP LOGICOP NOT
%token LPAREN RPAREN LCURL RCURL LTHIRD RTHIRD
%token IF ELSE FOR WHILE
%token COMMA SEMICOLON


%%

start : program
	{
		fprintf(fplog,"\t\tsymbol table:\n\n");
		table->printAllScopeTable(fplog);
		
		fprintf(fperr, "Total errors: %d", error_count);
		
		//ASM PART
		$$ = new Sync("");
		$$->asmCode += "TITLE: 1605055_COMPILER_GENERATED_ASM\n\n";
		
		$$->asmCode += ".MODEL SMALL\n";
		$$->asmCode += ".STACK 100H\n";
		$$->asmCode += ".DATA\n\n";
		
		if(comments)  $$->asmCode += ";DECLARED VARIABLES IN C CODE\n";
		
		//DECLARED VARIABLES IN C CODE
		while(!asm_var_list->empty()) {
			string varName = asm_var_list->front();
			asm_var_list->pop_front();
			int size = asm_var_size_list->front();
			asm_var_size_list->pop_front();
			if(size < 0)
				$$->asmCode += varName + " DW ?;\n";
			else {
				$$->asmCode += varName + " DW " + to_string(size) + " DUP (?)\n";
			}
		}
		$$->asmCode += "\n";
		
		if(comments)  $$->asmCode += ";TEMPORARY VARIABLES IN ASSEMBLY CODE\n";
		
		//TEMPORARY VARIABLES IN ASSEMBLY CODE
		for(int i = 1; i <= tempCount; i++) {
			$$->asmCode += tempVarName + to_string(i) + " DW ?;\n";
		}
		$$->asmCode += "\n";
		
		if(comments) $$->asmCode += ";ARGUMENT ARRAY RETURN VARIABLE FOR PROCEDURE\n";
		$$->asmCode += arg_array + " DW " + to_string(arg_max) + " DUP (?)\n";
		$$->asmCode += returnVar + " DW ?;\n";
		$$->asmCode += "\n";
		
		if(comments) $$->asmCode += ";DIGIT EXTRACTION VARS\n";
		$$->asmCode += "B10 DW 10000, 1000, 100, 10, 1;\n";
		$$->asmCode += "LEFTP DB ?;\n";
		$$->asmCode += "NUMBER DW ?;\n";
		$$->asmCode += "CR EQU 0DH;\n";
		$$->asmCode += "LF EQU 0AH;\n";
		$$->asmCode += "\n";
		
		$$->asmCode += ".CODE\n\n";
		
		$$->asmCode += "CALL main;\n\n";
		
		//HARDCODED PRINT FUNCTION
		
		$$->asmCode += "PRINT_NUMBER PROC\n\n";

		if(comments) $$->asmCode += ";PRINTING THE NUMBER\n\n";

		$$->asmCode += "MOV LEFTP,0;\n";
		$$->asmCode += "MOV SI,0;\n\n";

		$$->asmCode += "GET_DIGIT:\n\n";

		$$->asmCode += "CMP SI,8;\n";
		$$->asmCode += "JG PRINT_FINAL;\n\n";

		$$->asmCode += "MOV DX,0;\n";
		$$->asmCode += "MOV AX,NUMBER;\n";
		$$->asmCode += "DIV B10+SI;\n\n";

		if(comments) $$->asmCode += ";[QUOTIENT IN AX]\n\n";

		$$->asmCode += "MOV DX,0;\n";
		$$->asmCode += "MOV BX,10;\n";
		$$->asmCode += "DIV BX;\n";
		$$->asmCode += "MOV AX,DX;\n";
		if(comments) $$->asmCode += ";[REMAINDER IN AX]\n\n";

		$$->asmCode += "ADD SI,2;\n\n";

		if(comments) $$->asmCode += ";CHECK IF DIGIT IS ZERO AND LEFTMOST\n";
		$$->asmCode += "CMP AX,0;\n";
		$$->asmCode += "JNE PRINT_DIGIT;\n\n";

		$$->asmCode += "CMP LEFTP,0;\n";
		$$->asmCode += "JNE PRINT_DIGIT;\n\n";

		$$->asmCode += "JMP GET_DIGIT;\n\n";


		$$->asmCode += "PRINT_DIGIT:\n\n";

		$$->asmCode += "MOV LEFTP,1;\n\n";

		$$->asmCode += "ADD AL,48;\n";
		if(comments) $$->asmCode += ";[REMAINDER AS CHAR IN AL, AH = 0]\n\n";

		if(comments) $$->asmCode += ";PRINT DIGIT\n";
		$$->asmCode += "MOV DL,AL;\n";
		$$->asmCode += "MOV AH,2;\n";
		$$->asmCode += "INT 21H;\n\n";

		$$->asmCode += "JMP GET_DIGIT;\n\n";

		$$->asmCode += "PRINT_FINAL:\n\n";

		if(comments) $$->asmCode += ";IF NOTHING PRINTED, PRINT 0\n";
		$$->asmCode += "CMP LEFTP,0;\n";
		$$->asmCode += "JNE PRINT_DONE;\n\n";

		$$->asmCode += "MOV DL,48;\n";
		$$->asmCode += "MOV AH,2;\n";
		$$->asmCode += "INT 21H;\n\n";

		$$->asmCode += "PRINT_DONE:\n\n";

		if(comments) $$->asmCode += ";NEW LINE\n";
		$$->asmCode += "MOV AH,2\n";
		$$->asmCode += "MOV DL,LF;\n";
		$$->asmCode += "INT 21H;\n\n";

		$$->asmCode += "MOV DL, CR;\n";
		$$->asmCode += "INT 21H;\n\n";

		if(comments) $$->asmCode += ";RETURNING\n";
		$$->asmCode += "RET\n\n";

		$$->asmCode += "PRINT_NUMBER ENDP\n\n";
		
		//---------------
		
		$$->asmCode += $1->asmCode;
		if(asmDebug) $$->printAsm("start", line_count);
		
		//FINAL PRINT
		$$->printFinalAsm("prog");
	}
	;

program : program unit 
	{
		$$ = new Sync("");
		$$->output = $1->output + "\n" + $2->output;
		fprintf(fplog, "At line no: %d program : program unit\n\n", line_count);
		fprintf(fplog, "%s\n\n", $$->output.c_str());
		
		//ASM PART
		$$->asmCode = $1->asmCode + $2->asmCode;
		if(asmDebug)  $$->printAsm("program", line_count);
	}
	| unit
	{
		$$ = new Sync("");
		$$->output = $1->output;
		fprintf(fplog, "At line no: %d program : unit\n\n", line_count);
		fprintf(fplog, "%s\n\n", $$->output.c_str());
		
		//ASM PART
		$$->asmCode = $1->asmCode;
		if(asmDebug)  $$->printAsm("program", line_count);
	}
	;
	
unit : var_declaration
		{
			$$ = new Sync("");
			$$->output = $1->output;
			fprintf(fplog, "At line no: %d unit : var_declaration\n\n", line_count);
			fprintf(fplog, "%s\n\n", $$->output.c_str());
			
		}
		| func_declaration
		{
			$$ = new Sync("");
			$$->output = $1->output;
			fprintf(fplog, "At line no: %d unit : func_declaration\n\n", line_count);
			fprintf(fplog, "%s\n\n", $$->output.c_str());
		}
		| func_definition
		{
			$$ = new Sync("");
			$$->output = $1->output;
			fprintf(fplog, "At line no: %d unit : func_definition\n\n", line_count);
			fprintf(fplog, "%s\n\n", $$->output.c_str());
			
			//ASM PART
			$$->asmCode = $1->asmCode;
			if(asmDebug)  $$->printAsm("unit", line_count);
		}
		| compound_statement
		{
			$$ = new Sync("");
			$$->output = $1->output;
			fprintf(fplog, "At line no: %d unit : compound_statement\n\n", line_count);
			fprintf(fplog, "%s\n\n", $$->output.c_str());
			
			//ASM PART
			$$->asmCode = $1->asmCode;
			if(asmDebug)  $$->printAsm("unit", line_count);
		}
     ;
     
func_declaration : type_specifier ID LPAREN parameter_list RPAREN SEMICOLON
		{
			$$ = $4;
			if(!$$->declareFunc($1->var_type,$2->output,table)) {
				fprintf(fperr,"Error at line %d: Multiple declaration of %s\n\n", line_count, $2->output.c_str());
				error_count++;
			}
			if(!$$->paramExists->empty()) {
				string exists;
				while(!$$->paramExists->empty()) {
					exists = $$->paramExists->front();
					$$->paramExists->pop_front();
					fprintf(fperr,"Error at line %d: Multiple usage of %s as argument of function %s\n\n", line_count, $2->output.c_str());
					error_count++;
				}
			}
			$$->output = $1->output + " " + $2->output + $3->output + $4->output + $5->output +  $6->output;
			fprintf(fplog, "At line no: %d func_declaration : type_specifier ID LPAREN parameter_list RPAREN SEMICOLON\n\n", line_count);
			fprintf(fplog, "%s\n\n", $$->output.c_str());
		}
		| type_specifier ID LPAREN RPAREN SEMICOLON
		{
			//COMMENT: Compulsory new Sync
			$$ = new Sync("");
			if(!$$->declareFunc($1->var_type,$2->output,table)) {
				fprintf(fperr,"Error at line %d: Multiple declaration of %s\n\n", line_count, $2->output.c_str());
				error_count++;
			}
			$$->output = $1->output + " " + $2->output + $3->output + $4->output + $5->output;
			fprintf(fplog, "At line no: %d func_declaration : type_specifier ID LPAREN RPAREN SEMICOLON\n\n", line_count);
			fprintf(fplog, "%s\n\n", $$->output.c_str());
		}
		;
		 
func_definition : type_specifier ID LPAREN parameter_list RPAREN 
		{
			//ASM PART
			paramCode = "";
			if(comments) paramCode += ";FUNCTION ARGUMENTS RECEIVING\n";
			int i = 0;
			int scopeId = table->getCurrentScopeId() + 1;
			for(deque<string>::iterator it = $4->name_list->begin(); it != $4->name_list->end(); it++, i+=2) {
				string varName = *it + scopeText + to_string(scopeId);
				paramCode += "MOV AX," + arg_array + "[" + to_string(i) + "]" + ";\n";
				paramCode += "MOV " + varName + "," + "AX;\n";
			}
			paramCode += "\n";
			//---------------
			
			$$ = $4;
			functionState state = $$->defineFuncTop($1->var_type, $2->output, table);
			switch(state) {
			case functionState::mulDeclare:
				fprintf(fperr,"Error at line %d: Multiple declaration of %s\n\n", line_count, $2->output.c_str());
				error_count++;
				break;
			case functionState::mulDef:
				fprintf(fperr,"Error at line %d: Multiple definition of %s\n\n", line_count, $2->output.c_str());
				error_count++;
				break;
			case functionState::manyLessArgs:
				fprintf(fperr,"Error at line %d: Too many or too less arguments for function %s\n\n", line_count, $2->output.c_str());
				error_count++;
				break;
			case functionState::unmatchedArgs:
				fprintf(fperr,"Error at line %d: Argument mismatch for function %s\n\n", line_count, $2->output.c_str());
				error_count++;
				break;
			}
			if(!$$->paramExists->empty()) {
				string exists;
				while(!$$->paramExists->empty()) {
					exists = $$->paramExists->front();
					$$->paramExists->pop_front();
					fprintf(fperr,"Error at line %d: Multiple usage of %s as argument of function %s\n\n", line_count, $2->output.c_str());
					error_count++;
				}
			}
			if($$->unnamed_parameter) {
				fprintf(fperr,"Error at line %d: Unnnamed argument(s) in definition of function %s\n\n", line_count, $2->output.c_str());
				error_count++;
			}
			func_type_list = $$->type_list;
			func_name_list = $$->name_list;
		}
			function_body
		{
			$$->output = $1->output + " " + $2->output + $3->output + $4->output + $5->output + " " + $7->output;
			fprintf(fplog, "At line no: %d func_definition : type_specifier ID LPAREN parameter_list RPAREN function_body\n\n", line_count);
			fprintf(fplog, "%s\n\n", $$->output.c_str());
			
			//ASM PART
			$$->asmCode = "";
			if(comments) $$->asmCode += ";FUNCTION DEFINITION\n";
			$$->asmCode += "\n" + $2->output + " PROC\n\n";
			if($2->output != "main") {
				$$->asmCode += $7->asmCodePush;
			}
			else {
				if(comments) $$->asmCode += ";INITIALIZING DATA SEGMENT\n";
				$$->asmCode += "MOV AX,@DATA;\n";
				$$->asmCode += "MOV DS,AX;\n";
			}
			$$->asmCode += paramCode;
			$$->asmCode += $7->asmCode;
			if($2->output != "main") {
				$$->asmCode += $7->asmCodePop;
			}
			$$->asmCode += "\n" + $2->output + " ENDP\n\n";
			
			paramCode = "";
			if(asmDebug) $$->printAsm("func_definition",line_count);
		}
		| type_specifier ID LPAREN RPAREN {
			//COMMENT: Compulsory new Sync
			$$ = new Sync("");
			functionState state = $$->defineFuncTop($1->var_type, $2->output, table);
			switch(state) {
			case functionState::mulDeclare:
				fprintf(fperr,"Error at line %d: Multiple declaration of %s\n\n", line_count, $2->output.c_str());
				error_count++;
				break;
			case functionState::mulDef:
				fprintf(fperr,"Error at line %d: Multiple definition of %s\n\n", line_count, $2->output.c_str());
				error_count++;
				break;
			case functionState::manyLessArgs:
				fprintf(fperr,"Error at line %d: Too many or too less arguments for function %s\n\n", line_count, $2->output.c_str());
				error_count++;
				break;
			case functionState::unmatchedArgs:
				fprintf(fperr,"Error at line %d: Argument mismatch for function %s\n\n", line_count, $2->output.c_str());
				error_count++;
				break;
			}
			func_type_list = $$->type_list;
			func_name_list = $$->name_list;
		}
			function_body
		{
			$$->output = $1->output + " " + $2->output + $3->output + $4->output + " " + $6->output; 
			fprintf(fplog, "At line no: %d func_definition : type_specifier ID LPAREN parameter_list RPAREN function_body\n\n", line_count);
			fprintf(fplog, "%s\n\n", $$->output.c_str());
			
			//ASM PART
			$$->asmCode = "";
			if(comments) $$->asmCode += ";FUNCTION DEFINITION\n";
			$$->asmCode += "\n" + $2->output + " PROC\n\n";
			if($2->output != "main") {
				$$->asmCode += $6->asmCodePush;
			}
			else {
				if(comments) $$->asmCode += ";INITIALIZING DATA SEGMENT\n";
				$$->asmCode += "MOV AX,@DATA;\n";
				$$->asmCode += "MOV DS,AX;\n";
			}
			$$->asmCode += $6->asmCode;
			if($2->output != "main") {
				$$->asmCode += $6->asmCodePop;
			}
			$$->asmCode += "\n" + $2->output + " ENDP\n\n";
			
			if(asmDebug) $$->printAsm("func_definition",line_count);
		}
 		;				

function_body : LCURL
		{
			table->enterScope();
			fprintf(fplog," New ScopeTable with id %d created\n\n", table->getCurrentScopeId());
			//COMMENT: Compulsory new Sync
			$$ = new Sync("");
			$$->type_list = func_type_list;
			$$->name_list = func_name_list;
			
			//ASM PART
			int scopeId = table->getCurrentScopeId();
			for(deque<string>::iterator it = func_name_list->begin(); it != func_name_list->end(); it++) {
				string varName = *it;
				varName += scopeText + to_string(scopeId);
				asm_var_list->push_back(varName);
				asm_var_size_list->push_back(-1);
			}
			//---------------
			
			$$->defineFuncBody(table);
			
		}
			RCURL {
			//ASM PART
			if(comments)  $$->asmCodePush += ";PUSHING FUNCTION ELEMENTS INTO STACK\n";
			string scopeId = to_string(table->getCurrentScopeId());
			table->getAllVarNameCS(asm_var_stack);
			for(deque<string>::iterator it = asm_var_stack->begin(); it != asm_var_stack->end(); it++) {
				string varName = *it + scopeText + scopeId;
				$$->asmCodePush += "PUSH " + varName + ";\n";
			}
			$$->asmCodePush += "\n";
			
			if(comments)  $$->asmCode += ";FUNCTION BODY IS EMPTY\n";
			$$->asmCode += "\n";
			
			if(comments)  ";POPPING FUNCTION ELEMENTS FROM STACK\n";
			while(!asm_var_stack->empty()) {
				string varName = asm_var_stack->back() + scopeText + scopeId;
				$$->asmCodePop += "POP " + varName + ";\n";
				asm_var_stack->pop_back();
			}	
			if(asmDebug) $$->printAsm("function_body", line_count);
			//---------------
			
			table->printAllScopeTable(fplog);
			fprintf(fplog," ScopeTable with id %d removed\n\n", table->getCurrentScopeId());
			table->exitScope();
			$$->output = $1->output + $3->output;
			fprintf(fplog, "At line no: %d function_body : LCURL RCURL\n\n", line_count);
			fprintf(fplog, "%s\n\n", $$->output.c_str());
		}
		| LCURL {
			table->enterScope();
			fprintf(fplog," New ScopeTable with id %d created\n\n", table->getCurrentScopeId());
			//COMMENT: Compulsory new Sync
			$$ = new Sync("");
			$$->type_list = func_type_list;
			$$->name_list = func_name_list;
			
			//ASM PART
			int scopeId = table->getCurrentScopeId();
			for(deque<string>::iterator it = func_name_list->begin(); it != func_name_list->end(); it++) {
				string varName = *it;
				varName += scopeText + to_string(scopeId);
				asm_var_list->push_back(varName);
				asm_var_size_list->push_back(-1);
			}
			//---------------
			
			$$->defineFuncBody(table);
			
		}
			statements RCURL
		{
			//ASM PART
			if(comments)  ";PUSHING FUNCTION ELEMENTS INTO STACK\n";
			string scopeId = to_string(table->getCurrentScopeId());
			table->getAllVarNameCS(asm_var_stack);
			for(deque<string>::iterator it = asm_var_stack->begin(); it != asm_var_stack->end(); it++) {
				string varName = *it + scopeText + scopeId;
				$$->asmCodePush += "PUSH " + varName + ";\n";
			}
			$$->asmCodePush += "\n";
			
			if(comments)  $$->asmCode += ";FUNCTION BODY\n";
			$$->asmCode += $3->asmCode;
			$$->asmCode += "\n";
			
			if(comments)  ";POPPING FUNCTION ELEMENTS FROM STACK\n";
			while(!asm_var_stack->empty()) {
				string varName = asm_var_stack->back() + scopeText + scopeId;
				$$->asmCodePop += "POP " + varName + ";\n";
				asm_var_stack->pop_back();
			}
			if(asmDebug) $$->printAsm("function_body", line_count, $$->asmCodePush);
			if(asmDebug) $$->printAsm("function_body", line_count);
			if(asmDebug) $$->printAsm("function_body", line_count, $$->asmCodePop);
			//---------------
			
			table->printAllScopeTable(fplog);
			fprintf(fplog," ScopeTable with id %d removed\n\n", table->getCurrentScopeId());
			table->exitScope();
			$$->output = $1->output + "\n" + $3->output + "\n" + $4->output;
			fprintf(fplog, "At line no: %d function_body : LCURL RCURL\n\n", line_count);
			fprintf(fplog, "%s\n\n", $$->output.c_str());
		}

parameter_list : parameter_list COMMA type_specifier ID
		{
			$1->addParam($3->var_type,$4->output);
			$$ = $1;
			$$->output = $1->output + $2->output + " " + $3->output + " " + $4->output;
			fprintf(fplog, "At line no: %d parameter_list : parameter_list COMMA type_specifier ID\n\n", line_count);
			fprintf(fplog, "%s\n\n", $$->output.c_str());
		}
		| parameter_list COMMA type_specifier
		{
			$1->addParam($3->var_type,"");
			$$ = $1;
			$$->output = $1->output + $2->output + " " + $3->output;
			fprintf(fplog, "At line no: %d parameter_list : parameter_list COMMA type_specifier\n\n", line_count);
			fprintf(fplog, "%s\n\n", $$->output.c_str());
		}
 		| type_specifier ID
		{
			$1->startFuncDeclare();
			$1->addParam($1->var_type,$2->output);
			$$ = $1;
			$$->output = $1->output + " " + $2->output; 
			fprintf(fplog, "At line no: %d parameter_list : type_specifier\n\n", line_count);
			fprintf(fplog, "%s\n\n", $$->output.c_str());
		}
		| type_specifier
		{
			$1->startFuncDeclare();
			$1->addParam($1->var_type,"");
			$$ = $1;
			fprintf(fplog, "At line no: %d parameter_list : type_specifier\n\n", line_count);
			fprintf(fplog, "%s\n\n", $$->output.c_str());
		}
 		;
 		
compound_statement : LCURL {
				$$ = new Sync("");
				table->enterScope();
				fprintf(fplog," New ScopeTable with id %d created\n\n", table->getCurrentScopeId());
			}
				statements RCURL
			{
				$$->output = $1->output + '\n' + $3->output + '\n' + $4->output;
				fprintf(fplog, "At line no: %d compound_statement : LCURL statements RCURL\n\n", line_count);
				fprintf(fplog, "%s\n\n", $$->output.c_str());
				table->printAllScopeTable(fplog);
				fprintf(fplog," ScopeTable with id %d removed\n\n", table->getCurrentScopeId());
				table->exitScope();
				
				//ASM PART
				if(comments)  $$->asmCode += (";COMPOUND STATEMENT\n");
				$$->asmCode += $3->asmCode;
				if(asmDebug)  $$->printAsm("compound_statement", line_count);
			}
 		    | LCURL RCURL {
				$$ = new Sync("");
				$$->output = $1->output + '\n' + $2->output;
				fprintf(fplog, "At line no: %d compound_statement : LCURL RCURL\n\n", line_count);
				fprintf(fplog, "%s\n\n", $$->output.c_str());
			}
 		    ;
 		    
var_declaration : type_specifier declaration_list SEMICOLON
		{
			$$ = $2;
			$$->var_type = $1->var_type;
			if(!$$->flushVarList(table)) {
				if($1->var_type.compare("VOID") == 0) {
					fprintf(fperr,"Error at line %d: Variables cannot be declared as void\n\n", line_count);
					error_count++;
				}
				else if(!$$->varExists->empty()) {
					string exists;
					while(!$$->varExists->empty()) {
						exists = $$->varExists->front();
						$$->varExists->pop_front();
						fprintf(fperr,"Error at line %d: Multiple declaration of %s\n\n", line_count, exists.c_str());
						error_count++;
					}
				}
				else {
					cout << "CODEBUG: In \"var_declaration : type_specifier declaration_list SEMICOLON\" :" << endl;
					cout << "Sync::flushVarList() in \"sync.h\" file may not be working correctly." << endl << endl;
				}
			}			
			$$->output = $1->output + " " + $2->output + $3->output;
			fprintf(fplog, "At line no: %d var_declaration : type_specifier declaration_list SEMICOLON\n\n", line_count);
			fprintf(fplog, "%s\n\n", $$->output.c_str());
			
			//ASM PART
			int scopeId = table->getCurrentScopeId();
			while(!$$->return_var_list->empty()) {
				string varName = $$->return_var_list->front();
				$$->return_var_list->pop_front();
				varName += scopeText + to_string(scopeId);
				asm_var_list->push_back(varName);
				
				int size = $$->return_size_list->front();
				$$->return_size_list->pop_front();
				asm_var_size_list->push_back(size);
			}
			
		}
 		 ;
 		 
type_specifier : INT
		{
			$$ = $1;
			$$->var_type = "INT";
			fprintf(fplog, "At line no: %d type_specifier : INT\n\n", line_count);
			fprintf(fplog, "%s\n\n", $$->output.c_str());
		}
 		| FLOAT
		{
			$$ = $1;
			$$->var_type = "FLOAT";
			fprintf(fplog, "At line no: %d type_specifier : FLOAT\n\n", line_count);
			fprintf(fplog, "%s\n\n", $$->output.c_str());
		}
 		| VOID
		{
			$$ = $1;
			$$->var_type = "VOID";
			fprintf(fplog, "At line no: %d type_specifier : VOID\n\n", line_count);
			fprintf(fplog, "%s\n\n", $$->output.c_str());
		}
 		;
 		
declaration_list : declaration_list COMMA ID
			  {
				$1->addVar($3->output, -1);
				$$ = $1;
				$$->output = $1->output + $2->output + " " + $3->output; 
				fprintf(fplog, "At line no: %d declaration_list : declaration_list COMMA ID\n\n", line_count);
				fprintf(fplog, "%s\n\n", $$->output.c_str());
			  }
			  | declaration_list COMMA ID LTHIRD CONST_INT RTHIRD
			  {
				int index = stoi($5->output);
				if(index >= 0)
					$1->addVar($3->output, index);
				else {
					fprintf(fperr,"Error at line %d : Non-integer Array Index\n\n", line_count);
					error_count++;
				}
				$$ = $1;
				$$->output = $1->output + $2->output + " " + $3->output + $4->output + $5->output + $6->output; 
				fprintf(fplog, "At line no: %d declaration_list : declaration_list COMMA ID LTHIRD CONST_INT RTHIRD\n\n", line_count);
				fprintf(fplog, "%s\n\n", $$->output.c_str());
			  }
			  | ID
			  {
				$1->startVarDeclare();
				$1->addVar($1->output, -1);
				$$ = $1;
				fprintf(fplog, "At line no: %d declaration_list : ID\n\n", line_count);
				fprintf(fplog, "%s\n\n", $$->output.c_str());
			  }
			  | ID LTHIRD CONST_INT RTHIRD
			  {
				$1->startVarDeclare();
				int index = stoi($3->output);
				if(index >= 0)
					$1->addVar($1->output, index);
				else {
					fprintf(fperr,"Error at line %d : Non-integer Array Index\n\n", line_count);
					error_count++;
				}
				$$ = $1;
				$$->output = $1->output + $2->output + $3->output + $4->output; 
				fprintf(fplog, "At line no: %d declaration_list : ID LTHIRD CONST_INT RTHIRD\n\n", line_count);
				fprintf(fplog, "%s\n\n", $$->output.c_str());
			  }
			  ;
 		  
statements : statement
		{
			$$ = new Sync("");
			$$->output = $1->output;
			fprintf(fplog, "At line no: %d statements : statement\n\n", line_count);
			fprintf(fplog, "%s\n\n", $$->output.c_str());
			
			//ASM PART
			$$->asmCode += $1->asmCode;
			if(asmDebug)  $$->printAsm("statements", line_count);

		}
		| statements statement
		{
			$$->output = $1->output + "\n" + $2->output;
			fprintf(fplog, "At line no: %d statements : statements statement\n\n", line_count);
			fprintf(fplog, "%s\n\n", $$->output.c_str());
			
			//ASM PART
			$$->asmCode = $1->asmCode + $2->asmCode;
			if(asmDebug)  $$->printAsm("statements", line_count);
		}
	   ;
	   
statement : var_declaration
		{
			$$ = new Sync("");
			$$->output = $1->output;
			fprintf(fplog, "At line no: %d statement : var_declaration\n\n", line_count);
			fprintf(fplog, "%s\n\n", $$->output.c_str());
		}
		| expression_statement
		{
			$$ = new Sync("");
			$$->output = $1->output;
			fprintf(fplog, "At line no: %d statement : expression_statement\n\n", line_count);
			fprintf(fplog, "%s\n\n", $$->output.c_str());
			
			//ASM PART
			if(comments) $$->asmCode += ";STATEMENT\n";
			$$->asmCode = $1->asmCode;
			if(asmDebug)  $$->printAsm("statement", line_count);
		}
		| compound_statement
		{
			$$ = new Sync("");
			$$->output = $1->output;
			fprintf(fplog, "At line no: %d statement : compound_statement\n\n", line_count);
			fprintf(fplog, "%s\n\n", $$->output.c_str());
			
			//ASM PART
			$$->asmCode += $1->asmCode;
			if(asmDebug)  $$->printAsm("compound_statement", line_count);
		}
		| FOR LPAREN expression_statement expression_statement expression RPAREN statement
		{
			$$ = new Sync("");
			$$->output = $1->output + $2->output + $3->output + $4->output + $5->output + $6->output + $7->output;
			fprintf(fplog, "At line no: %d statement : FOR LPAREN expression_statement expression_statement expression RPAREN statement\n\n", line_count);
			fprintf(fplog, "%s\n\n", $$->output.c_str());
			
			//ASM PART
			if(comments) $$->asmCode += ";FOR LOOP\n";
			
			if(comments) $$->asmCode += ";STATEMENTS BEFORE ENTERING FOR LOOP\n";
			$$->asmCode += $3->asmCode;
			
			string labelEnd = newLabel();
			string startLabel = "START_FOR" + labelEnd;
			string endLabel = "END_FOR" + labelEnd;
			
			$$->asmCode += "\n" + startLabel + ":\n\n";
			
			$$->asmCode += $4->asmCode;
			$$->asmCode += "\n";
			
			string varName = $4->varName;
			if(isNumber($4->varName)) {
				$$->asmCode += "MOV " + data_reg + "," + $4->varName + ";\n";
				varName = data_reg;
			}
			else if($4->varIndex != "<none>") {
				if(!isNumber($4->varIndex)) {
					$$->asmCode += "MOV " + index_reg + "," + $4->varIndex + ";\n";
					varName += "[" + index_reg + "]";
				}
				else
					varName += "[" + $4->varIndex + "]";
			}
			
			$$->asmCode += "CMP " + varName + "," + "0;\n";
			$$->asmCode += "JE " + endLabel + ";\n\n";
			
			$$->asmCode += $7->asmCode;
			$$->asmCode += "\n";
			
			if(comments) $$->asmCode += ";STATEMENTS AT THE END OF FOR LOOP\n";
			$$->asmCode += $5->asmCode;
			
			$$->asmCode += "\nJMP " + startLabel + ";\n";
			
			$$->asmCode += "\n" + endLabel + ":\n\n";
			
			if(asmDebug) $$->printAsm("statement",line_count);
		}
		| IF LPAREN expression RPAREN statement
		{
			$$ = new Sync("");
			$$->output = $1->output + $2->output + $3->output + $4->output + $5->output;
			fprintf(fplog, "At line no: %d statement : IF LPAREN expression RPAREN statement\n\n", line_count);
			fprintf(fplog, "%s\n\n", $$->output.c_str());
			
			//ASM PART
			if(comments) $$->asmCode += ";IF CONDITION\n";
			$$->asmCode += $3->asmCode;
			
			string varName = $3->varName;
			if(isNumber($3->varName)) {
				$$->asmCode += "MOV " + data_reg + "," + $3->varName + ";\n";
				varName = data_reg;
			}
			else if($3->varIndex != "<none>") {
				if(!isNumber($3->varIndex)) {
					$$->asmCode += "MOV " + index_reg + "," + $3->varIndex + ";\n";
					varName += "[" + index_reg + "]";
				}
				else
					varName += "[" + $3->varIndex + "]";
			}
			
			string labelEnd = newLabel();
			string endLabel = "END_IF" + labelEnd;
			
			$$->asmCode += "CMP " + varName + "," + "0;\n";
			$$->asmCode += "JE " + endLabel + ";\n\n";
			
			$$->asmCode += $5->asmCode;
			
			$$->asmCode += "\n" + endLabel + ":\n\n";
			
			if(asmDebug) $$->printAsm("statement",line_count);
		}
		| IF LPAREN expression RPAREN statement ELSE statement
		{
			$$ = new Sync("");
			$$->output = $1->output + $2->output + $3->output + $4->output + $5->output + $6->output + $7->output;
			fprintf(fplog, "At line no: %d statement : IF LPAREN expression RPAREN statement ELSE statement\n\n", line_count);
			fprintf(fplog, "%s\n\n", $$->output.c_str());
			
			//ASM PART
			if(comments) $$->asmCode += ";IF-ELSE CONDITION\n";
			$$->asmCode += $3->asmCode;
			$$->asmCode += "\n";
			
			string varName = $3->varName;
			if(isNumber($3->varName)) {
				$$->asmCode += "MOV " + data_reg + "," + $3->varName + ";\n";
				varName = data_reg;
			}
			else if($3->varIndex != "<none>") {
				if(!isNumber($3->varIndex)) {
					$$->asmCode += "MOV " + index_reg + "," + $3->varIndex + ";\n";
					varName += "[" + index_reg + "]";
				}
				else
					varName += "[" + $3->varIndex + "]";
			}
			
			string labelEnd = newLabel();
			string falseLabel = "ELSE" + labelEnd;
			string endLabel = "END_IF" + labelEnd;
			
			$$->asmCode += "CMP " + varName + "," + "0;\n";
			$$->asmCode += "JE " + falseLabel + ";\n\n";
			
			$$->asmCode += $5->asmCode;
			
			$$->asmCode += "\nJMP " + endLabel + ";\n"; 
			
			$$->asmCode += "\n" + falseLabel + ":\n\n";
			
			$$->asmCode += $7->asmCode;
			
			$$->asmCode += "\n" + endLabel + ":\n\n";
			
			if(asmDebug) $$->printAsm("statement",line_count);
		}
		| WHILE LPAREN expression RPAREN statement
		{
			$$ = new Sync("");
			$$->output = $1->output + $2->output + $3->output + $4->output + $5->output;
			fprintf(fplog, "At line no: %d statement : WHILE LPAREN expression RPAREN statement\n\n", line_count);
			fprintf(fplog, "%s\n\n", $$->output.c_str());
			
			//ASM PART
			if(comments) $$->asmCode += ";WHILE LOOP\n";
			
			string labelEnd = newLabel();
			string startLabel = "START_WHILE" + labelEnd;
			string endLabel = "END_WHILE" + labelEnd;
			
			$$->asmCode += "\n" + startLabel + ":\n\n";
			
			$$->asmCode += $3->asmCode;
			$$->asmCode += "\n";
			
			string varName = $3->varName;
			if(isNumber($3->varName)) {
				$$->asmCode += "MOV " + data_reg + "," + $3->varName + ";\n";
				varName = data_reg;
			}
			else if($3->varIndex != "<none>") {
				if(!isNumber($3->varIndex)) {
					$$->asmCode += "MOV " + index_reg + "," + $3->varIndex + ";\n";
					varName += "[" + index_reg + "]";
				}
				else
					varName += "[" + $3->varIndex + "]";
			}
			
			$$->asmCode += "CMP " + varName + "," + "0;\n";
			$$->asmCode += "JE " + endLabel + ";\n\n";
			
			$$->asmCode += $5->asmCode;
			
			$$->asmCode += "\nJMP " + startLabel + ";\n";
			
			$$->asmCode += "\n" + endLabel + ":\n\n";
			
			if(asmDebug) $$->printAsm("statement",line_count);
		}
		| PRINTLN LPAREN ID RPAREN SEMICOLON
		{
			$$ = new Sync("");
			$$->output = $1->output + $2->output + $3->output + $4->output + $5->output;
			fprintf(fplog, "At line no: %d statement : PRINTLN LPAREN ID RPAREN SEMICOLON\n\n", line_count);
			fprintf(fplog, "%s\n\n", $$->output.c_str());
			
			//ASM PART
			int scopeId = table->lookUpScope($3->output);
			string varName = $3->output + scopeText + to_string(scopeId);
			if($3->varIndex != "<none>") {
				if(!isNumber($3->varIndex)) {
					$$->asmCode += "MOV " + index_reg_2 + "," + $3->varIndex + ";\n";
					varName += "[" + index_reg_2 + "]";
				}
				else
					varName += "[" + $3->varIndex + "]";
			}
			$$->asmCode += "MOV " + data_reg + "," + varName + ";\n";
			$$->asmCode += "MOV NUMBER, " + data_reg + ";\n";
			$$->asmCode += "CALL PRINT_NUMBER\n";
		}
		| RETURN expression SEMICOLON
		{
			$$ = new Sync("");
			$$->output = $1->output + " " + $2->output + $3->output;
			fprintf(fplog, "At line no: %d statement : RETURN expression SEMICOLON\n\n", line_count);
			fprintf(fplog, "%s\n\n", $$->output.c_str());
			
			//ASM CODE
			if(comments) $$->asmCode == ";RETURNING VALUE\n";
			string varName = $2->varName;
			if(!isNumber($2->varName)) {
				if($2->varIndex != "<none>") {
					if(!isNumber($2->varIndex)) {
						$$->asmCode += "MOV " + index_reg_2 + "," + $2->varIndex + ";\n";
						varName += "[" + index_reg_2 + "]";
					}
					else
						varName += "[" + $2->varIndex + "]";
				}
				$$->asmCode += "MOV " + data_reg + "," + varName + ";\n";
				varName = data_reg;
			}
			$$->asmCode += "MOV " + returnVar + "," + data_reg + ";\n";
			
			if(asmDebug) $$->printAsm("statement",line_count);
		}
	  ;
	  
expression_statement : SEMICOLON
			{
				$$ = new Sync("");
				$$->output = $1->output;
				fprintf(fplog, "At line no: %d expression_statement : SEMICOLON\n\n", line_count);
				fprintf(fplog, "%s\n\n", $$->output.c_str());
				
				//ASM PART
				//EMPTY BOOLEAN STATEMENT. MAYBE RETURN FALSE? <OTHERWISE, MAYBE STUCK IN FOR/WHILE LOOP>
				$$->varName = "0";
				if(asmDebug)  $$->printAsm("expression_statement", line_count, "<EMPTY EXPRESSION STATEMENT>\n<RETURNS 0>\n");
			}
			| expression SEMICOLON
			{
				$$ = new Sync("");
				$$->output = $1->output + $2->output;
				fprintf(fplog, "At line no: %d expression_statement : expression SEMICOLON\n\n", line_count);
				fprintf(fplog, "%s\n\n", $$->output.c_str());
				
				//ASM PART
				if(comments) $$->asmCode += ";EXPRESSION STATEMENT\n";
				$$->asmCode += $1->asmCode;
				$$->varName = $1->varName;
				$$->varIndex = $1->varIndex;
				asmPrint($$,"expression_statement");
			}
			;
	  
variable : ID
		{
			$$ = new Sync("");
			SymbolInfo* look = table->lookUp($1->output);
			if(look == NULL) {
				fprintf(fperr,"Error at Line %d : Undeclared Variable: %s\n\n",line_count,$1->output.c_str());
				error_count++;
				$$->type = "";
			}
			else {
				$$->type = look->getType();
				if(look->getSize() >= 0)
					$$->type = $$->type + "_ARRAY";
			}
			$$->output = $1->output;
			fprintf(fplog, "At line no: %d variable : ID\n\n", line_count);
			fprintf(fplog, "%s\n\n", $$->output.c_str());
			
			//ASM PART
			if(look != NULL) {
				int scopeId = table->lookUpScope($1->output);
				$$->varName = look->getName() + scopeText + to_string(scopeId);
			}
			asmVarPrint($$,"variable");
		}
		| ID LTHIRD expression RTHIRD 
		{
			$$ = new Sync("");
			SymbolInfo* look = table->lookUp($1->output);
			if(look == NULL) {
				fprintf(fperr,"Error at Line %d : Undeclared Variable: %s\n\n",line_count,$1->output.c_str());
				error_count++;
				$$->type = "";
			}
			else {
				$$->type = look->getType();
				if(look->getSize() < 0) {
					fprintf(fperr,"Error at line %d : Type Mismatch\n\n", line_count);
					error_count++;
				}
			}
			if($3->type != "INT") {
				fprintf(fperr,"Error at Line %d : Non-integer Array Index \n\n",line_count);
				error_count++;
			}
			$$->output = $1->output + $2->output + $3->output + $4->output;
			fprintf(fplog, "At line no: %d variable : ID LTHIRD expression RTHIRD\n\n", line_count);
			fprintf(fplog, "%s\n\n", $$->output.c_str());
			
			//ASM PART
			$$->asmCode = $3->asmCode;
			if(look != NULL) {
				int scopeId = table->lookUpScope($1->output);
				$$->varName = $1->output + scopeText + to_string(scopeId);
				if($3->varName == "<none>"){
					$$->varIndex = "<no_index>";
					if(comments) $$->asmCode += ";ERROR: NO INDEX FOUND FOR ARRAY DATA TYPE\n";
				}
				else if($3->varIndex == "<none>") {
					if( isNumber($3->varName) ) {
						$$->varIndex = to_string(stoi($3->varName) * 2);
					}
					else {
						if(comments)  $$->asmCode += ";COMPUTING ARRAY INDEX\n";
						string index = newTemp();
						$$->asmCode += "MOV AX,2;\n";
						$$->asmCode += "IMUL " + $3->varName + ";\n";
						$$->asmCode += "MOV " + index + "," + "AX;\n\n";
						$$->varIndex = index;
					}
				}
				else {
					if(comments)  $$->asmCode += ";COMPUTING ARRAY INDEX\n";
					if( !isNumber($3->varIndex) ) {
						$$->asmCode += "MOV " + index_reg + "," + $3->varIndex + ";\n";
						$3->varIndex = index_reg;
					}
					$$->asmCode += "MOV AX,2;\n";
					$$->asmCode += "IMUL " + $3->varName + "[" + $3->varIndex + "]" + ";\n";
					string newVar = newTemp();
					$$->asmCode += "MOV " + newVar + "," + "AX;\n\n";
					$$->varIndex = newVar;
				}
			}
			asmVarPrint($$,"variable");
		}
	 ;
	 
expression : logic_expression
		{
			$$ = new Sync("");
			$$->type = $1->type;
			$$->output = $1->output;
			fprintf(fplog, "At line no: %d expression : logic_expression\n\n", line_count);
			fprintf(fplog, "%s\n\n", $$->output.c_str());
			
			//ASM PART
			$$->asmCode = $1->asmCode;
			$$->varName = $1->varName;
			$$->varIndex = $1->varIndex;
			asmPrint($$,"expression");
			
		}
		| variable ASSIGNOP logic_expression
		{
			$$ = new Sync("");
			if($1->type.compare("") != 0 && $3->type.compare("") != 0 && $1->type.compare($3->type) != 0) {
				if($1->type.compare("FLOAT") == 0 && $3->type.compare("INT") == 0);
				else {
					fprintf(fperr,"Error at line %d : Type Mismatch\n\n", line_count);
					error_count++;
				}
			}
			$$->output = $1->output + $2->output + $3->output;
			fprintf(fplog, "At line no: %d expression : variable ASSIGNOP logic_expression\n\n", line_count);
			fprintf(fplog, "%s\n\n", $$->output.c_str());
			
			//ASM PART
			$$->asmCode = $1->asmCode + $3->asmCode;
			if(comments) $$->asmCode += ";ASSIGNMENT OPERATION\n";
			
			string varName = $1->varName;
			if($1->varIndex != "<none>") {
				if(!isNumber($1->varIndex)) {
					$$->asmCode += "MOV " + index_reg + "," + $1->varIndex + ";\n";
					varName += "[" + index_reg + "]";
				}
				else
					varName += "[" + $1->varIndex + "]";
			}
			string varName2 = $3->varName;
			if(!isNumber($3->varName)) {
				if($3->varIndex != "<none>") {
					if(!isNumber($3->varIndex)) {
						$$->asmCode += "MOV " + index_reg_2 + "," + $3->varIndex + ";\n";
						varName2 += "[" + index_reg_2 + "]";
					}
					else
						varName2 += "[" + $3->varIndex + "]";
				}
				$$->asmCode += "MOV " + data_reg + "," + varName2 + ";\n";
				varName2 = data_reg;
			}
			$$->asmCode += "MOV " + varName + "," + varName2 + ";\n\n";
			$$->varName = $1->varName;
			$$->varIndex = $1->varIndex;
			asmPrint($$,"expression");
		}
	   ;
			
logic_expression : rel_expression 
		{
			$$ = new Sync("");
			$$->type = $1->type;
			$$->output = $1->output;
			fprintf(fplog, "At line no: %d logic_expression : rel_expression \n\n", line_count);
			fprintf(fplog, "%s\n\n", $$->output.c_str());
			
			//ASM PART
			$$->asmCode = $1->asmCode;
			$$->varName = $1->varName;
			$$->varIndex = $1->varIndex;
			asmPrint($$,"logic_expression");
		}
		| rel_expression LOGICOP rel_expression
		{
			$$ = new Sync("");
			$$->output = $1->output + $2->output + $3->output;
			fprintf(fplog, "At line no: %d logic_expression : rel_expression LOGICOP rel_expression\n\n", line_count);
			fprintf(fplog, "%s\n\n", $$->output.c_str());
			
			//ASM PART
			$$->asmCode += $1->asmCode + $3->asmCode;
			if(comments)  $$->asmCode += ";LOGICAL AND/OR OPERATION;\n";
			
			string varName = $1->varName;
			if(isNumber($1->varName)) {
				$$->asmCode += "MOV " + data_reg + "," + $1->varName + ";\n";
				varName = data_reg;
			}
			else if($1->varIndex != "<none>") {
				if(!isNumber($1->varIndex)) {
					$$->asmCode += "MOV " + index_reg + "," + $1->varIndex + ";\n";
					varName += "[" + index_reg + "]";
				}
				else
					varName += "[" + $1->varIndex + "]";
			}
			
			string varName2 = $3->varName;
			if(isNumber($3->varName)) {
				$$->asmCode += "MOV " + data_reg_2 + "," + $3->varName + ";\n";
				varName2 = data_reg_2;
			}
			else if($3->varIndex != "<none>") {
				if(!isNumber($3->varIndex)) {
					$$->asmCode += "MOV " + index_reg_2 + "," + $3->varIndex + ";\n";
					varName2 += "[" + index_reg_2 + "]";
				}
				else
					varName2 += "[" + $3->varIndex + "]";
			}
			$$->asmCode += "\n";
			
			string newVar = newTemp();
			
			if($2->output == "&&") {
				string labelEnd = newLabel();
				string endLabel = "AND_OP_DONE" + labelEnd;
				string falseLabel = "AND_FALSE" + labelEnd;
				
				$$->asmCode += "CMP " + varName + "," + "0;\n";
				$$->asmCode += "JE " + falseLabel + ";\n\n";
				
				$$->asmCode += "CMP " + varName2 + "," + "0;\n";
				$$->asmCode += "JE " + falseLabel + ";\n\n";
				
				$$->asmCode += "MOV " + newVar + "," + "1;\n";
				$$->asmCode += "JMP " + endLabel + ";\n";
				
				$$->asmCode += "\n" + falseLabel + ":\n\n";
				
				$$->asmCode += "MOV " + newVar + "," + "0;\n";
				
				$$->asmCode += "\n" + endLabel + ":\n\n";
				
				$$->varName = newVar;
			}
			else if($2->output == "||") {
				string labelEnd = newLabel();
				string endLabel = "OR_OP_DONE" + labelEnd;
				string trueLabel = "OR_TRUE" + labelEnd;
				
				$$->asmCode += "CMP " + varName + "," + "0;\n";
				$$->asmCode += "JNE " + trueLabel + ";\n\n";
				
				$$->asmCode += "CMP " + varName2 + "," + "0;\n";
				$$->asmCode += "JNE " + trueLabel + ";\n\n";
				
				$$->asmCode += "MOV " + newVar + "," + "0;\n";
				$$->asmCode += "JMP " + endLabel + ";\n";
				
				$$->asmCode += "\n" + trueLabel + ":\n\n";
				
				$$->asmCode += "MOV " + newVar + "," + "1;\n";
				
				$$->asmCode += "\n" + endLabel + ":\n\n";
				
				$$->varName = newVar;
			}
			else {
				printf("CODEBUG: Invalid symbol for ADDOP\n");
				printf("Check rule -- simple_expression : simple_expression ADDOP term\n");
				if(comments) $$->asmCode += ";ERROR: INVALID LOGICOP SYMBOL. RESULT  NOT STORED\n";
			}
			asmPrint($$,"logic_expression");
		}
		;
			
rel_expression	: simple_expression
		{
			$$ = new Sync("");
			$$->type = $1->type;
			$$->output = $1->output;
			fprintf(fplog, "At line no: %d rel_expression : simple_expression\n\n", line_count);
			fprintf(fplog, "%s\n\n", $$->output.c_str());
			
			//ASM PART
			$$->asmCode = $1->asmCode;
			$$->varName = $1->varName;
			$$->varIndex = $1->varIndex;
			asmPrint($$,"rel_expression");
		}
		| simple_expression RELOP simple_expression
		{
			$$ = new Sync("");
			$$->output = $1->output + $2->output + $3->output;
			fprintf(fplog, "At line no: %d rel_expression : simple_expression RELOP rel_expression\n\n", line_count);
			fprintf(fplog, "%s\n\n", $$->output.c_str());
			
			//ASM PART
			$$->asmCode += $1->asmCode + $3->asmCode;
			if(comments)  $$->asmCode += ";RELATIONAL OPERATION;\n";
			
			string varName = $1->varName;
			if($1->varIndex != "<none>") {
				if(!isNumber($1->varIndex)) {
					$$->asmCode += "MOV " + index_reg + "," + $1->varIndex + ";\n";
					varName += "[" + index_reg + "]";
				}
				else
					varName += "[" + $1->varIndex + "]";
			}
			$$->asmCode += "MOV " + data_reg + "," + varName + ";\n";
			
			string varName2 = $3->varName;
			if($3->varIndex != "<none>") {
				if(!isNumber($3->varIndex)) {
					$$->asmCode += "MOV " + index_reg + "," + $3->varIndex + ";\n";
					varName2 += "[" + index_reg + "]";
				}
				else
					varName2 += "[" + $3->varIndex + "]";
			}
			string newVar = newTemp();
			
			string labelEnd = newLabel();
			string endLabel = "REL_OP_DONE" + labelEnd;
			string trueLabel = "REL_TRUE" + labelEnd;
			
			string jumpCommand = "J<none>";
			if($2->output == ">")  jumpCommand = "JG";
			else if($2->output == "<")  jumpCommand = "JL";
			else if($2->output == ">=")  jumpCommand = "JGE";
			else if($2->output == "<=")  jumpCommand = "JLE";
			else if($2->output == "==")  jumpCommand = "JE";
			else if($2->output == "!=")  jumpCommand = "JNE";
			else {
				printf("CODEBUG: Invalid symbol for RELOP\n");
				printf("Check rule -- rel_expression : simple_expression RELOP simple_expression\n");
				if(comments) $$->asmCode += ";ERROR: INVALID RELOP SYMBOL. JUMP COMMAND NOT SET\n";
			}
			
			$$->asmCode += "CMP " + data_reg + "," + varName2 + ";\n";
			$$->asmCode += jumpCommand + " " + trueLabel + ";\n\n";
			
			$$->asmCode += "MOV " + newVar + "," + "0;\n";
			$$->asmCode += "JMP " + endLabel + ";\n";
			
			$$->asmCode += "\n" + trueLabel + ":\n\n";
			
			$$->asmCode += "MOV " + newVar + "," + "1;\n";
			
			$$->asmCode += "\n" + endLabel + ":\n\n";
			
			$$->varName = newVar;
			
			asmPrint($$,"rel_expression");
		}
		;
				
simple_expression : term 
		{
			$$ = new Sync("");
			$$->type = $1->type;
			$$->output = $1->output;
			fprintf(fplog, "At line no: %d simple_expression : term \n\n", line_count);
			fprintf(fplog, "%s\n\n", $$->output.c_str());
			
			//ASM PART
			$$->asmCode = $1->asmCode;
			$$->varName = $1->varName;
			$$->varIndex = $1->varIndex;
			asmPrint($$,"simple_expression");
		}
		| simple_expression ADDOP term
		{	
			$$ = new Sync("");
			if($1->type.compare("") != 0 && $3->type.compare("") != 0 && $1->type.compare($3->type) != 0) {
				if( ($1->type.compare("INT") == 0 || $1->type.compare("FLOAT") == 0) && ($3->type.compare("FLOAT") == 0 || $3->type.compare("INT") == 0) );
				else {
					fprintf(fperr,"Error at line %d : Type Mismatch\n\n", line_count);
					error_count++;
				}
			}
			$$->output = $1->output + $2->output + $3->output;
			fprintf(fplog, "At line no: %d simple_expression : simple_expression ADDOP term\n\n", line_count);
			fprintf(fplog, "%s\n\n", $$->output.c_str());
			
			//ASM PART
			$$->asmCode = $1->asmCode + $3->asmCode;
			if(comments) $$->asmCode += ";ADDITION/SUBTRACTION OPERATION\n";
			
			string varName = $1->varName;
			if($1->varIndex != "<none>") {
				if(!isNumber($1->varIndex)) {
					$$->asmCode += "MOV " + index_reg + "," + $1->varIndex + ";\n";
					varName += "[" + index_reg + "]";
				}
				else
					varName += "[" + $1->varIndex + "]";
			}
			$$->asmCode += "MOV " + data_reg + "," + varName + ";\n";
			
			string varName2 = $3->varName;
			if($3->varIndex != "<none>") {
				if(!isNumber($3->varIndex)) {
					$$->asmCode += "MOV " + index_reg + "," + $3->varIndex + ";\n";
					varName2 += "[" + index_reg + "]";
				}
				else
					varName2 += "[" + $3->varIndex + "]";
			}
			if($2->output == "+")
				$$->asmCode += "ADD " + data_reg + "," + varName2 + ";\n";
			else if($2->output == "-")
				$$->asmCode += "SUB " + data_reg + "," + varName2 + ";\n";
			else {
				printf("CODEBUG: Invalid symbol for ADDOP\n");
				printf("Check rule -- simple_expression : simple_expression ADDOP term\n");
				if(comments) $$->asmCode += ";ERROR: INVALID ADDOP SYMBOL. RESULT NOT STORED\n";
			}
			string newVar = newTemp();
			$$->asmCode += "MOV " + newVar + "," + data_reg + ";\n\n";
			$$->varName = newVar;
			
			asmPrint($$,"simple_expression");
			
		}		
		  ;
					
term :	unary_expression
		{
			$$ = new Sync("");
			$$->type = $1->type;
			$$->output = $1->output;
			fprintf(fplog, "At line no: %d term : unary_expression\n\n", line_count);
			fprintf(fplog, "%s\n\n", $$->output.c_str());
			
			//ASM PART
			$$->asmCode = $1->asmCode;
			$$->varName = $1->varName;
			$$->varIndex = $1->varIndex;
			asmPrint($$,"term");
		}
		|  term MULOP unary_expression
		{
			$$ = new Sync("");
			if($2->output.compare("%") == 0 && ($1->type.compare("INT") != 0 || $3->type.compare("INT") != 0)) {
				fprintf(fperr,"Error at line: %d : Integer operand on modulus operator\n\n", line_count);
				error_count++;
			}
			else if($1->type.compare("") != 0 && $3->type.compare("") != 0 && $1->type.compare($3->type) != 0) {
				if( ($1->type.compare("INT") == 0 || $1->type.compare("FLOAT") == 0) && ($3->type.compare("FLOAT") == 0 || $3->type.compare("INT") == 0) );
				else {
					fprintf(fperr,"Error at line %d : Type Mismatch\n\n", line_count);
					error_count++;
				}
			}
			$$->output = $1->output + $2->output + $3->output;
			fprintf(fplog, "At line no: %d term : term MULOP unary_expression\n\n", line_count);
			fprintf(fplog, "%s\n\n", $$->output.c_str());
			
			//ASM PART
			$$->asmCode += $1->asmCode + $3->asmCode;
			if(comments) $$->asmCode += ";MULTIPLICATION/DIVISION OPERATION\n";
			
			string varName = $1->varName;
			if($1->varIndex != "<none>") {
				if(!isNumber($1->varIndex)) {
					$$->asmCode += "MOV " + index_reg + "," + $1->varIndex + ";\n";
					varName += "[" + index_reg + "]";
				}
				else
					varName += "[" + $1->varIndex + "]";
			}
			$$->asmCode += "MOV AX," + varName + ";\n";
			
			string varName2 = $3->varName;
			if(isNumber($3->varName)) {
				$$->asmCode += "MOV " + mulop_reg + "," + $3->varName + ";\n";
				varName2 = mulop_reg;
			}
			else if($3->varIndex != "<none>") {
				if(!isNumber($3->varIndex)) {
					$$->asmCode += "MOV " + index_reg + "," + $3->varIndex + ";\n";
					varName2 += "[" + index_reg + "]";
				}
				else
					varName2 += "[" + $3->varIndex + "]";
			}
			
			string newVar = newTemp();
			if($2->output == "*") {
				$$->asmCode += "IMUL " + varName2 + ";\n";
				$$->asmCode += "MOV " + newVar + "," + "AX\n\n";
			}
			else if($2->output == "/") {
				$$->asmCode += "MOV DX,0;\n";
				$$->asmCode += "IDIV " + varName2 + ";\n";
				$$->asmCode += "MOV " + newVar + "," + "AX\n\n";
			}
			else if($2->output == "%") {
				$$->asmCode += "MOV DX,0;\n";
				$$->asmCode += "IDIV " + varName2 + ";\n";
				$$->asmCode += "MOV " + newVar + "," + "DX\n\n";
			}
			else {
				printf("CODEBUG: Invalid symbol for MULOP\n");
				printf("Check rule -- term : term MULOP unary_expression\n");
				if(comments) $$->asmCode += ";ERROR: INVALID MULOP SYMBOL. RESULT NOT STORED\n";
			}
			$$->varName = newVar;
			asmPrint($$,"term");
		}
     ;

unary_expression : ADDOP unary_expression
		{
			$$ = new Sync("");
			$$->type = $2->type;
			$$->output = $1->output + $2->output;
			fprintf(fplog, "At line no: %d unary_expression : ADDOP unary_expression\n\n", line_count);
			fprintf(fplog, "%s\n\n", $$->output.c_str());
			
			//ASM PART
			$$->asmCode = $2->asmCode;
			if(comments) $$->asmCode += ";RETURNING \"" + $1->output + "GIVEN_VARIABLE\"\n";
			
			string varName = $2->varName;
			if($2->varIndex != "<none>") {
				if(!isNumber($2->varIndex)) {
					$$->asmCode += "MOV " + index_reg + "," + $2->varIndex + ";\n";
					varName += "[" + index_reg + "]";
				}
				else
					varName += "[" + $2->varIndex + "]";
			}
			$$->asmCode += "MOV " + data_reg + "," + varName + ";\n";
			if($1->output == "-") {
				$$->asmCode += "NEG " + data_reg + ";\n";
			}
			string newVar = newTemp();
			$$->asmCode += "MOV " + newVar + "," + data_reg + ";\n\n";
			$$->varName = newVar;
			
			asmPrint($$,"unary_expression");

		}
		| NOT unary_expression
		{
			$$ = new Sync("");
			$$->type = $2->type;
			$$->output = $1->output + $2->output;
			fprintf(fplog, "At line no: %d unary_expression : NOT unary_expression\n\n", line_count);
			fprintf(fplog, "%s\n\n", $$->output.c_str());
			
			//ASM PART
			$$->asmCode = $2->asmCode;
			if(comments) $$->asmCode += ";NOT OPERATION\n";
			
			string varName = $2->varName;
			if(isNumber($2->varName)) {
				$$->asmCode += "MOV " + data_reg + "," + $2->varName + ";\n";
				varName = data_reg;
			}
			else if($2->varIndex != "<none>") {
				if(!isNumber($2->varIndex)) {
					$$->asmCode += "MOV " + index_reg + "," + $2->varIndex + ";\n";
					varName += "[" + index_reg + "]";
				}
				else
					varName += "[" + $2->varIndex + "]";
			}
			string newVar = newTemp();
			
			string labelEnd = newLabel();
			string endLabel = "NOT_OP_DONE" + labelEnd;
			string falseLabel = "NOT_FALSE" + labelEnd;
			
			$$->asmCode += "CMP " + varName + "," + "0;\n";
			$$->asmCode += "JE " + falseLabel + ";\n";
			
			$$->asmCode += "\n";
			$$->asmCode += "MOV " + newVar + "," + "0;\n";
			$$->asmCode += "JMP " + endLabel + ";\n";
			
			$$->asmCode += "\n" + falseLabel + ":\n\n";
			
			$$->asmCode += "MOV " + newVar + "," + "1;\n";
			
			$$->asmCode += "\n" + endLabel + ":\n\n";
			
			$$->varName = newVar;
			asmPrint($$,"unary_expression");
		}
		| factor 
		{
			$$ = new Sync("");
			$$->type = $1->type;
			$$->output = $1->output;
			fprintf(fplog, "At line no: %d unary_expression : factor\n\n", line_count);
			fprintf(fplog, "%s\n\n", $$->output.c_str());
			
			//ASM PART
			$$->asmCode = $1->asmCode;
			$$->varName = $1->varName;
			$$->varIndex = $1->varIndex;
			asmPrint($$,"unary_expression");
		}
		 ;
	
factor	: variable 
	{
		$$ = new Sync("");
		$$->type = $1->type;
		$$->output = $1->output;
		fprintf(fplog, "At line no: %d factor : variable\n\n", line_count);
		fprintf(fplog, "%s\n\n", $$->output.c_str());
		
		//ASM PART
		$$->asmCode = $1->asmCode;
		$$->varName = $1->varName;
		$$->varIndex = $1->varIndex;
		asmPrint($$,"factor");
	}
	| ID LPAREN argument_list RPAREN
	{
		$$ = new Sync("");
		SymbolInfo *look = table->lookUp($1->output);
		if(look == NULL || look->getType().compare("FUNCTION") != 0) {
				fprintf(fperr,"Error at Line %d : Undeclared Function: %s\n\n",line_count,$1->output.c_str());
				error_count++;
			}
		else {
			$$->type = look->paramList->front();
		}
		$$->output = $1->output + $2->output + $3->output + $4->output;
		fprintf(fplog, "At line no: %d factor : ID LPAREN argument_list RPAREN\n\n", line_count);
		fprintf(fplog, "%s\n\n", $$->output.c_str());
		
		//ASM CODE
		if(comments) $$->asmCode += ";FUNCTION CALLING\n";
		$$->asmCode += $3->asmCode;
		$$->asmCode += "CALL " + $1->output + ";\n";
		
		string newVar = newTemp();
		$$->asmCode += "MOV " + data_reg + "," + returnVar + ";\n";
		$$->asmCode += "MOV " + newVar + "," + data_reg + ";\n";
		$$->asmCode += "\n";
		
		$$->varName = newVar;
		asmPrint($$,"factor");
	}
	| LPAREN expression RPAREN
	{
		$$ = new Sync("");
		$$->output = $1->output + $2->output + $3->output;
		fprintf(fplog, "At line no: %d factor : LPAREN expression RPAREN\n\n", line_count);
		fprintf(fplog, "%s\n\n", $$->output.c_str());
		
		//ASM PART
		if(comments) $$->asmCode += ";EXPRESSION IN FIRST PARENTHESES\n";
		$$->asmCode += $2->asmCode;
		$$->varName = $2->varName;
		$$->varIndex = $2->varIndex;
		asmPrint($$,"factor");
	}
	| CONST_INT
	{
		$$ = new Sync("");
		$$->type = "INT";
		$$->output = $1->output;
		fprintf(fplog, "At line no: %d factor : CONST_INT\n\n", line_count);
		fprintf(fplog, "%s\n\n", $$->output.c_str());
		
		//ASM PART
		$$->varName = $1->output;
		if(asmDebug)  $$->printAsm("factor", line_count, "value usage: " + $$->varName + "\n");
	}
	| CONST_FLOAT
	{
		$$ = new Sync("");
		$$->type = "FLOAT";
		$$->output = $1->output;
		fprintf(fplog, "At line no: %d factor : CONST_FLOAT\n\n", line_count);
		fprintf(fplog, "%s\n\n", $$->output.c_str());
		//ASM PART
		$$->varName = $1->output;
		if(asmDebug)  $$->printAsm("factor", line_count, "value usage: " + $$->varName + "\n");
	}
	| variable INCOP 
	{
		$$ = new Sync("");
		$$->type = $1->type;
		$$->output = $1->output + $2->output;
		fprintf(fplog, "At line no: %d factor : variable INCOP\n\n", line_count);
		fprintf(fplog, "%s\n\n", $$->output.c_str());
		
		//ASM PART
		$$->asmCode = $1->asmCode;
		if(comments) $$->asmCode += ";POST-INCREMENT OPERATION\n";
		string varName = $1->varName;
		if($1->varIndex != "<none>") {
			if(!isNumber($1->varIndex)) {
				$$->asmCode += "MOV " + index_reg + "," + $1->varIndex + ";\n";
				varName += "[" + index_reg + "]";
			}
			else
				varName += "[" + $1->varIndex + "]";
		}
		string newVar = newTemp();
		$$->asmCode += "MOV " + data_reg + "," + varName + ";\n";
		$$->asmCode += "MOV " + newVar + "," + data_reg + ";\n";
		$$->varName = newVar;
		
		$$->asmCode += "INC " + varName + ";\n\n";
		asmPrint($$,"factor");
	}
	| variable DECOP
	{
		$$ = new Sync("");
		$$->type = $1->type;
		$$->output = $1->output + $2->output;
		fprintf(fplog, "At line no: %d factor : variable DECOP\n\n", line_count);
		fprintf(fplog, "%s\n\n", $$->output.c_str());
		
		//ASM PART
		$$->asmCode = $1->asmCode;
		if(comments) $$->asmCode += ";POST-DECREMENT OPERATION\n";
		string varName = $1->varName;
		if($1->varIndex != "<none>") {
			if(!isNumber($1->varIndex)) {
				$$->asmCode += "MOV " + index_reg + "," + $1->varIndex + ";\n";
				varName += "[" + index_reg + "]";
			}
			else
				varName += "[" + $1->varIndex + "]";
		}
		string newVar = newTemp();
		$$->asmCode += "MOV " + data_reg + "," + varName + ";\n";
		$$->asmCode += "MOV " + newVar + "," + data_reg + ";\n";
		$$->varName = newVar;
		
		$$->asmCode += "DEC " + varName + ";\n\n";
		asmPrint($$,"factor");
	}
	;
	
argument_list : arguments
			{
				$$ = new Sync("");
				$$->output = $1->output;
				fprintf(fplog, "At line no: %d argument_list : arguments\n\n", line_count);
				fprintf(fplog, "%s\n\n", $$->output.c_str());
				
				//ASM CODE
				if(comments) $$->asmCode += ";PASSING FUNCTION ARGUMENTS BEFORE CALLING\n";
				$$->asmCode = $1->asmCode;
				arg_counter = 0;
				if(asmDebug) $$->printAsm("argument_list",line_count);
			}
			|
			{
				$$ = new Sync("");
				$$->output = "";
				fprintf(fplog, "At line no: %d argument_list : <empty>\n\n", line_count);
				fprintf(fplog, "%s\n\n", $$->output.c_str());
				
				//ASM CODE
				arg_counter = 0;
			}
			;
	
arguments : arguments COMMA logic_expression
		{
			$$ = new Sync("");
			$$->output = $1->output + $2->output + $3->output;
			fprintf(fplog, "At line no: %d arguments : arguments COMMA logic_expression\n\n", line_count);
			fprintf(fplog, "%s\n\n", $$->output.c_str());
			
			//ASM PART
			$$->asmCode += $1->asmCode;
			string varName = $3->varName;
			if(!isNumber($3->varName)) {
				if($3->varIndex != "<none>") {
					if(!isNumber($3->varIndex)) {
						$$->asmCode += "MOV " + index_reg + "," + $3->varIndex + ";\n";
						varName += "[" + index_reg + "]";
					}
					else
						varName += "[" + $3->varIndex + "]";
				}
				$$->asmCode += "MOV " + data_reg + "," + varName + ";\n";
				varName = data_reg;
			}
			$$->asmCode += "MOV " + arg_array + "[" + to_string(arg_counter) + "]" + "," + varName + ";\n";
			arg_counter += 2;
			
			if(asmDebug) $$->printAsm("arguments",line_count);
		}
		| logic_expression
		{
			$$ = new Sync("");
			$$->output = $1->output;
			fprintf(fplog, "At line no: %d arguments : logic_expression\n\n", line_count);
			fprintf(fplog, "%s\n\n", $$->output.c_str());
			
			//ASM PART
			string varName = $1->varName;
			if(!isNumber($1->varName)) {
				if($1->varIndex != "<none>") {
					if(!isNumber($1->varIndex)) {
						$$->asmCode += "MOV " + index_reg + "," + $1->varIndex + ";\n";
						varName += "[" + index_reg + "]";
					}
					else
						varName += "[" + $1->varIndex + "]";
				}
				$$->asmCode += "MOV " + data_reg + "," + varName + ";\n";
				varName = data_reg;
			}
			$$->asmCode += "MOV " + arg_array + "[" + to_string(arg_counter) + "]" + "," + varName + ";\n";
			arg_counter += 2;
			
			if(asmDebug) $$->printAsm("arguments",line_count);
		}
		;
 

%%
int main(int argc,char *argv[])
{
	
	if((fpsrc=fopen(argv[1],"r"))==NULL)
	{
		printf("Cannot Open Input File.\n");
		exit(1);
	}

	fplog = fopen("logout.txt","w");
	fclose(fplog);
	fperr = fopen("errorout.txt","w");
	fclose(fperr);
	
	fplog = fopen("logout.txt","a");
	fperr = fopen("errorout.txt","a");
	
	yyin=fpsrc;
	yyparse();
	
	
	fclose(fplog);
	fclose(fperr);
	
	return 0;
}

