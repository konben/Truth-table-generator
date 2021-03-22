# File structure.
INC_DIR := ./inc
SRC_DIR := ./src
OBJ_DIR := ./obj
BIN_DIR := ./bin

# Compilers n' stuff.
LEX := flex
YACC := bison

FLAGS := -I$(INC_DIR)
CC := gcc

$(BIN_DIR)/tt_generator: $(OBJ_DIR)/lex.yy.o $(OBJ_DIR)/parser.tab.o
	$(CC) -o $(BIN_DIR)/tt_generator $(OBJ_DIR)/parser.tab.o $(OBJ_DIR)/lex.yy.o -ll

$(OBJ_DIR)/lex.yy.o: $(SRC_DIR)/lex.yy.c $(INC_DIR)/parser.tab.h
	gcc -c -o $(OBJ_DIR)/lex.yy.o $(SRC_DIR)/lex.yy.c $(FLAGS)

$(OBJ_DIR)/parser.tab.o: $(SRC_DIR)/parser.tab.c
	gcc -c -o $(OBJ_DIR)/parser.tab.o $(SRC_DIR)/parser.tab.c $(FLAGS)

$(SRC_DIR)/lex.yy.c: lexer.l
	mkdir $(SRC_DIR) $(OBJ_DIR) $(BIN_DIR)
	$(LEX) lexer.l
	mv lex.yy.c $(SRC_DIR)/

$(SRC_DIR)/parser.tab.c $(INC_DIR)/parser.tab.h: parser.y
	$(YACC) -d parser.y
	mv parser.tab.h $(INC_DIR)/
	mv parser.tab.c $(SRC_DIR)/

.PHONY: clean

clean:
	rm $(INC_DIR)/parser.tab.h $(SRC_DIR)/parser.tab.c $(SRC_DIR)/lex.yy.c
	rm $(OBJ_DIR)/* $(BIN_DIR)/*

