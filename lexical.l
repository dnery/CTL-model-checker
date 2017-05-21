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
"|"                     return LOGICAL_OR;      /* Logical expression tokens */
"!"                     return LOGICAL_NOT;
"&"                     return LOGICAL_AND;
"->"                    return LOGICAL_IMP;
"<->"                   return LOGICAL_IFF;
"AF"                    return CTL_AF;          /* CTL command tokens */
"EF"                    return CTL_EF;
"AG"                    return CTL_AG;
"EG"                    return CTL_EG;
"AX"                    return CTL_AX;
"EX"                    return CTL_EX;
"AU"                    return CTL_AU;
"EU"                    return CTL_EU;
[a-zA-Z][a-zA-Z0-9]*  { yylval.name = yytext;
                        return IDENTIFIER; }  /* Store identifier name */
","                     return COMMA;
"("                     return OPAR;
")"                     return CPAR;
"\n"                    return EOL;
[ \t]+                  ;                       /* Ignore any whitespace */
%%
