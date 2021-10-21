%option noyywrap

%{

#include <cstdio>
#include <cstdlib>
#include <cstring>
#include <vector>
#include "symbol_table.h"

using namespace std;

int bucketSize = 50;

int line_count=1;
int error_count = 0;

FILE *logout;
FILE *tokenout;

SymbolTable table(bucketSize);

char * strmem;

char* toUppercase(char* input) {
	delete strmem;  ///clear if allocated
	strmem = new char[strlen(input)+1];
	int i = 0;
	do {
		if(input[i] >= 'a' && input[i] <= 'z') {
			strmem[i] = input[i] - 'a' + 'A';
		}
		else {
			strmem[i] = input[i];
		}
		i++;
	} while(input[i] != '\0');
	strmem[i] = '\0';
	return strmem;
}

char* cutBorders(char* input, int left = 1, int right = 1) {
    delete strmem;  ///clear if allocated
    int len = strlen(input);
    strmem = new char[len-left-right+1];
    for(int i = 0; i < len-left-right; i++) {
        strmem[i] = input[i+left];
    }
	strmem[len-left-right] = '\0';
    return strmem;
}

char* stringProcess(char* input) {
    delete strmem;
    strmem = new char[strlen(input)+1];
    int src = 0, mem = 0;
    do {
        if(input[src] != '\\') {
            strmem[mem] = input[src];
            src++;
            mem++;
        }
        else if(input[src] == '\\') {
            switch(input[src+1]) {
            case '\n':
                src += 2;
                break;
            case 'n':
                strmem[mem] = '\n';
                src += 2;
                mem++;
                break;
            case 't':
                strmem[mem] = '\t';
                src += 2;
                mem++;
                break;
            case '\'':
                strmem[mem] = '\'';
                src += 2;
                mem++;
                break;
            case '\\':
                strmem[mem] = '\\';
                src += 2;
                mem++;
                break;
            case '\"':
                strmem[mem] = '\"';
                src += 2;
                mem++;
                break;
            case 'a':
                strmem[mem] = '\a';
                src += 2;
                mem++;
                break;
            case 'f':
                strmem[mem] = '\f';
                src += 2;
                mem++;
                break;
            case 'r':
                strmem[mem] = '\r';
                src += 2;
                mem++;
                break;
            case 'b':
                strmem[mem] = '\b';
                src += 2;
                mem++;
                break;
            case 'v':
                strmem[mem] = '\v';
                src += 2;
                mem++;
                break;
            case '0':
                strmem[mem] = '\0';
                src += 2;
                mem++;
                break;
            default:
                strmem[mem] = input[src+1];
                src += 2;
                mem++;
            }
        }
    } while(input[src] != '\0');
	strmem[mem] = '\0';
    return strmem;
}

void updateLineCount(char* input) {
    int src = 0;
    do {
        if(input[src] == '\n')
            line_count++;
        src++;
    } while(input[src] != '\0');
}

%}

WHITESPACE [ \t\f\r\v]+
LETTER [a-zA-Z]
DIGIT [0-9]
NEWLINE \n

%%

{WHITESPACE} {}

{NEWLINE} {line_count++;}

"if" 		|
"else" 		|
"for" 		|
"while" 	|
"do" 		|
"break" 	|
"int" 		|
"char" 		|
"float" 	|
"double"	|
"void" 		|
"return"	|
"switch"	|
"case" 		|
"default" 	|
"continue"	{
		fprintf(tokenout, "<%s> ", toUppercase(yytext));
		fprintf(logout,"Line No. %d: Token <%s> Lexeme %s found\n\n", line_count, toUppercase(yytext), yytext);
	}

{DIGIT}+	{

		fprintf(tokenout,"<CONST_INT,%s> ",yytext);
		fprintf(logout,"Line No. %d: Token <CONST_INT> Lexeme %s found\n\n",line_count,yytext);

		//insert in symbol table and print symbol table content(only non empty buckets)
		if(table.insert(yytext,"ID")) {
			table.printCurrentScopeTable(logout);
		}
	}

({DIGIT}*\.{DIGIT}+(E-?{DIGIT}+)?)|({DIGIT}+E{DIGIT}+)	{

		fprintf(tokenout,"<CONST_FLOAT,%s> ",yytext);
		fprintf(logout,"Line No. %d: Token <CONST_FLOAT> Lexeme %s found\n\n",line_count,yytext);

		//insert in symbol table and print symbol table content(only non empty buckets)
		if(table.insert(yytext,"ID")) {
			table.printCurrentScopeTable(logout);
		}
	}

\'[^\'\\\n\t\a\f\r\b\v]\'	{
			fprintf(tokenout,"<CONST_CHAR,%s> ",cutBorders(yytext));
			fprintf(logout,"Line No. %d: Token <CONST_CHAR> Lexeme %s found\n\n",line_count,yytext);

			//insert in symbol table and print symbol table content(only non empty buckets)
			if(table.insert(yytext,"ID")) {
				table.printCurrentScopeTable(logout);
			}
		}


\'\\(\\|\'|\")\'	{
					fprintf(tokenout,"<CONST_CHAR,%s> ",cutBorders(yytext,2));
					fprintf(logout,"Line No. %d: Token <CONST_CHAR> Lexeme %s found\n\n",line_count,yytext);

					//insert in symbol table and print symbol table content(only non empty buckets)
					if(table.insert(yytext,"ID")) {
						table.printCurrentScopeTable(logout);
					}
				}

\'\\n\'	{
			fprintf(tokenout,"<CONST_CHAR,\n> ");
			fprintf(logout,"Line No. %d: Token <CONST_CHAR> Lexeme %s found\n\n",line_count,yytext);

			//insert in symbol table and print symbol table content(only non empty buckets)
			if(table.insert(yytext,"ID")) {
				table.printCurrentScopeTable(logout);
			}
		}

\'\\t\'	{
	fprintf(tokenout,"<CONST_CHAR,\t> ");
	fprintf(logout,"Line No. %d: Token <CONST_CHAR> Lexeme %s found\n\n",line_count,yytext);

	//insert in symbol table and print symbol table content(only non empty buckets)
	if(table.insert(yytext,"ID")) {
		table.printCurrentScopeTable(logout);
	}
}

\'\\a\'	{
	fprintf(tokenout,"<CONST_CHAR,\a> ");
	fprintf(logout,"Line No. %d: Token <CONST_CHAR> Lexeme %s found\n\n",line_count,yytext);

	//insert in symbol table and print symbol table content(only non empty buckets)
	if(table.insert(yytext,"ID")) {
		table.printCurrentScopeTable(logout);
	}
}

\'\\f\'	{
	fprintf(tokenout,"<CONST_CHAR,\f> ");
	fprintf(logout,"Line No. %d: Token <CONST_CHAR> Lexeme %s found\n\n",line_count,yytext);

	//insert in symbol table and print symbol table content(only non empty buckets)
	if(table.insert(yytext,"ID")) {
		table.printCurrentScopeTable(logout);
	}
}

\'\\r\'	{
	fprintf(tokenout,"<CONST_CHAR,\r> ");
	fprintf(logout,"Line No. %d: Token <CONST_CHAR> Lexeme %s found\n\n",line_count,yytext);

	//insert in symbol table and print symbol table content(only non empty buckets)
	if(table.insert(yytext,"ID")) {
		table.printCurrentScopeTable(logout);
	}
}

\'\\b\'	{
	fprintf(tokenout,"<CONST_CHAR,\b> ");
	fprintf(logout,"Line No. %d: Token <CONST_CHAR> Lexeme %s found\n\n",line_count,yytext);

	//insert in symbol table and print symbol table content(only non empty buckets)
	if(table.insert(yytext,"ID")) {
		table.printCurrentScopeTable(logout);
	}
}

\'\\v\'	{
	fprintf(tokenout,"<CONST_CHAR,\v> ");
	fprintf(logout,"Line No. %d: Token <CONST_CHAR> Lexeme %s found\n\n",line_count,yytext);

	//insert in symbol table and print symbol table content(only non empty buckets)
	if(table.insert(yytext,"ID")) {
		table.printCurrentScopeTable(logout);
	}
}

\'\\0\'	{
	fprintf(tokenout,"<CONST_CHAR,\0> ");
	fprintf(logout,"Line No. %d: Token <CONST_CHAR> Lexeme %s found\n\n",line_count,yytext);

	//insert in symbol table and print symbol table content(only non empty buckets)
	if(table.insert(yytext,"ID")) {
		table.printCurrentScopeTable(logout);
	}
}

"+"		|

"-"		{
			fprintf(tokenout,"<ADDOP,%s> ",yytext);
			fprintf(logout,"Line No. %d: Token <ADDOP> Lexeme %s found\n\n",line_count,yytext);
		}

"*"		|
"/"		|
"%"		{
			fprintf(tokenout,"<MULOP,%s> ",yytext);
			fprintf(logout,"Line No. %d: Token <MULOP> Lexeme %s found\n\n",line_count,yytext);
		}

"++"	|
"--"	{
			fprintf(tokenout,"<INCOP,%s> ",yytext);
			fprintf(logout,"Line No. %d: Token <INCOP> Lexeme %s found\n\n",line_count,yytext);
		}

"<"		|
"<="	|
">" 	|
">=" 	|
"==" 	|
"!="	{
			fprintf(tokenout,"<RELOP,%s> ",yytext);
			fprintf(logout,"Line No. %d: Token <RELOP> Lexeme %s found\n\n",line_count,yytext);
		}

"="	{
	fprintf(tokenout,"<ASSIGNOP,%s> ",yytext);
	fprintf(logout,"Line No. %d: Token <ASSIGNOP> Lexeme %s found\n\n",line_count,yytext);
}

"&&"	|
"||"	{
			fprintf(tokenout,"<LOGICOP,%s> ",yytext);
			fprintf(logout,"Line No. %d: Token <LOGICOP> Lexeme %s found\n\n",line_count,yytext);
		}
"&"		|
"|"		|
"^" 	|
"<<"	|
">>"	{
			fprintf(tokenout,"<BITOP,%s> ",yytext);
			fprintf(logout,"Line No. %d: Token <BITOP> Lexeme %s found\n\n",line_count,yytext);
		}

"!"	{
		fprintf(tokenout,"<NOT,%s> ",yytext);
		fprintf(logout,"Line No. %d: Token <NOT> Lexeme %s found\n\n",line_count,yytext);
	}


"("	{
		fprintf(tokenout,"<LPAREN,%s> ",yytext);
		fprintf(logout,"Line No. %d: Token <LPAREN> Lexeme %s found\n\n",line_count,yytext);
	}

")"	{
		fprintf(tokenout,"<RPAREN,%s> ",yytext);
		fprintf(logout,"Line No. %d: Token <RPAREN> Lexeme %s found\n\n",line_count,yytext);
	}

"{"	{
		fprintf(tokenout,"<LCURL,%s> ",yytext);
		fprintf(logout,"Line No. %d: Token <LCURL> Lexeme %s found\n\n",line_count,yytext);
	}

"}"	{
		fprintf(tokenout,"<RCURL,%s> ",yytext);
		fprintf(logout,"Line No. %d: Token <RCURL> Lexeme %s found\n\n",line_count,yytext);
	}

"["	{
		fprintf(tokenout,"<LTHIRD,%s> ",yytext);
		fprintf(logout,"Line No. %d: Token <LTHIRD> Lexeme %s found\n\n",line_count,yytext);
	}

"]"	{
		fprintf(tokenout,"<RTHIRD,%s> ",yytext);
		fprintf(logout,"Line No. %d: Token <RTHIRD> Lexeme %s found\n\n",line_count,yytext);
	}

","	{
		fprintf(tokenout,"<COMMA,%s> ",yytext);
		fprintf(logout,"Line No. %d: Token <COMMA> Lexeme %s found\n\n",line_count,yytext);
	}

";"	{
		fprintf(tokenout,"<SEMICOLON,%s> ",yytext);
		fprintf(logout,"Line No. %d: Token <SEMICOLON> Lexeme %s found\n\n",line_count,yytext);
	}

({LETTER}|"_")({LETTER}|"_"|{DIGIT})*	{

		fprintf(tokenout,"<ID,%s> ",yytext);
		fprintf(logout,"Line No. %d: Token <ID> Lexeme %s found\n\n",line_count,yytext);

		//insert in symbol table and print symbol table content(only non empty buckets)
		if(table.insert(yytext,"ID")) {
			table.printCurrentScopeTable(logout);
		}
	}

\"([^\"\n]|"\\\""|"\\\n")*\"	{

		fprintf(tokenout,"<STRING,%s> ",stringProcess(yytext));
		fprintf(logout,"Line No. %d: Token <STRING> Lexeme %s found\n\n",line_count,yytext);
		updateLineCount(yytext);
	}

"//"([^\n]*\\\n)*[^\n]*	{

	fprintf(logout,"Line No. %d: Token <COMMENT> Lexeme %s found\n\n", line_count,yytext);
	updateLineCount(yytext);
}

"/*"([^*]|((\*)*[^/*]))*(\*)+"/"	{
	fprintf(logout,"Line No. %d: Token <COMMENT> Lexeme %s found\n\n", line_count,yytext);
	updateLineCount(yytext);
}

({DIGIT}*\.)*{DIGIT}*	{
	fprintf(logout,"Error at line %d: Too many decimal point %s\n\n",line_count,yytext);
	error_count++;
}

(({DIGIT}*\.)*{DIGIT}+(E(-|{DIGIT}|.)*)+)	{
	fprintf(logout,"Error at line %d: Ill formed number %s\n\n",line_count,yytext);
	error_count++;
}

{DIGIT}({LETTER}|"_"|{DIGIT})*	{
	fprintf(logout,"Error at line %d: Invalid prefix on ID or invalid suffix on Number %s\n\n",line_count,yytext);
	error_count++;
}

\'\'	{
	fprintf(logout,"Error at line %d: Empty character constant error_count %s\n\n",line_count,yytext);
	error_count++;
}

\'([^\'\n]|(\\\'))*	{
	fprintf(logout,"Error at line %d: Unterminated character %s\n\n",line_count,yytext);
	error_count++;
}

\'([^\'\n]|(\\\'))*\'	{
	fprintf(logout,"Error at line %d: Multi character constant error_count %s\n\n",line_count,yytext);
	error_count++;
}

\"([^\"\n]|"\\\""|"\\\n")*	{

		fprintf(logout,"Error at line %d: Unterminated String %s\n\n",line_count,yytext);
		updateLineCount(yytext);
		error_count++;
	}

"/*"([^*]|((\*)*[^/*]))*(\*)*	{
	fprintf(logout,"Error at line %d: Unterminated comment %s\n\n",line_count,yytext);
	updateLineCount(yytext);
	error_count++;
}

.	{
	fprintf(logout,"Error at line %d: Unrecognized character %s",line_count,yytext);
	error_count++;
}

%%

int main(int argc,char *argv[]){

	if(argc!=2){
		printf("Please provide input file name and try again\n");
		return 0;
	}

	FILE *fin=fopen(argv[1],"r");
	if(fin==NULL){
		printf("Cannot open specified file\n");
		return 0;
	}

	logout= fopen("log.txt","w");
	tokenout= fopen("token.txt","w");

	yyin = fin;
	yylex();
	
	fprintf(logout,"Total lines: %d\n",line_count);
	fprintf(logout,"Total error_counts: %d\n",error_count);
	
	fclose(yyin);
	fclose(tokenout);
	fclose(logout);
	return 0;
}
