%{
#include <stdlib.h>
#include <stdio.h>
#include <unistd.h>
#include "header.h"

extern int yylex();
extern FILE *yyin;

node *new_atom(char index);
node *new_operator(int op_type, node *lval, node *rval);
void fprint_tt(FILE *out, node *ast);
void yyerror(char *msg);

// Command line flags.
int binary_flag = 0;
FILE *out_file = NULL;
%}

%union {
    node *ast_node;
    char atom_index;
}

%token <atom_index> ATOM

%left IMPLICATION
%left EQUIVALENCE
%left OR
%left AND
%nonassoc NOT

%type <ast_node> boolexpr

%%
main:   boolexpr {
        fprint_tt(out_file, $1);
    }

boolexpr:   boolexpr IMPLICATION boolexpr   { $$ = new_operator(IMPLICATION, $1, $3); }
    |       boolexpr EQUIVALENCE boolexpr   { $$ = new_operator(EQUIVALENCE, $1, $3); }
    |       boolexpr OR boolexpr            { $$ = new_operator(OR, $1, $3); }
    |       boolexpr AND boolexpr           { $$ = new_operator(AND, $1, $3); }
    |       NOT boolexpr                    { $$ = new_operator(NOT, $2, NULL); }
    |       '(' boolexpr ')'                { $$ = $2; }
    |       ATOM                            { $$ = new_atom($1); } 
    ;
%%

/* Initializes a new atom-node. */
node *new_atom(char index)
{
    node *ret = (node *) malloc(sizeof(node));
    *ret = (node) {.type = ATOM, .value = index};

    return ret;
}

/* Initializes a new operator-node. */
node *new_operator(int op_type, node *lval, node *rval)
{
    node *ret = (node *) malloc(sizeof(node));
    *ret = (node) {.type = op_type, .lval = lval, .rval = rval};
    
    return ret;
}

/* Evaluates an AST. */
int eval(node *ast)
{
    switch (ast->type)
    {
    case IMPLICATION:
        return !eval(ast->lval) || eval(ast->rval);
    case EQUIVALENCE:
        {
            char l = eval(ast->lval);
            char r = eval(ast->rval);
            return (l && r) || (!l && !r);
        }
    case OR:
        return eval(ast->lval) || eval(ast->rval);
    case AND:
        return eval(ast->lval) && eval(ast->rval);
    case NOT:
        return !eval(ast->lval);
    case ATOM:
        return atom_table[ast->value];
    default:
        puts("huh?\n");
        return 0;
    }
}

/* Generates the next sequence in the truth table and returns 1 if we are finished. */
int next()
{
    for (int i = 25; i >= 0; i--)
    {
        switch (atom_table[i])
        {
        case TRUE:
            atom_table[i] = FALSE;
            break;
        case FALSE:
            atom_table[i] = TRUE;
            return 0;
        }
    }

    return 1;
}

/* Prints an AST. */
void fprint_ast(FILE *out, node *ast)
{
    switch (ast->type)
    {
    case IMPLICATION:
        fputc('(', out);
        fprint_ast(out, ast->lval); fputs(" -> ", out); fprint_ast(out, ast->rval);
        fputc(')', out);
        break;        
    case EQUIVALENCE:
        fputc('(', out);
        fprint_ast(out, ast->lval); fputs(" <-> ", out); fprint_ast(out, ast->rval);
        fputc(')', out);        
        break;
    case OR:
        fputc('(', out);
        fprint_ast(out, ast->lval); fputs(" v ", out); fprint_ast(out, ast->rval);
        fputc(')', out);
        break;
    case AND:
        fputc('(', out);
        fprint_ast(out, ast->lval); fputs(" & ", out); fprint_ast(out, ast->rval);
        fputc(')', out);
        break;
    case NOT:
        fputc('~', out); fprint_ast(out, ast->lval);
        break;
    case ATOM:
        fputc(ast->value + 'A', out);
        break;
    default:
        puts("huh?\n");
        return;
    }    
}

char bin_to_char(int v)
{
    if (binary_flag)
        return v? '1' : '0';
    return v? 'T' : 'F';
}

/* Prints a truth table. */
void fprint_tt(FILE *out, node *ast)
{
    // Print headers.
    for (int i = 0; i < 26; i++)
    {
        if (atom_table[i] != UNUSED)
            fprintf(out, "%c ", i + 'A');
    }
    fputs("| ", out);
    fprint_ast(out, ast);
    fputc('\n', out);
    // Print values.
    do {
        for (int i = 0; i < 26; i++)
        {
            if (atom_table[i] != UNUSED)
                fprintf(out, "%c ", bin_to_char(atom_table[i]));
        }
        fprintf(out, "| %c\n", bin_to_char(eval(ast)));
    } while (!next());
}

/* Opens a file, returns an error if not possible. */
FILE *open_file(char *path, char *flags)
{
    FILE *ret = fopen(path, flags);
    if (!ret)
        yyerror("could not open file");
    return ret;
}

void yyerror(char *msg)
{
    fprintf(stderr, "error: %s!\n", msg);
    exit(1);
}

int main(int argc, char **argv)
{
    out_file = stdout;

    opterr = 0;
    char c;
    while ((c = getopt(argc, argv, "bi:f:h")) != -1)
    {
        switch (c)
        {
        case 'b':
            binary_flag = 1;
            break;
        case 'i':
            yyin = open_file(optarg, "r");
            break;
        case 'f':
            out_file = open_file(optarg, "w");
            break;
        case 'h':
        case '?':
            // TODO: Write a help message.
            printf("Usage: tt_generator [arguments]\n"
                    "\n"
                    "Prints the truth-table of a boolean expression read from stdin.\n"
                    "\n"
                    "Arguments:\n"
                    "\t-b\t\tprint values as binaries.\n"
                    "\t-i <path>\tuse file as input instead of stdin.\n"
                    "\t-f <path>\tuse file as output instead of stdout.\n"
                    "\t-h\t\tprint help message.\n"
                    "\n"
                    "Notation:\n"
                    "\t&/and\t\tlogic AND\n"
                    "\tv/or\t\tlogic OR\n"
                    "\t~/not\t\tlogic NOT\n" 
                    "\t->/if\t\tlogic implication\n"
                    "\t<->/iff\t\tlogic equivalence\n"
                    "\t()\t\tparentheses\n"
                    "\n"
                    "Operator precedence(descending):\n"
                    "\t1.\t~\n"
                    "\t2.\t&\n"
                    "\t3.\tv\n"
                    "\t4.\t<->\n"
                    "\t6.\t->\n"
                    "\n"
                    "All binary operators are left associative.\n"
                );
            return 0;
        }
    }

    // Clear var table.
    for (int i = 0; i < 26; i++)
        atom_table[i] = UNUSED;

    yyparse();

    return 0;
}
