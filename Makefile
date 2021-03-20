LEX = flex
YACC = bison

CC = gcc

tt_generator: lex.yy.o parser.tab.o
	$(CC) -o tt_generator parser.tab.o lex.yy.o -ll

lex.yy.o: lex.yy.c parser.tab.h
	gcc -c -o lex.yy.o lex.yy.c

parser.tab.o: parser.tab.c
	gcc -c -o parser.tab.o parser.tab.c

lex.yy.c: lexer.l
	$(LEX) lexer.l

parser.tab.c parser.tab.h: parser.y
	$(YACC) -d parser.y

.PHONY: clean

clean:
	rm parser.tab.* lex.yy.* tt_generator
