%{
  #include "calc.tab.h"
%}
%%

"+"     { return ADD; }
"-"     { return SUB; }
"*"     { return MUL; }
"/"     { return DIV; }
"|"     { return ABS; }
[0-9]+  { yylval = atol(yytext); return NUMBER; }
"0x"[a-f0-9]+ { yylval = strtol(yytext, 0, 16); return NUMBER; }
"\n"    { return EOL; }
[ \t]   { }
"("     { return OP; }
")"     { return CP; }
"//".*  { }
.       { printf("Mystery character %s", yytext); }

%%
