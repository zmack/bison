#pragma once

extern int yylineno;
void yyerror(char *s, ...);

struct ast {
  int nodetype;
  struct ast *left;
  struct ast *right;
};

struct numval {
  int nodetype;
  double number;
};

struct ast *new_ast(int nodetype, struct ast *left, struct ast *right);
struct ast *new_num(double d);

double eval(struct ast *);
void treefree(struct ast *);
