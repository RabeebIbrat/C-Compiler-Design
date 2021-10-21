cd %cd%
flex scannerwork.l
del lex.yy.cpp
rename lex.yy.c lex.yy.cpp
g++ lex.yy.cpp
a input.txt
