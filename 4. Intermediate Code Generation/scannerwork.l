%option noyywrap

%{

#include<iostream>
#include<cstdlib>
#include <cstdio>
#include <cstdlib>
#include <cstring>
#include "sync.h"
#include "symbol_table.h"
#include "parser.tab.h"

using namespace std;

int line_count=1;

extern YYSTYPE yylval;
extern SymbolTable *table;
void yyerror(char *);

FILE *logout;
FILE *tokenout;

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
ADDOP [+-] 
MULOP [*/%]

%%

{WHITESPACE} {}

{NEWLINE} {line_count++;}

"if" { 
		yylval = (YYSTYPE) new Sync(yytext);
		return IF;
	 }
"else"	{ 
			yylval = (YYSTYPE) new Sync(yytext);
			return ELSE;
		}
"for" { 
		yylval = (YYSTYPE) new Sync(yytext);
		return FOR;
	  }
"while" { 
			yylval = (YYSTYPE) new Sync(yytext);
			return WHILE;
		}
"int" {
		yylval = (YYSTYPE) new Sync(yytext);
		return INT;
	  }
"float"	{ 
			yylval = (YYSTYPE) new Sync(yytext);
			return FLOAT;
		}
"return" { 
			yylval = (YYSTYPE) new Sync(yytext);
			return RETURN;
		 }
"void" { 
			yylval = (YYSTYPE) new Sync(yytext);
			return VOID;
	   }

"println"	{
				yylval = (YYSTYPE) new Sync(yytext);
				return PRINTLN;
			}
			
"!"		{	
			yylval = (YYSTYPE) new Sync(yytext);
			return NOT; 
		}

{DIGIT}+	{
		
		yylval = (YYSTYPE) new Sync(yytext);
		return CONST_INT;
	}
	
({DIGIT}*\.{DIGIT}+(E-?{DIGIT}+)?)|({DIGIT}+E{DIGIT}+)	{

		yylval = (YYSTYPE) new Sync(yytext);
		return CONST_FLOAT;
	}
	
({LETTER}|"_")({LETTER}|"_"|{DIGIT})*	{
		
		yylval = (YYSTYPE) new Sync(yytext);
		return ID;
	}


{ADDOP}	{
			yylval = (YYSTYPE) new Sync(yytext);
			return ADDOP;
		}

{MULOP}	{
			yylval = (YYSTYPE) new Sync(yytext);
			return MULOP;
		}
		
","	{
		yylval = (YYSTYPE) new Sync(yytext);
		return COMMA;
	}

";"	{
		yylval = (YYSTYPE) new Sync(yytext);
		return SEMICOLON;
	}
	
"(" 	{
			yylval = (YYSTYPE) new Sync(yytext);
			return LPAREN;
		}
")" 	{
			yylval = (YYSTYPE) new Sync(yytext);
			return RPAREN;
		}
"{" 	{
			yylval = (YYSTYPE) new Sync(yytext);
			return LCURL;
		}
"}" 	{
			yylval = (YYSTYPE) new Sync(yytext);
			return RCURL;
		}
"[" 	{
			yylval = (YYSTYPE) new Sync(yytext);
			return LTHIRD;
		}
"]" 	{
			yylval = (YYSTYPE) new Sync(yytext);
			return RTHIRD;
		}
"++" 	{
			yylval = (YYSTYPE) new Sync(yytext);
			return INCOP;
		}
"--" 	{
			yylval = (YYSTYPE) new Sync(yytext);
			return DECOP;
		}

"=" 	{
			yylval = (YYSTYPE) new Sync(yytext);
			return ASSIGNOP;
		}

">" |
"<" |
">=" |
"<=" |
"==" |
"!=" {
		yylval = (YYSTYPE) new Sync(yytext);
		return RELOP;
	}
	
"&&"	|
"||"	{
			yylval = (YYSTYPE) new Sync(yytext);
			return LOGICOP;
		}




"//"([^\n]*\\\n)*[^\n]*	{
	updateLineCount(yytext);
}

"/*"([^*]|((\*)*[^/*]))*(\*)+"/"	{
	updateLineCount(yytext);
}

%%

