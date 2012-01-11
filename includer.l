%option noyywrap
%x IFILE

%{
  struct bufstack {
    struct bufstack *prev;
    YY_BUFFER_STATE bs;
    int lineno;
    char *filename;
    FILE *f;
  } *cur_bs = 0;

  char *curfilename;

  int newfile(char *fn);
  int popfile(void);

%}

%%

^"#"[ \t]*include[ \t]*[\"<]    { BEGIN IFILE; }
<IFILE>[^ \t\n\">]+             {
                                  {
                                    int c;
                                    while ( (c = input()) && c != '\n');
                                  }
                                  yylineno++;
                                  if ( !newfile(yytext) )
                                    yyterminate();

                                  BEGIN INITIAL;
                                }
<IFILE>.|\n                     {
                                  fprintf(stderr, "%4d bad include line\n", yylineno);
                                  yyterminate();
                                }

<<EOF>>                         { if ( !popfile()) yyterminate(); }

^.                              { fprintf(yyout, "%4d %s", yylineno, yytext); }
^\n                             { fprintf(yyout, "%4d %s", yylineno++, yytext); }
\n                              { ECHO; yylineno++; }
 .                              { ECHO; }

%%

main(int argc, char **argv) {
  if ( argc < 2 ) {
    fprintf(stderr, "filename needed\n");
    return 1;
  }

  if ( newfile(argv[1]) ) {
    yylex();
  }
}

int newfile(char *fn) {
  FILE *f = fopen(fn, "r");
  printf("%s\n", fn);
  struct bufstack *bs = malloc(sizeof(struct bufstack));

  if (!f) { perror(fn); return 0; }
  if (!bs) { perror("malloc"); exit(1); }

  if ( cur_bs ) {
    cur_bs->lineno = yylineno;
  }

  bs->prev = cur_bs;

  bs->bs = yy_create_buffer(f, YY_BUF_SIZE);
  bs->f = f;
  bs->filename = fn;
  yy_switch_to_buffer(bs->bs);
  cur_bs = bs;
  yylineno = 1;
  curfilename = fn;
  return 1;
}

int popfile(void) {
  struct bufstack *bs = cur_bs;
  struct bufstack *prev_bs;

  if (!bs) return 0;

  fclose(bs->f);
  yy_delete_buffer(bs->bs);

  prev_bs = bs->prev;
  free(bs);

  if (!prev_bs) return 0;

  yy_switch_to_buffer(prev_bs->bs);
  cur_bs = prev_bs;
  yylineno = cur_bs->lineno;
  curfilename = cur_bs->filename;
  return 1;
}
