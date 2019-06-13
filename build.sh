g++ lex.yy.c yacc.tab.c -o c
bison -d yacc.y 
flex lex.l 
