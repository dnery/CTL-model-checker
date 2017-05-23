%{
/* Exchange type: 2. define also comes from tab.h */
typedef union LVAL_T {

        size_t value;
        char *name;

} lval_t;
#define YYSTYPE lval_t

#include "grammar.tab.h"

/* Exchange type: 3. defer resolution to linker */
extern lval_t yylval;
%}

%%
"|"                   { printf("%s ", yytext); return LOGICAL_OR; }                        /* Logical expression tokens */
"!"                   { printf("%s ", yytext); return LOGICAL_NOT; }
"&"                   { printf("%s ", yytext); return LOGICAL_AND; }
"->"                  { printf("%s ", yytext); return LOGICAL_IMP; }
"<->"                 { printf("%s ", yytext); return LOGICAL_IFF; }
"AF"                  { printf("%s ", yytext); return CTL_AF; }                            /* CTL command tokens */
"EF"                  { printf("%s ", yytext); return CTL_EF; }
"AG"                  { printf("%s ", yytext); return CTL_AG; }
"EG"                  { printf("%s ", yytext); return CTL_EG; }
"AX"                  { printf("%s ", yytext); return CTL_AX; }
"EX"                  { printf("%s ", yytext); return CTL_EX; }
"AU"                  { printf("%s ", yytext); return CTL_AU; }
"EU"                  { printf("%s ", yytext); return CTL_EU; }
[a-zA-Z][a-zA-Z0-9]*  { printf("%s ", yytext); yylval.name = yytext; return IDENTIFIER; }  /* Store identifier name */
","                   { printf("%s ", yytext); return COMMA; }
"("                   { printf("%s ", yytext); return OPAR; }
")"                   { printf("%s ", yytext); return CPAR; }
"\n"                  { printf("\n\n"); return EOL; }
[ \t]+                { ; }                                                                /* Ignore any whitespace */
%%
