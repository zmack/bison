%{
#include <stdio.h>
#include <stdlib.h>
#include "calc-2.h"
%}

%union {
  struct ast *a;
  double d;
};

%token <d> NUMBER
%token EOL

%type <a> exp factor term

%%
calclist:
  | calclist exp EOL {
    printf("= %4.4g\n", eval($2));
    treefree($2);
    printf("> ");
  }
  | calclist EOL { printf("> "); }
  ;

exp: factor
  | exp '+' factor { $$ = new_ast('+', $1, $3); }
  | exp '-' factor { $$ = new_ast('-', $1, $3); }
  ;

factor: term
  | factor '*' term { $$ = new_ast('*', $1, $3); }
  | factor '/' term { $$ = new_ast('/', $1, $3); }
  ;

term: NUMBER { $$ = new_num($1); }
  | '|' term { $$ = new_ast('|', $2, NULL); }
  | '(' exp ')' { $$ = $2; }
  | '-' term { $$ = new_ast('M', $2, NULL); }
  ;
%%
