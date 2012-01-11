%option noyywrap nodefault yylineno case-insensitive

%{
  #define NHASH 9997

  struct symbol {
    char *name;
    struct ref *reflist;
  };

  struct ref {
    struct ref *next;
    char *filename;
    int flags;
    int lineno;
  };

  char *current_filename;
  struct symbol symbol_table[NHASH];

  struct symbol *lookup(char*);
  void addref(int, char*, char*, int);
  void printrefs();
%}
%%

"a" |
"an" |
"and" |
"are" |
"as" |
"at" |
"be" |
"but" |
"for" |
"in" |
"is" |
"it" |
"of" |
"on" |
"or" |
"that" |
"the" |
"this" |
"to"

[a-z]+(\'(\s|\t))?    { addref(yylineno, current_filename, yytext, 0); }
.|\n

%%

main(int argc, char **argv) {
  int i;

  if ( argc < 2 ) {
    current_filename = "(stdin)";
    yylineno = 1;
    yylex();
  } else {
    for( i = 1; i < argc; i++ ) {
      FILE *f = fopen(argv[i], "r");

      if (!f) {
        perror(argv[1]);
        return 1;
      }
      current_filename = argv[1];

      yyrestart(f);
      yylineno = 1;
      yylex();
      fclose(f);
    }
  }

  printrefs();
}

static unsigned symhash(char *sym) {
  unsigned int hash = 0;
  unsigned c;

  while ( c = *sym++ ) {
    hash = hash*9 ^ c;
  }

  return hash;
}

struct symbol* lookup(char *sym) {
  struct symbol *sp = &symbol_table[symhash(sym) % NHASH];
  int symbol_count = NHASH;

  while (--symbol_count > 0 ) {
    if ( sp->name && !strcmp(sp->name, sym)) return sp;

    if ( !sp->name ) {
      sp->name = strdup(sym);
      sp->reflist = 0;
      return sp;
    }

    if ( ++sp >= symbol_table + NHASH ) sp = symbol_table;
  }

  fputs("symbol table overflow\n", stderr);
  abort();
}

void addref(int lineno, char *filename, char *word, int flags) {
  struct ref *r;
  struct symbol *sp = lookup(word);

  if (sp->reflist &&
      sp->reflist->lineno == lineno &&
      sp->reflist->filename == filename) return;

  r = malloc(sizeof(struct ref));
  if (!r) {
    fputs("out of space\n", stderr);
    abort();
  }

  r->next = sp->reflist;
  r->filename = filename;
  r->lineno = lineno;
  r->flags = flags;
  sp->reflist = r;
}

static int symcompare(const void *xa, const void *xb) {
  const struct symbol *a = xa;
  const struct symbol *b = xb;

  if ( !a->name ) {
    if ( !b->name ) {
      return 0;
    } else {
      return 1;
    }
  }
  
  if ( !b->name ) {
    return -1;
  }

  return strcmp(a->name, b->name);
}

void printrefs() {
  struct symbol *sp;

  qsort(symbol_table, NHASH, sizeof(struct symbol), symcompare);

  for( sp = symbol_table; sp->name && sp < symbol_table + NHASH; sp++ ) {
    char *previous_fn = NULL;

    struct ref *rp = sp->reflist;
    struct ref *rpp = 0;
    struct ref *rpn;

    do {
      rpn = rp->next;
      rp->next = rpp;
      rpp = rp;
      rp = rpn;
    } while(rp);

    printf("%10s", sp->name);
    for( rp = rpp; rp; rp = rp->next ) {
      if ( rp->filename == previous_fn ) {
        printf(" %d", rp->lineno);
      } else {
        printf(" %s:%d", rp->filename, rp->lineno);
        previous_fn = rp->filename;
      }
    }

    printf("\n");
  }
}
