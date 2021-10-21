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

FILE *fpsrc, *fplog, *fperr;

int yyparse(void);
int yylex(void);
extern FILE *yyin;
extern int line_count;

int bucketSize = 50;
SymbolTable *table = new SymbolTable(bucketSize);
bool skipEnterScope = false;

deque<string> *func_type_list = NULL;
deque<string> *func_name_list = NULL;

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
	}
	;

program : program unit 
	{
		$$->output = $1->output + "\n" + $2->output;
		fprintf(fplog, "At line no: %d program : program unit\n\n", line_count);
		fprintf(fplog, "%s\n\n", $$->output.c_str());
	}
	| unit
	{
		$$->output = $1->output;
		fprintf(fplog, "At line no: %d program : unit\n\n", line_count);
		fprintf(fplog, "%s\n\n", $$->output.c_str());
	}
	;
	
unit : var_declaration
		{
			$$->output = $1->output;
			fprintf(fplog, "At line no: %d unit : var_declaration\n\n", line_count);
			fprintf(fplog, "%s\n\n", $$->output.c_str());
		}
		| func_declaration
		{
			$$->output = $1->output;
			fprintf(fplog, "At line no: %d unit : func_declaration\n\n", line_count);
			fprintf(fplog, "%s\n\n", $$->output.c_str());
		}
		| func_definition
		{
			$$->output = $1->output;
			fprintf(fplog, "At line no: %d unit : func_definition\n\n", line_count);
			fprintf(fplog, "%s\n\n", $$->output.c_str());
		}
		| compound_statement
		{
			$$->output = $1->output;
			fprintf(fplog, "At line no: %d unit : compound_statement\n\n", line_count);
			fprintf(fplog, "%s\n\n", $$->output.c_str());
		}
     ;
     
func_declaration : type_specifier ID LPAREN parameter_list RPAREN SEMICOLON
		{
			$$ = $4;
			if(!$$->declareFunc($1->var_type,$2->output,table)) {
				fprintf(fperr,"Error at line %d: Multiple declaration of %s\n\n", line_count, $2->output.c_str());
			}
			if(!$$->paramExists->empty()) {
				string exists;
				while(!$$->paramExists->empty()) {
					exists = $$->paramExists->front();
					$$->paramExists->pop_front();
					fprintf(fperr,"Error at line %d: Multiple usage of %s as argument of function %s\n\n", line_count, $2->output.c_str());
				}
			}
			$$->output = $1->output + " " + $2->output + $3->output + $4->output + $5->output +  $6->output;
			fprintf(fplog, "At line no: %d func_declaration : type_specifier ID LPAREN parameter_list RPAREN SEMICOLON\n\n", line_count);
			fprintf(fplog, "%s\n\n", $$->output.c_str());
		}
		| type_specifier ID LPAREN RPAREN SEMICOLON
		{
			$$ = new Sync("");
			if(!$$->declareFunc($1->var_type,$2->output,table)) {
				fprintf(fperr,"Error at line %d: Multiple declaration of %s\n\n", line_count, $2->output.c_str());
			}
			$$->output = $1->output + " " + $2->output + $3->output + $4->output + $5->output;
			fprintf(fplog, "At line no: %d func_declaration : type_specifier ID LPAREN RPAREN SEMICOLON\n\n", line_count);
			fprintf(fplog, "%s\n\n", $$->output.c_str());
		}
		;
		 
func_definition : type_specifier ID LPAREN parameter_list RPAREN 
		{
			$$ = $4;
			functionState state = $$->defineFuncTop($1->var_type, $2->output, table);
			switch(state) {
			case functionState::mulDeclare:
				fprintf(fperr,"Error at line %d: Multiple declaration of %s\n\n", line_count, $2->output.c_str());
				break;
			case functionState::mulDef:
				fprintf(fperr,"Error at line %d: Multiple definition of %s\n\n", line_count, $2->output.c_str());
				break;
			case functionState::manyLessArgs:
				fprintf(fperr,"Error at line %d: Too many or too less arguments for function %s\n\n", line_count, $2->output.c_str());
				break;
			case functionState::unmatchedArgs:
				fprintf(fperr,"Error at line %d: Argument mismatch for function %s\n\n", line_count, $2->output.c_str());
				break;
			}
			if(!$$->paramExists->empty()) {
				string exists;
				while(!$$->paramExists->empty()) {
					exists = $$->paramExists->front();
					$$->paramExists->pop_front();
					fprintf(fperr,"Error at line %d: Multiple usage of %s as argument of function %s\n\n", line_count, $2->output.c_str());
				}
			}
			if($$->unnamed_parameter) {
				fprintf(fperr,"Error at line %d: Unnnamed argument(s) in definition of function %s\n\n", line_count, $2->output.c_str());
			}
			func_type_list = $$->type_list;
			func_name_list = $$->name_list;
		}
			function_body
		{
			$$->output = $1->output + " " + $2->output + $3->output + $4->output + $5->output + " " + $7->output;
			fprintf(fplog, "At line no: %d func_definition : type_specifier ID LPAREN parameter_list RPAREN function_body\n\n", line_count);
			fprintf(fplog, "%s\n\n", $$->output.c_str());
		}
		| type_specifier ID LPAREN RPAREN {
			$$ = new Sync("");
			functionState state = $$->defineFuncTop($1->var_type, $2->output, table);
			switch(state) {
			case functionState::mulDeclare:
				fprintf(fperr,"Error at line %d: Multiple declaration of %s\n\n", line_count, $2->output.c_str());
				break;
			case functionState::mulDef:
				fprintf(fperr,"Error at line %d: Multiple definition of %s\n\n", line_count, $2->output.c_str());
				break;
			case functionState::manyLessArgs:
				fprintf(fperr,"Error at line %d: Too many or too less arguments for function %s\n\n", line_count, $2->output.c_str());
				break;
			case functionState::unmatchedArgs:
				fprintf(fperr,"Error at line %d: Argument mismatch for function %s\n\n", line_count, $2->output.c_str());
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
		}
 		;				

function_body : LCURL
		{
			table->enterScope();
			fprintf(fplog," New ScopeTable with id %d created\n\n", table->getCurrentScopeId());
			$$ = new Sync("");
			$$->type_list = func_type_list;
			$$->name_list = func_name_list;
			$$->defineFuncBody(table);
		}
			RCURL {
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
			$$ = new Sync("");
			$$->type_list = func_type_list;
			$$->name_list = func_name_list;
			$$->defineFuncBody(table);
			
		}
			statements RCURL
		{
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
				table->enterScope();
				fprintf(fplog," New ScopeTable with id %d created\n\n", table->getCurrentScopeId());
			}
				statements RCURL
			{
				$$->output = $1->output + '\n' + $2->output + '\n' + $3->output;
				fprintf(fplog, "At line no: %d compound_statement : LCURL statements RCURL\n\n", line_count);
				fprintf(fplog, "%s\n\n", $$->output.c_str());
				table->printAllScopeTable(fplog);
				fprintf(fplog," ScopeTable with id %d removed\n\n", table->getCurrentScopeId());
				table->exitScope();
			}
 		    | LCURL RCURL
 		    ;
 		    
var_declaration : type_specifier declaration_list SEMICOLON
		{
			$$ = $2;
			$$->var_type = $1->var_type;
			if(!$$->flushVarList(table)) {
				if($1->var_type.compare("VOID") == 0) {
					fprintf(fperr,"Error at line %d: Variables cannot be declared as void\n\n", line_count);
				}
				else if(!$$->varExists->empty()) {
					string exists;
					while(!$$->varExists->empty()) {
						exists = $$->varExists->front();
						$$->varExists->pop_front();
						fprintf(fperr,"Error at line %d: Multiple declaration of %s\n\n", line_count, exists.c_str());
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
				else
					fprintf(fperr,"Error at line %d : Non-integer Array Index\n\n", line_count);
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
				else
					fprintf(fperr,"Error at line %d : Non-integer Array Index\n\n", line_count);
				$$ = $1;
				$$->output = $1->output + $2->output + $3->output + $4->output; 
				fprintf(fplog, "At line no: %d declaration_list : ID LTHIRD CONST_INT RTHIRD\n\n", line_count);
				fprintf(fplog, "%s\n\n", $$->output.c_str());
			  }
			  ;
 		  
statements : statement
		{
			$$->output = $1->output;
			fprintf(fplog, "At line no: %d statements : statement\n\n", line_count);
			fprintf(fplog, "%s\n\n", $$->output.c_str());

		}
		| statements statement
		{
			$$->output = $1->output + "\n" + $2->output;
			fprintf(fplog, "At line no: %d statements : statements statement\n\n", line_count);
			fprintf(fplog, "%s\n\n", $$->output.c_str());
		}
	   ;
	   
statement : var_declaration
		{
			$$->output = $1->output;
			fprintf(fplog, "At line no: %d statement : var_declaration\n\n", line_count);
			fprintf(fplog, "%s\n\n", $$->output.c_str());
		}
		| expression_statement
		{
			$$->output = $1->output;
			fprintf(fplog, "At line no: %d statement : expression_statement\n\n", line_count);
			fprintf(fplog, "%s\n\n", $$->output.c_str());
		}
		| compound_statement
		{
			$$->output = $1->output;
			fprintf(fplog, "At line no: %d statement : compound_statement\n\n", line_count);
			fprintf(fplog, "%s\n\n", $$->output.c_str());
		}
		| FOR LPAREN expression_statement expression_statement expression RPAREN statement
		{
			$$->output = $1->output + $2->output + $3->output + $4->output + $5->output + $6->output + $7->output;
			fprintf(fplog, "At line no: %d statement : FOR LPAREN expression_statement expression_statement expression RPAREN statement\n\n", line_count);
			fprintf(fplog, "%s\n\n", $$->output.c_str());
		}
		| IF LPAREN expression RPAREN statement
		{
			$$->output = $1->output + $2->output + $3->output + $4->output + $5->output;
			fprintf(fplog, "At line no: %d statement : IF LPAREN expression RPAREN statement\n\n", line_count);
			fprintf(fplog, "%s\n\n", $$->output.c_str());
		}
		| IF LPAREN expression RPAREN statement ELSE statement
		{
			$$->output = $1->output + $2->output + $3->output + $4->output + $5->output + $6->output + $7->output;
			fprintf(fplog, "At line no: %d statement : IF LPAREN expression RPAREN statement ELSE statement\n\n", line_count);
			fprintf(fplog, "%s\n\n", $$->output.c_str());
		}
		| WHILE LPAREN expression RPAREN statement
		{
			$$->output = $1->output + $2->output + $3->output + $4->output + $5->output;
			fprintf(fplog, "At line no: %d statement : WHILE LPAREN expression RPAREN statement\n\n", line_count);
			fprintf(fplog, "%s\n\n", $$->output.c_str());
		}
		| PRINTLN LPAREN ID RPAREN SEMICOLON
		{
			$$->output = $1->output + $2->output + $3->output + $4->output + $5->output;
			fprintf(fplog, "At line no: %d statement : PRINTLN LPAREN ID RPAREN SEMICOLON\n\n", line_count);
			fprintf(fplog, "%s\n\n", $$->output.c_str());
		}
		| RETURN expression SEMICOLON
		{
			$$->output = $1->output + " " + $2->output + $3->output;
			fprintf(fplog, "At line no: %d statement : RETURN expression SEMICOLON\n\n", line_count);
			fprintf(fplog, "%s\n\n", $$->output.c_str());
		}
	  ;
	  
expression_statement : SEMICOLON
			{
				$$->output = $1->output;
				fprintf(fplog, "At line no: %d expression_statement : SEMICOLON\n\n", line_count);
				fprintf(fplog, "%s\n\n", $$->output.c_str());
			}
			| expression SEMICOLON
			{
				$$->output = $1->output + $2->output;
				fprintf(fplog, "At line no: %d expression_statement : expression SEMICOLON\n\n", line_count);
				fprintf(fplog, "%s\n\n", $$->output.c_str());
			}
			;
	  
variable : ID
		{
			SymbolInfo* look = table->lookUp($1->output);
			if(look == NULL) {
				fprintf(fperr,"Error at Line %d : Undeclared Variable: %s\n\n",line_count,$1->output.c_str());
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
		}
		| ID LTHIRD expression RTHIRD 
		{
			SymbolInfo* look = table->lookUp($1->output);
			if(look == NULL) {
				fprintf(fperr,"Error at Line %d : Undeclared Variable: %s\n\n",line_count,$1->output.c_str());
				$$->type = "";
			}
			else {
				$$->type = look->getType();
				if(look->getSize() < 0)
					fprintf(fperr,"Error at line %d : Type Mismatch\n\n", line_count);
			}
			if($3->type != "INT") {
				fprintf(fperr,"Error at Line %d : Non-integer Array Index \n\n",line_count);
			}
			$$->output = $1->output + $2->output + $3->output + $4->output;
			fprintf(fplog, "At line no: %d variable : ID LTHIRD expression RTHIRD\n\n", line_count);
			fprintf(fplog, "%s\n\n", $$->output.c_str());
		}
	 ;
	 
expression : logic_expression
		{
			$$->type = $1->type;
			$$->output = $1->output;
			fprintf(fplog, "At line no: %d expression : logic_expression\n\n", line_count);
			fprintf(fplog, "%s\n\n", $$->output.c_str());
		}
		| variable ASSIGNOP logic_expression
		{
			if($1->type.compare("") != 0 && $3->type.compare("") != 0 && $1->type.compare($3->type) != 0) {
				if($1->type.compare("FLOAT") == 0 && $3->type.compare("INT") == 0);
				else 
					fprintf(fperr,"Error at line %d : Type Mismatch\n\n", line_count);
			}
			$$->output = $1->output + $2->output + $3->output;
			fprintf(fplog, "At line no: %d expression : variable ASSIGNOP logic_expression\n\n", line_count);
			fprintf(fplog, "%s\n\n", $$->output.c_str());
		}
	   ;
			
logic_expression : rel_expression 
		{
			$$->type = $1->type;
			$$->output = $1->output;
			fprintf(fplog, "At line no: %d logic_expression : rel_expression \n\n", line_count);
			fprintf(fplog, "%s\n\n", $$->output.c_str());
		}
		| rel_expression LOGICOP rel_expression
		{
			$$->output = $1->output + $2->output + $3->output;
			fprintf(fplog, "At line no: %d logic_expression : rel_expression LOGICOP rel_expression\n\n", line_count);
			fprintf(fplog, "%s\n\n", $$->output.c_str());
		}
		;
			
rel_expression	: simple_expression
		{
			$$->type = $1->type;
			$$->output = $1->output;
			fprintf(fplog, "At line no: %d rel_expression : simple_expression\n\n", line_count);
			fprintf(fplog, "%s\n\n", $$->output.c_str());
		}
		| simple_expression RELOP simple_expression
		{
			$$->output = $1->output + $2->output + $3->output;
			fprintf(fplog, "At line no: %d rel_expression : simple_expression RELOP rel_expression\n\n", line_count);
			fprintf(fplog, "%s\n\n", $$->output.c_str());
		}
		;
				
simple_expression : term 
		{
			$$->type = $1->type;
			$$->output = $1->output;
			fprintf(fplog, "At line no: %d simple_expression : term \n\n", line_count);
			fprintf(fplog, "%s\n\n", $$->output.c_str());
		}
		| simple_expression ADDOP term
		{	
			if($1->type.compare("") != 0 && $3->type.compare("") != 0 && $1->type.compare($3->type) != 0) {
				if( ($1->type.compare("INT") == 0 || $1->type.compare("FLOAT") == 0) && ($3->type.compare("FLOAT") == 0 || $3->type.compare("INT") == 0) );
				else
					fprintf(fperr,"Error at line %d : Type Mismatch\n\n", line_count);
			}
			$$->output = $1->output + $2->output + $3->output;
			fprintf(fplog, "At line no: %d simple_expression : simple_expression ADDOP term\n\n", line_count);
			fprintf(fplog, "%s\n\n", $$->output.c_str());
		}		
		  ;
					
term :	unary_expression
		{
			$$->type = $1->type;
			$$->output = $1->output;
			fprintf(fplog, "At line no: %d term : unary_expression\n\n", line_count);
			fprintf(fplog, "%s\n\n", $$->output.c_str());
		}
		|  term MULOP unary_expression
		{
			if($2->output.compare("%") == 0 && ($1->type.compare("INT") != 0 || $3->type.compare("INT") != 0)) {
				fprintf(fperr,"Error at line: %d : Integer operand on modulus operator\n\n", line_count);
			}
			else if($1->type.compare("") != 0 && $3->type.compare("") != 0 && $1->type.compare($3->type) != 0) {
				if( ($1->type.compare("INT") == 0 || $1->type.compare("FLOAT") == 0) && ($3->type.compare("FLOAT") == 0 || $3->type.compare("INT") == 0) );
				else
					fprintf(fperr,"Error at line %d : Type Mismatch\n\n", line_count);
			}
			$$->output = $1->output + $2->output + $3->output;
			fprintf(fplog, "At line no: %d term : term MULOP unary_expression\n\n", line_count);
			fprintf(fplog, "%s\n\n", $$->output.c_str());
		}
     ;

unary_expression : ADDOP unary_expression
		{
			$$->type = $2->type;
			$$->output = $1->output + $2->output;
			fprintf(fplog, "At line no: %d unary_expression : ADDOP unary_expression\n\n", line_count);
			fprintf(fplog, "%s\n\n", $$->output.c_str());
		}
		| NOT unary_expression
		{
			$$->type = $2->type;
			$$->output = $1->output + $2->output;
			fprintf(fplog, "At line no: %d unary_expression : NOT unary_expression\n\n", line_count);
			fprintf(fplog, "%s\n\n", $$->output.c_str());
		}
		| factor 
		{
			$$->type = $1->type;
			$$->output = $1->output;
			fprintf(fplog, "At line no: %d unary_expression : factor\n\n", line_count);
			fprintf(fplog, "%s\n\n", $$->output.c_str());
		}
		 ;
	
factor	: variable 
	{
		$$->type = $1->type;
		$$->output = $1->output;
		fprintf(fplog, "At line no: %d factor : variable\n\n", line_count);
		fprintf(fplog, "%s\n\n", $$->output.c_str());
	}
	| ID LPAREN argument_list RPAREN
	{
		SymbolInfo *look = table->lookUp($1->output);
		if(look == NULL || look->getType().compare("FUNCTION") != 0) {
				fprintf(fperr,"Error at Line %d : Undeclared Function: %s\n\n",line_count,$1->output.c_str());
			}
		else {
			$$->type = look->paramList->front();
		}
		$$->output = $1->output + $2->output + $3->output + $4->output;
		fprintf(fplog, "At line no: %d factor : ID LPAREN argument_list RPAREN\n\n", line_count);
		fprintf(fplog, "%s\n\n", $$->output.c_str());
	}
	| LPAREN expression RPAREN
	{
		$$->output = $1->output + $2->output + $3->output;
		fprintf(fplog, "At line no: %d factor : LPAREN expression RPAREN\n\n", line_count);
		fprintf(fplog, "%s\n\n", $$->output.c_str());
	}
	| CONST_INT
	{
		$$->type = "INT";
		$$->output = $1->output;
		fprintf(fplog, "At line no: %d factor : CONST_INT\n\n", line_count);
		fprintf(fplog, "%s\n\n", $$->output.c_str());
	}
	| CONST_FLOAT
	{
		$$->type = "FLOAT";
		$$->output = $1->output;
		fprintf(fplog, "At line no: %d factor : CONST_FLOAT\n\n", line_count);
		fprintf(fplog, "%s\n\n", $$->output.c_str());
	}
	| variable INCOP 
	{
		$$->type = $1->type;
		$$->output = $1->output + $2->output;
		fprintf(fplog, "At line no: %d factor : variable INCOP\n\n", line_count);
		fprintf(fplog, "%s\n\n", $$->output.c_str());
	}
	| variable DECOP
	{
		$$->type = $1->type;
		$$->output = $1->output + $2->output;
		fprintf(fplog, "At line no: %d factor : variable DECOP\n\n", line_count);
		fprintf(fplog, "%s\n\n", $$->output.c_str());
	}
	;
	
argument_list : arguments
			{
				$$->output = $1->output;
				fprintf(fplog, "At line no: %d argument_list : arguments\n\n", line_count);
				fprintf(fplog, "%s\n\n", $$->output.c_str());
			}
			|
			{
				$$->output = "";
				fprintf(fplog, "At line no: %d argument_list : <empty>\n\n", line_count);
				fprintf(fplog, "%s\n\n", $$->output.c_str());
			}
			;
	
arguments : arguments COMMA logic_expression
		{
			$$->output = $1->output + $2->output + $3->output;
			fprintf(fplog, "At line no: %d arguments : arguments COMMA logic_expression\n\n", line_count);
			fprintf(fplog, "%s\n\n", $$->output.c_str());
		}
		| logic_expression
		{
			$$->output = $1->output;
			fprintf(fplog, "At line no: %d arguments : logic_expression\n\n", line_count);
			fprintf(fplog, "%s\n\n", $$->output.c_str());
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

