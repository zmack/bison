%option noyywrap nodefault yylineno
%{
#include "supercalc.tab.h"
%}

EXP       ([Ee][-+]?[0-9]+)

%%
"+" |
"-" |
"*" |
"/" |
"%" |
"=" |
"|" |
"," |
";" |
"(" |
")" |
"{" |
"}" { return yytext[0]; }

">"     { yylval.function = 1; return CMP; }
"<"     { yylval.function = 2; return CMP; }
"<>"    { yylval.function = 3; return CMP; }
"=="    { yylval.function = 4; return CMP; }
">="    { yylval.function = 5; return CMP; }
"<="    { yylval.function = 6; return CMP; }

"if"    { return IF; }
"then"  { return THEN; }
"else"  { return ELSE; }
"while" { return WHILE; }
"do"    { return DO; }
"let"   { return LET; }

"sqrt"    { yylval.function = B_sqrt; return FUNC; }
"exp"     { yylval.function = B_exp; return FUNC; }
"log"     { yylval.function = B_log; return FUNC; }
"print"   { yylval.function = B_print; return FUNC; }

[a-zA-Z][a-zA-Z0-9]*      { yylval.s = lookup(yytext); return NAME; }

[0-9]+"."?[0-9]*{EXP}? |
"."?[0-9]+{EXP}?          { yylval.d = atof(yytext); return NUMBER; }

"//".*
[ \t]

\\\n    { printf("c> "); }
\n      { return EOL; }
.       { yyerror("Mystery character %s\n", *yytext); }
%%
