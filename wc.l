%option noyywrap
%{
  int chars = 0;
  int words = 0;
  int lines = 0;

  int chars_total = 0;
  int words_total = 0;
  int lines_total = 0;
%}

%%

[a-zA-Z]+   { words++; chars += strlen(yytext); }
\n          { chars++; lines++; }
.           { chars++; }

%%

main(int argc, char **argv) {
  int i;

  if ( argc < 2 ) {
    yylex();
    printf("%8d%8d%8d\n", lines, words, chars);
    return 0;
  }

  for ( i = 0; i < argc; i++ ) {
    FILE *f = fopen(argv[i], "r");

    if ( !f ) {
      perror(argv[i]);
      return 1;
    }

    yyrestart(f);
    yylex();
    fclose(f);

    printf("%8d%8d%8d\n", lines, words, chars);

    chars_total += chars; chars = 0;
    lines_total += lines; lines = 0;
    words_total += words; words = 0;
  }

  if ( argc > 1 ) {
    printf("%8d%8d%8d\n", lines_total, words_total, chars_total);
  }
}
