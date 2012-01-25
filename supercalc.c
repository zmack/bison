#include <stdio.h>
#include <stdlib.h>
#include <stdarg.h>
#include <string.h>
#include <math.h>
#include "supercalc.h"


static unsigned symhash(char *sym)
{
  unsigned int hash = 0;
  unsigned c;

  while(c = *sym++) hash = hash*9 ^ c;

  return hash;
}

struct symbol *lookup(char *sym)
{
  struct symbol *sp = &symtab[symhash(sym) % NHASH];
  int scount = NHASH;

  while(--scount >= 0) {
    if(sp->name && !strcmp(sp->name, sym)) { return sp; }

    if(!sp->name) {
      sp->name = strdup(sym);
      sp->value = 0;
      sp->function = NULL;
      sp->symbols = NULL;
      return sp;
    }

    if(++sp >= symtab + NHASH) sp = symtab;
  }

  yyerror("symbol table overflow");
  abort();
}

struct ast *new_ast(int nodetype, struct ast *left, struct ast *right)
{
  struct ast *a = malloc(sizeof(struct ast));

  if(!a) {
    yyerror("Out of space");
    exit(0);
  }

  a->nodetype = nodetype;
  a->left = left;
  a->right = right;

  return a;
}

struct ast *new_num(double d)
{
  struct numval *a = malloc(sizeof(struct numval));
  
  if(!a) {
    yyerror("Out of space");
    exit(0);
  }

  a->nodetype = 'K';
  a->number = d;

  return (struct ast *)a;
}

struct ast *new_cmp(int cmptype, struct ast *left, struct ast *right)
{
  struct ast *a = malloc(sizeof(struct ast));

  if(!a) {
    yyerror("Out of space");
    exit(0);
  }

  a->nodetype = '0' + cmptype;
  a->left = left;
  a->right = right;

  return a;
}

struct ast *new_function(int function_type, struct ast *left)
{
  struct fncall *a = malloc(sizeof(struct fncall));

  if(!a) {
    yyerror("Out of space");
    exit(0);
  }
  a->nodetype = 'F';
  a->left = left;
  a->function_type = function_type;

  return (struct ast *)a;
}

struct ast *new_call(struct symbol *s, struct ast *list)
{
  struct ufncall *a = malloc(sizeof(struct ufncall));

  if(!a) {
    yyerror("Out of space");
    exit(0);
  }

  a->nodetype = 'C';
  a->list = list;
  a->symbol = s;

  return (struct ast *)a;
}

struct ast *new_ref(struct symbol *s)
{
  struct symref *a = malloc(sizeof(struct symref));

  if(!a) {
    yyerror("Out of space");
    exit(0);
  }

  a->nodetype = 'N';
  a->symbol = s;

  return (struct ast *)a;
}

struct ast *new_assign(struct symbol *s, struct ast *value)
{
  struct symbol_assign *a = malloc(sizeof(struct symbol_assign));

  if(!a) {
    yyerror("Out of space");
    exit(0);
  }

  a->nodetype = '=';
  a->symbol = s;
  a->value = value;

  return (struct ast *)a;
}

struct ast *new_flow(int nodetype, struct ast *condition, struct ast *then_list, struct ast *else_list)
{
  struct flow *a = malloc(sizeof(struct flow));

  if(!a) {
    yyerror("Out of space");
    exit(0);
  }

  a->nodetype = nodetype;
  a->condition = condition;
  a->happy_path = then_list;
  a->sad_path = else_list;

  return (struct ast *)a;
}

void treefree(struct ast *a)
{
  switch(a->nodetype) {
    case '+':
    case '-':
    case '*':
    case '/':
    case '%':
    case '1': case '2': case '3': case '4': case '5': case '6':
    case 'L':
      treefree(a->right);

    case '|':
    case 'M': case 'C': case 'F':
      treefree(a->left);

    case 'K': case 'N':
      break;

    case '=':
      free( ((struct symbol_assign *)a)->value);
      break;

    case 'I':
      free(((struct flow *)a)->condition);
      if(((struct flow *)a)->happy_path) treefree(((struct flow *)a)->happy_path);
      if(((struct flow *)a)->sad_path) treefree(((struct flow *)a)->sad_path);
      break;

    default:
      printf("Bad free node type %d", a->nodetype);
  }

  free(a);
}

struct symlist *new_symlist(struct symbol *symbol, struct symlist *next)
{
  struct symlist *sl = malloc(sizeof(struct symlist));

  if(!sl) {
    yyerror("Out of space");
    exit(0);
  }

  sl->symbol = symbol;
  sl->next = next;
  return sl;
}

void symlist_free(struct symlist *sl)
{
  struct symlist *nsl;
  while(sl) {
    nsl = sl->next;
    free(sl);
    sl = nsl;
  }
}

static double callbuiltin(struct fncall *);
static double calluser(struct ufncall *);

double eval(struct ast *a)
{
  double v;

  if(!a) {
    yyerror("internal error, null eval");
    return 0.0;
  }

  switch(a->nodetype) {
  case 'K':
    v = ((struct numval *)a)->number;
    break;

  case 'N':
    v = ((struct symref *)a)->symbol->value;
    break;

  case '=':
    v = ((struct symbol_assign *)a)->symbol->value = eval(((struct symbol_assign *)a)->value);
    break;

  case '+': v = eval(a->left) + eval(a->right); break;
  case '-': v = eval(a->left) - eval(a->right); break;
  case '*': v = eval(a->left) * eval(a->right); break;
  case '/': v = eval(a->left) / eval(a->right); break;
  case '%': v = fmod(eval(a->left), eval(a->right)); break;
  case '|': v = fabs(eval(a->left)); break;
  case 'M': v = -eval(a->left); break;

  case '1': v = (eval(a->left) > eval(a->right))? 1 : 0; break;
  case '2': v = (eval(a->left) < eval(a->right))? 1 : 0; break;
  case '3': v = (eval(a->left) != eval(a->right))? 1 : 0; break;
  case '4': v = (eval(a->left) == eval(a->right))? 1 : 0; break;
  case '5': v = (eval(a->left) >= eval(a->right))? 1 : 0; break;
  case '6': v = (eval(a->left) <= eval(a->right))? 1 : 0; break;

  case 'I':
    if(eval( ((struct flow *)a)->condition ) != 0) {
      if(((struct flow *)a)->happy_path) {
        v = eval(((struct flow *)a)->happy_path);
      } else {
        v = 0.0;
      }
    } else {
      if(((struct flow *)a)->sad_path) {
        v = eval(((struct flow *)a)->sad_path);
      } else {
        v = 0.0;
      }
    }
    break;

  case 'W':
    v = 0.0;

    if(((struct flow *)a)->happy_path) {
      while(eval(((struct flow *)a)->condition) != 0) {
        v = eval(((struct flow *)a)->happy_path);
      }
    }
    break;

  case 'L':
    eval(a->left);
    v = eval(a->right);
    break;

  case 'F':
    v = callbuiltin((struct fncall *)a);
    break;

  case 'C':
    v = calluser((struct ufncall *)a);
    break;

  default:
    printf("Bad node %d", a->nodetype);
  }

  return v;
}

static double callbuiltin(struct fncall *f)
{
  enum bifs functype = f->function_type;
  double v = eval(f->left);

  switch(functype) {
  case B_sqrt:
    return sqrt(v);
  case B_exp:
    return exp(v);
  case B_log:
    return log(v);
  case B_print:
    return printf("= %4.4g\n", v);
  default:
    yyerror("Unknown built-in %d", functype);
    return 0.0;
  }
}


void dodef(struct symbol *name, struct symlist *symbols, struct ast *function)
{
  if(name->symbols) symlist_free(name->symbols);
  if(name->function) treefree(name->function);

  name->symbols = symbols;
  name->function = function;
}

static double calluser(struct ufncall *f)
{
  struct symbol *fn = f->symbol;
  struct symlist *sl;
  struct ast *args = f->list;

  double *oldval, *newval;
  double v;
  int nargs;
  int i;

  if(!fn->function) {
    yyerror("call to undefined function %s", fn->name);
    return 0;
  }

  sl = fn->symbols;
  for(nargs = 0; sl; sl = sl->next) {
    nargs++;
  }

  oldval = (double *)malloc(nargs * sizeof(double));
  newval = (double *)malloc(nargs * sizeof(double));

  if(!oldval || !newval) {
    yyerror("Out of space %s", fn->name);
    return 0.0;
  }

  for(i = 0; i < nargs; i++) {
    if(!args) {
      yyerror("Too few args to call %s", fn->name);
      free(oldval); free(newval);
      return 0.0;
    }

    if(args->nodetype == 'L') {
      newval[i] = eval(args->left);
      args = args->right;
    } else {
      newval[i] = eval(args);
      args = NULL;
    }
  }

  sl = fn->symbols;
  for(i = 0; i < nargs; i++) {
    struct symbol *s = sl->symbol;

    oldval[i] = s->value;
    s->value = newval[i];
    sl = sl->next;
  }

  free(newval);

  v = eval(fn->function);

  sl = fn->symbols;
  for(i = 0; i < nargs; i++) {
    struct symbol *s = sl->symbol;
    s->value = oldval[i];
    sl = sl->next;
  }

  free(oldval);
  return v;
}

void yyerror(char *s, ...) {
  va_list ap;
  va_start(ap, s);

  fprintf(stderr, "%d: error:", yylineno);
  fprintf(stderr, s, ap);
  fprintf(stderr, "\n");
}

int main(int argc, char **argv) {
  if (argc == 1) {
    printf("> ");
    return yyparse();
  } else {
    FILE *f = fopen(argv[1], "r");
    yyin = f;
    yyparse();
    fclose(yyin);
  }
}
