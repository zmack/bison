extern int yylineno;
extern FILE *yyin;
void yyerror(char *s, ...);

struct symbol {
  char *name;
  double value;
  struct ast *function;
  struct symlist *symbols;
};

#define NHASH 9997
struct symbol symtab[NHASH];

struct symbol *lookup(char *);

struct symlist {
  struct symbol *symbol;
  struct symlist *next;
};

struct symlist *new_symlist(struct symbol *sym, struct symlist *next);
void symlist_free(struct symlist *list);

enum bifs {
  B_sqrt = 1,
  B_exp,
  B_log,
  B_print
};

struct ast {
  int nodetype;
  struct ast *left;
  struct ast *right;
};

struct fncall {
  int nodetype;
  struct ast *left;
  enum bifs function_type;
};

struct ufncall {
  int nodetype;
  struct ast *list;
  struct symbol *symbol;
};

struct flow {
  int nodetype;
  struct ast *condition;
  struct ast *happy_path;
  struct ast *sad_path;
};

struct numval {
  int nodetype;
  double number;
};

struct symref {
  int nodetype;
  struct symbol *symbol;
};

struct symbol_assign {
  int nodetype;
  struct symbol *symbol;
  struct ast *value;
};


struct ast *new_ast(int nodetype, struct ast *left, struct ast *right);
struct ast *new_cmp(int cmptype, struct ast *left, struct ast *right);
struct ast *new_function(int functype, struct ast *left);
struct ast *new_call(struct symbol *s, struct ast *left);
struct ast *new_ref(struct symbol *s);
struct ast *new_assign(struct symbol *s, struct ast *v);
struct ast *new_num(double d);
struct ast *new_flow(int nodetype, struct ast *condition, struct ast *happy, struct ast *sad);


void do_def(struct symbol *name, struct symlist *symbols, struct ast *statements);

double eval(struct ast *);

void treefree(struct ast *);
extern int yylineno;
void yyerror(char *s, ...);
