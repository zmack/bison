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
%left '+' '-'
%left '*' '/'
%nonassoc '|' UMINUS

%type <a> exp

%%
calclist:
  | calclist exp EOL {
    printf("= %4.4g\n", eval($2));
    treefree($2);
    printf("> ");
  }
  | calclist EOL { printf("> "); }
  ;

exp:
  exp '+' exp { $$ = new_ast('+', $1, $3); }
  | exp '-' exp { $$ = new_ast('-', $1, $3); }
  | exp '*' exp { $$ = new_ast('*', $1, $3); }
  | exp '/' exp { $$ = new_ast('/', $1, $3); }
  | '|' exp     { $$ = new_ast('|', $2, NULL); }
  | '(' exp ')' { $$ = $2; }
  | '-' exp %prec UMINUS    { $$ = new_ast('M', $2, NULL); }
  | NUMBER      { $$ = new_num($1); }
  ;
%%
