%{
#include <stdio.h>
#include <stdlib.h>
#include "supercalc.h"
%}

%union {
  struct ast *a;
  double d;
  struct symbol *s;
  struct symlist *sl;
  int function;
}

%token <d> NUMBER;
%token <s> NAME;
%token <function> FUNC;
%token EOL
%token IF THEN ELSE WHILE DO LET

%nonassoc <function> CMP
%right '='
%left '+' '-'
%left '*' '/'
%nonassoc '|' UMINUS

%type <a> exp stmt list explist
%type <sl> symlist

%start calclist

%%

stmt: IF exp THEN list                { $$ = new_flow('I', $2, $4, NULL); }
  | IF exp THEN list ELSE list        { $$ = new_flow('I', $2, $4, $6); }
  | WHILE exp DO list                 { $$ = new_flow('W', $2, $4, NULL); }
  | exp
  ;

list:             { $$ = NULL; }
  | stmt ';' list {
                    if ($3 == NULL) {
                      $$ = $1;
                    } else {
                      $$ = new_ast('L', $1, $3);
                    }
                  }
  ;

exp: exp CMP exp              { $$ = new_cmp($2, $1, $3); }
  | exp '+' exp               { $$ = new_ast('+', $1, $3); }
  | exp '-' exp               { $$ = new_ast('-', $1, $3); }
  | exp '*' exp               { $$ = new_ast('*', $1, $3); }
  | exp '/' exp               { $$ = new_ast('/', $1, $3); }
  | '|' exp                   { $$ = new_ast('|', $2, NULL); }
  | '(' exp ')'               { $$ = $2 }
  | '-' exp %prec UMINUS      { $$ = new_ast('M', $2, NULL); }
  | NUMBER                    { $$ = new_num($1); }
  | NAME                      { $$ = new_ref($1); }
  | NAME '=' exp              { $$ = new_assign($1, $3); }
  | FUNC '(' explist ')'      { $$ = new_function($1, $3); }
  | NAME '(' explist ')'      { $$ = new_call($1, $3); }
  ;

explist: exp
  | exp ',' explist           { $$ = new_ast('L', $1, $3); }
  ;

symlist: NAME                 { $$ = new_symlist($1, NULL); }
  | NAME ',' symlist          { $$ = new_symlist($1, $3); }
  ;

calclist:
  | calclist stmt EOL         {
                                printf("= %4.4g\n>", eval($2));
                                treefree($2);
                              }
  | calclist LET NAME '(' symlist ')' '=' list EOL {
                                dodef($3, $5, $8);
                                printf("Defined %s\n>", $3->name);
                              }
  | calclist error EOL        { yyerrok; printf(">"); }
  ;
