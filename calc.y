%{
#include <stdio.h>
#include <stdlib.h>
%}

%token OP CP
%token NUMBER
%token ADD SUB MUL DIV ABS
%token EOL

%%

calclist:
  | EOL               { printf("Nothing :(\n"); }
  | calclist exp EOL  { printf("= %d ( 0x%x )\n", $2, $2); }
  ;

exp: factor
  | exp ADD factor { $$ = $1 + $3; }
  | exp SUB factor { $$ = $1 - $3; }
  ;


factor: term
  | factor MUL term { $$ = $1 * $3; }
  | factor DIV term { $$ = $1 / $3; }
  ;

term: NUMBER
  | ABS term  { $$ = $2 > 0 ? $2 : -$2; }
  | OP exp CP { $$ = $2; }
  ;

%%

main(int argc, char **argv) {
  yyparse();
}

yyerror(char *s) {
  fprintf(stderr, "error: %s\n", s);
}
