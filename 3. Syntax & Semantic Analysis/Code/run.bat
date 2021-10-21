cd %cd%
bison -d -v parser.y
g++ -std=gnu++11 -w -c -o y.o parser.tab.c
flex scannerwork.l
g++ -std=gnu++11 -w -c -o l.o lex.yy.c
g++ -std=gnu++11 -o parse y.o l.o
parse input.txt

PAUSE
rem cmd /k