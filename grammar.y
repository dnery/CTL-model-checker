%{
#include <stdio.h>

/* Exchange type: 1. define the exchange type */
typedef union LVAL_T {

        size_t value;
        char *name;

} lval_t;

#define YYSTYPE lval_t

/* uniq_tag numerical id for the processing step */
size_t uniq_tag = 1;

size_t exproc_id(lval_t);

size_t exproc_or(lval_t);
size_t exproc_and(lval_t);
size_t exproc_imp(lval_t);
size_t exproc_iff(lval_t);
size_t exproc_not(lval_t);

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
                $1.value, $3.value, uniq_tag);
                $$.value = uniq_tag++;
          }
          | logical_expr LOGICAL_AND unary_expr
          {
                printf("Logical AND between %llu and %llu tagged as %llu.\n",
                $1.value, $3.value, uniq_tag);
                $$.value = uniq_tag++;
          }
          | logical_expr LOGICAL_IMP unary_expr
          {
                printf("Logical implication between %llu and %llu tagged as %llu.\n",
                $1.value, $3.value, uniq_tag);
                $$.value = uniq_tag++;
          }
          | logical_expr LOGICAL_IFF unary_expr
          {
                printf("Logical if-only-if between %llu and %llu tagged as %llu.\n",
                $1.value, $3.value, uniq_tag);
                $$.value = uniq_tag++;
          }
          ;

unary_expr: primary_expr
          | LOGICAL_NOT unary_expr
          {
               $$.value = exproc_not($2);
               printf("Logical NOT of %llu tagged as %llu.\n", $2.value, $$.value);
          }
          | CTL_AF unary_expr
          {
               printf("CTL all finally of %llu tagged as %llu.\n", $2.value,
               uniq_tag);
               $$.value = uniq_tag++;
          }
          | CTL_EF unary_expr
          {
               printf("CTL exists finally of %llu tagged as %llu.\n", $2.value,
               uniq_tag);
               $$.value = uniq_tag++;
          }
          | CTL_AG unary_expr
          {
               printf("CTL all globally of %llu tagged as %llu.\n", $2.value,
               uniq_tag);
               $$.value = uniq_tag++;
          }
          | CTL_EG unary_expr
          {
               printf("CTL exists globally of %llu tagged as %llu.\n", $2.value,
               uniq_tag);
               $$.value = uniq_tag++;
          }
          | CTL_AX unary_expr
          {
               printf("CTL all next of %llu tagged as %llu.\n", $2.value,
               uniq_tag);
               $$.value = uniq_tag++;
          }
          | CTL_EX unary_expr
          {
               printf("CTL exists next of %llu tagged as %llu.\n", $2.value,
               uniq_tag);
               $$.value = uniq_tag++;
          }
          | CTL_AU unary_expr unary_expr
          {
               printf("CTL all of %llu until %llu tagged as %llu.\n", $2.value,
               $3.value, uniq_tag);
               $$.value = uniq_tag++;
          }
          | CTL_AU OPAR expr COMMA expr CPAR
          {
               printf("CTL all of %llu until %llu tagged as %llu.\n", $3.value,
               $5.value, uniq_tag);
               $$.value = uniq_tag++;
          }
          | CTL_EU unary_expr unary_expr
          {
               printf("CTL exists %llu until %llu tagged as %llu.\n", $2.value,
               $3.value, uniq_tag);
               $$.value = uniq_tag++;
          }
          | CTL_EU OPAR expr COMMA expr CPAR
          {
               printf("CTL exists %llu until %llu tagged as %llu.\n", $3.value,
               $5.value, uniq_tag);
               $$.value = uniq_tag++;
          }
          ;

primary_expr: IDENTIFIER
            {
                $$.value = exproc_id($1);
                printf("Identifier %s tagged as %llu.\n", $1.name, $$.value);
            }
            | OPAR expr CPAR
            {
                printf("Parenthesized expr of tag %llu.\n", $2.value);
                $$.value = $2.value;
            }
            ;
%%


#include <stdlib.h>
#include <string.h>


/* Node type for graph holds properties as strings */
typedef struct NODE_T {

        size_t uniq_tags;  // unique expression tags
        size_t nprops;     // number of props
        char **props;      // props as strings

} node_t;

char   *am_graph;  // global: adj-matrix graph (as a vector)
node_t *am_nodes;  // global: adj-matrix graph nodes
size_t  am_dims;   // golbal: adj-matrix dimensions


/* Exchange type: 4. exchange variable is finally defined */
lval_t yylval;  // global: lexer retrieve
char  *pgname;  // global: program name

size_t exproc_id(lval_t lval)
{
        uniq_tag <<= 1;

        printf("  Where's %s.\n", lval.name);

        for (size_t inode = 0; inode < am_dims; inode++)
                for (size_t iprop = 0; iprop < am_nodes[inode].nprops; iprop++)
                        if (!strcmp(am_nodes[inode].props[iprop], lval.name)) {
                                am_nodes[inode].uniq_tags |= uniq_tag;
                                printf("    Tagged %llu.\n", inode+1);
                                break;
                        }

        return uniq_tag;
}

size_t exproc_not(lval_t lval)
{
        uniq_tag <<= 1;

        printf("  Where's not %llu.\n", lval.value);

        for (size_t inode = 0; inode < am_dims; inode++)
                if(!(am_nodes[inode].uniq_tags & lval.value)) {
                        am_nodes[inode].uniq_tags |= uniq_tag;
                        printf("    Tagged %llu.\n", inode+1);
                }

        return uniq_tag;
}

int main(int argc, char *argv[])
{
        pgname = argv[0];

        /*
         * Read graph
         */
        printf("\nReading graph...\n\n");

        // Read: number of nodes in graph
        scanf("%llu", &am_dims);
        am_graph = calloc(am_dims * am_dims, 1);
        am_nodes = malloc(am_dims * sizeof(*am_nodes));

        // Read: nodes in graph
        for (size_t inode = 0; inode < am_dims; inode++) {

                // Current node
                size_t currentnode;
                scanf("%llu", &currentnode);

                // Following nodes
                size_t nnextnodes;
                size_t nodereader;

                // Following props
                size_t nnextprops;
                char   propreader[2048];

                // Read: n next props
                scanf("%llu", &nnextprops);
                am_nodes[currentnode-1].uniq_tags = 1;
                am_nodes[currentnode-1].nprops = nnextprops;
                am_nodes[currentnode-1].props = malloc(nnextprops *
                                sizeof(*(am_nodes[currentnode-1].props)));

                // Read: next props
                for (size_t iprop = 0; iprop < nnextprops; iprop++) {
                        scanf("%s", propreader);
                        am_nodes[currentnode-1].props[iprop] =
                                        malloc(strlen(propreader) + 1);
                        strcpy(am_nodes[currentnode-1].props[iprop], propreader);
                }

                // Read: n next nodes
                scanf("%llu", &nnextnodes);

                // Read: next nodes
                for (size_t inode = 0; inode < nnextnodes; inode++) {
                        scanf("%llu", &nodereader);
                        size_t idx = (currentnode-1)*am_dims+nodereader-1;
                        am_graph[idx] = 1;
                }
        }

        printf("Begin CTL expression parsing...\n\n");

        yyparse();

        printf("\nParsing successful. Doing other stuff...\n\n");

        /*
         * Print graph
         */
        printf("\nPrinting: graph adj-matrix\n\n");

        // Print: adj-matrix graph
        for (size_t inode = 0; inode < am_dims; inode++) {
                for (size_t inext = 0; inext < am_dims; inext++)
                        printf("%d ", am_graph[inode*am_dims+inext]);
                printf("\n");
        }

        printf("\nPrinting: graph node info\n\n");

        // Print: adj-matrix nodes
        for (size_t inode = 0; inode < am_dims; inode++) {
                printf("Node %d:", inode+1);

                printf("\n  Has neighbours: ");
                for (size_t inext = 0; inext < am_dims; inext++)
                        if (am_graph[inode*am_dims+inext])
                                printf("%llu ", inext+1);

                printf("\n  Has properties: ");
                for (size_t iprop = 0; iprop < am_nodes[inode].nprops; iprop++)
                        printf("%s ", am_nodes[inode].props[iprop]);

                printf("\n  Has been tagged with: ");
                size_t all_tags = uniq_tag;
                while (all_tags > 1) {
                        if (all_tags & am_nodes[inode].uniq_tags)
                                printf("%llu ", all_tags);
                        all_tags >>= 1;
                }

                printf("\n");
        }

        /*
         * Free graph
         */
        printf("\nDeallocating graph...\n\n");

        // Free: node props
        for (size_t inode = 0; inode < am_dims; inode++) {
                for (size_t iprop = 0; iprop < am_nodes[inode].nprops; iprop++)
                        free(am_nodes[inode].props[iprop]);
                free(am_nodes[inode].props);

                printf("  Freed node %llu prop array.\n", inode+1);
        }

        // Free: nodes & graph
        free(am_nodes);
        free(am_graph);
        printf("  Freed node array and adj-matrix.\n\n");

        return 0;
}

/* Called when syntax error is found */
int yyerror(char *err)
{
        fprintf(stderr, "%s: %s\n", pgname, err);
}

/* Called when parsing reaches EOF */
int yywrap()
{
        return 1;
}
