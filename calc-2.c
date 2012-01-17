#include <stdio.h>
#include <stdlib.h>
#include <stdarg.h>
#include "calc-2.h"

struct ast *new_ast(int nodetype, struct ast *left, struct ast *right) {
  struct ast *a = malloc(sizeof(struct ast));

  if (!a) {
    yyerror("malloc error");
    exit(0);
  }

  a->nodetype = nodetype;
  a->left = left;
  a->right = right;

  return a;
}

struct ast *new_num(double d) {
  struct numval *a = malloc(sizeof(struct numval));

  if (!a) {
    yyerror("malloc error");
    exit(0);
  }

  a->nodetype = 'K';
  a->number = d;

  return (struct ast *)a;
}

double eval(struct ast *a) {
  double v;
  
  switch(a->nodetype) {
    case 'K':
      v = ((struct numval *)a)->number;
    break;

    case '+': v = eval(a->left) + eval(a->right); break;
    case '-': v = eval(a->left) - eval(a->right); break;
    case '*': v = eval(a->left) * eval(a->right); break;
    case '/': v = eval(a->left) / eval(a->right); break;

    case '|': v = eval(a->left); if (v < 0) v = -v; break;
    case 'M': v = -eval(a->left); break;

    default: printf("Bad node %c\n", a->nodetype);
  }

  return v;
}

void treefree(struct ast *a) {
  switch(a->nodetype) {
    case '+':
    case '-':
    case '*':
    case '/':
      treefree(a->right);

    case '|':
    case 'M':
      treefree(a->left);

    case 'K':
      free(a);
      break;

    default:
      printf("Bad node in free %c\n", a->nodetype);
  }
}

void yyerror(char *s, ...) {
  va_list ap;
  va_start(ap, s);

  fprintf(stderr, "%d: error:", yylineno);
  fprintf(stderr, s, ap);
  fprintf(stderr, "\n");
}

int main() {
  printf("> ");
  return yyparse();
}
