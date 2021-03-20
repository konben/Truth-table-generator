%{
#include "header.h"
#include "parser.tab.h"

extern char *yytext;
%}

%%
[A-Z]       { char ind = yytext[0] - 'A'; atom_table[ind] = FALSE; yylval.atom_index = ind; return ATOM; }

and|&       return AND;
or|v        return OR;
if|->       return IMPLICATION;
iff|<->     return EQUIVALENCE;
not|~       return NOT;

[()]        return yytext[0];
[ \t]       ;
\n          return 0;
%%

int yywrap()
{
    return 1;
}
