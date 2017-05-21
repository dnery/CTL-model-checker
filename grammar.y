%{
#include <stdio.h>

/* Exchange type: 1. define the exchange type */
#define YYSTYPE char *
%}

/* Precedence increases downwards */

/* 1. */
%token EOL

/* 2. */
%left LOGICAL_OR LOGICAL_AND LOGICAL_IMP LOGICAL_IFF

/* 3. */
%right LOGICAL_NOT

/* 4. */
%right CTL_AF CTL_EF CTL_AG CTL_EG CTL_AX CTL_EX CTL_AU CTL_EU

/* 5. */
%token IDENTIFIER OPAR CPAR

%%
list: /* literally nothing */
    | list EOL
    | list expr EOL
    ;

expr: logical_expr
    ;

logical_expr: unary_expr
          | logical_expr LOGICAL_OR unary_expr
          {
                printf("Logical OR.\n");
          }
          | logical_expr LOGICAL_AND unary_expr
          {
                printf("Logical AND.\n");
          }
          | logical_expr LOGICAL_IMP unary_expr
          {
                printf("Logical implication.\n");
          }
          | logical_expr LOGICAL_IFF unary_expr
          {
                printf("Logical if-only-if.\n");
          }
          ;

unary_expr: primary_expr
          | LOGICAL_NOT unary_expr
          {
               printf("Logical NOT.\n");
          }
          | CTL_AF unary_expr
          {
               printf("CTL all finally.\n");
          }
          | CTL_EF unary_expr
          {
               printf("CTL exists finally.\n");
          }
          | CTL_AG unary_expr
          {
               printf("CTL all globally.\n");
          }
          | CTL_EG unary_expr
          {
               printf("CTL exists globally.\n");
          }
          | CTL_AX unary_expr
          {
               printf("CTL all next.\n");
          }
          | CTL_EX unary_expr
          {
               printf("CTL exists next.\n");
          }
          | CTL_AU unary_expr
          {
               printf("CTL all until.\n");
          }
          | CTL_EU unary_expr
          {
               printf("CTL exists until.\n");
          }
          ;

primary_expr: IDENTIFIER
            {
                printf("Identifier %s.\n", $1);
            }
            | OPAR expr CPAR
            {
                printf("Parenthesized expr.\n");
            }
            ;
%%

/* Exchange type: 4. exchange variable is finally defined */
char *yylval;  // global: lexer retrieve
char *pgname;  // global: program name

int main(int argc, char *argv[])
{
        printf("Something happens in main...\n");
        pgname = argv[0];
        yyparse();
}

int yyerror(char *err)
{
        fprintf(stderr, "%s: %s\n", pgname, err);
}

int yywrap()
{
        return 1;
}
