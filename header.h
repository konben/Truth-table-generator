enum {UNUSED=-1, FALSE=0, TRUE=1};
char atom_table[26];


// Node of the AST.
typedef struct _node
{
    int type;
    char value;
    struct _node *lval, *rval;
} node;
