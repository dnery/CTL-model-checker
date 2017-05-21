%{
#include <stdio.h>

/* Exchange type: 1. define the exchange type */
typedef union LVAL_T {

        size_t value;
        char *name;

} lval_t;

#define YYSTYPE lval_t

/* unique numerical id for the processing step */
size_t unique;
%}

/* Precedence increases downwards */

/* 1. */
%token IDENTIFIER OPAR CPAR COMMA EOL

/* 2. */
%left LOGICAL_OR LOGICAL_AND LOGICAL_IMP LOGICAL_IFF

/* 3. */
%right LOGICAL_NOT

/* 4. */
%right CTL_AF CTL_EF CTL_AG CTL_EG CTL_AX CTL_EX CTL_AU CTL_EU

%%
list: /* literally nothing */
    | list EOL
    | list expr EOL
    {
        unique = 0;
    }
    ;

expr: logical_expr
    {
        $$.value = $1.value;
    }
    ;

logical_expr: unary_expr
          | logical_expr LOGICAL_OR unary_expr
          {
                printf("Logical OR between %llu and %llu tagged as %llu.\n",
                $1.value, $3.value, unique);
                $$.value = unique++;
          }
          | logical_expr LOGICAL_AND unary_expr
          {
                printf("Logical AND between %llu and %llu tagged as %llu.\n",
                $1.value, $3.value, unique);
                $$.value = unique++;
          }
          | logical_expr LOGICAL_IMP unary_expr
          {
                printf("Logical implication between %llu and %llu tagged as %llu.\n",
                $1.value, $3.value, unique);
                $$.value = unique++;
          }
          | logical_expr LOGICAL_IFF unary_expr
          {
                printf("Logical if-only-if between %llu and %llu tagged as %llu.\n",
                $1.value, $3.value, unique);
                $$.value = unique++;
          }
          ;

unary_expr: primary_expr
          | LOGICAL_NOT unary_expr
          {
               printf("Logical NOT of %llu tagged as %llu.\n", $2.value,
               unique);
               $$.value = unique++;
          }
          | CTL_AF unary_expr
          {
               printf("CTL all finally of %llu tagged as %llu.\n", $2.value,
               unique);
               $$.value = unique++;
          }
          | CTL_EF unary_expr
          {
               printf("CTL exists finally of %llu tagged as %llu.\n", $2.value,
               unique);
               $$.value = unique++;
          }
          | CTL_AG unary_expr
          {
               printf("CTL all globally of %llu tagged as %llu.\n", $2.value,
               unique);
               $$.value = unique++;
          }
          | CTL_EG unary_expr
          {
               printf("CTL exists globally of %llu tagged as %llu.\n", $2.value,
               unique);
               $$.value = unique++;
          }
          | CTL_AX unary_expr
          {
               printf("CTL all next of %llu tagged as %llu.\n", $2.value,
               unique);
               $$.value = unique++;
          }
          | CTL_EX unary_expr
          {
               printf("CTL exists next of %llu tagged as %llu.\n", $2.value,
               unique);
               $$.value = unique++;
          }
          | CTL_AU unary_expr unary_expr
          {
               printf("CTL all of %llu until %llu tagged as %llu.\n", $2.value,
               $3.value, unique);
               $$.value = unique++;
          }
          | CTL_AU OPAR expr COMMA expr CPAR
          {
               printf("CTL all of %llu until %llu tagged as %llu.\n", $3.value,
               $5.value, unique);
               $$.value = unique++;
          }
          | CTL_EU unary_expr unary_expr
          {
               printf("CTL exists %llu until %llu tagged as %llu.\n", $2.value,
               $3.value, unique);
               $$.value = unique++;
          }
          | CTL_EU OPAR expr COMMA expr CPAR
          {
               printf("CTL exists %llu until %llu tagged as %llu.\n", $3.value,
               $5.value, unique);
               $$.value = unique++;
          }
          ;

primary_expr: IDENTIFIER
            {
                printf("Identifier %s tagged as %llu.\n", $1.name, unique);
                $$.value = unique++;
            }
            | OPAR expr CPAR
            {
                printf("Parenthesized expr of tag %llu.\n", $2.value);
                $$.value = $2.value;
            }
            ;
%%

/* Exchange type: 4. exchange variable is finally defined */
lval_t yylval;  // global: lexer retrieve
char *pgname;  // global: program name

int main(int argc, char *argv[])
{
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
