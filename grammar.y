%{
#include <stdio.h>

/* Exchange type: 1. define the exchange type */
typedef union LVAL_T {

        size_t value;
        char *name;

} lval_t;

#define YYSTYPE lval_t

/* unique_tag numerical id for the processing step */
size_t unique_tag = 1;

size_t exproc_id(lval_t);
size_t exproc_or(lval_t, lval_t);
size_t exproc_and(lval_t, lval_t);
size_t exproc_imp(lval_t, lval_t);
size_t exproc_iff(lval_t, lval_t);
size_t exproc_not(lval_t);

size_t exproc_af(lval_t);
size_t exproc_ef(lval_t);
size_t exproc_ag(lval_t);
size_t exproc_eg(lval_t);
size_t exproc_ax(lval_t);
size_t exproc_ex(lval_t);

size_t exproc_au(lval_t);
size_t exproc_eu(lval_t);

void cleanup();
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
        cleanup();
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
                $$.value = exproc_or($1, $3);
                printf("Logical OR between %lu and %lu tagged as %lu.\n",
                $1.value, $3.value, $$.value);
          }
          | logical_expr LOGICAL_AND unary_expr
          {
                $$.value = exproc_and($1, $3);
                printf("Logical AND between %lu and %lu tagged as %lu.\n",
                $1.value, $3.value, $$.value);
          }
          | logical_expr LOGICAL_IMP unary_expr
          {
                $$.value = exproc_imp($1, $3);
                printf("Logical implication between %lu and %lu tagged as %lu.\n",
                $1.value, $3.value, $$.value);
          }
          | logical_expr LOGICAL_IFF unary_expr
          {
                $$.value = exproc_iff($1, $3);
                printf("Logical if-only-if between %lu and %lu tagged as %lu.\n",
                $1.value, $3.value, $$.value);
          }
          ;

unary_expr: primary_expr
          | LOGICAL_NOT unary_expr
          {
               $$.value = exproc_not($2);
               printf("Logical NOT of %lu tagged as %lu.\n", $2.value, $$.value);
          }
          | CTL_AF unary_expr
          {
               $$.value = exproc_af($2);
               printf("CTL all finally of %lu tagged as %lu.\n", $2.value,
               $$.value);
          }
          | CTL_EF unary_expr
          {
               $$.value = exproc_ef($2);
               printf("CTL exists finally of %lu tagged as %lu.\n", $2.value,
               $$.value);
          }
          | CTL_AG unary_expr
          {
               $$.value = exproc_ag($2);
               printf("CTL all globally of %lu tagged as %lu.\n", $2.value,
               $$.value);
          }
          | CTL_EG unary_expr
          {
               $$.value = exproc_eg($2);
               printf("CTL exists globally of %lu tagged as %lu.\n", $2.value,
               $$.value);
          }
          | CTL_AX unary_expr
          {
               printf("CTL all next of %lu tagged as %lu.\n", $2.value,
               unique_tag);
               $$.value = unique_tag++;
          }
          | CTL_EX unary_expr
          {
               printf("CTL exists next of %lu tagged as %lu.\n", $2.value,
               unique_tag);
               $$.value = unique_tag++;
          }
          | CTL_AU unary_expr unary_expr
          {
               printf("CTL all of %lu until %lu tagged as %lu.\n", $2.value,
               $3.value, unique_tag);
               $$.value = unique_tag++;
          }
          | CTL_AU OPAR expr COMMA expr CPAR
          {
               printf("CTL all of %lu until %lu tagged as %lu.\n", $3.value,
               $5.value, unique_tag);
               $$.value = unique_tag++;
          }
          | CTL_EU unary_expr unary_expr
          {
               printf("CTL exists %lu until %lu tagged as %lu.\n", $2.value,
               $3.value, unique_tag);
               $$.value = unique_tag++;
          }
          | CTL_EU OPAR expr COMMA expr CPAR
          {
               printf("CTL exists %lu until %lu tagged as %lu.\n", $3.value,
               $5.value, unique_tag);
               $$.value = unique_tag++;
          }
          ;

primary_expr: IDENTIFIER
            {
                $$.value = exproc_id($1);
                printf("Identifier %s tagged as %lu.\n", $1.name, $$.value);
            }
            | OPAR expr CPAR
            {
                printf("Parenthesized expr of tag %lu.\n", $2.value);
                $$.value = $2.value;
            }
            ;
%%


#include <stdlib.h>
#include <string.h>


/* Node type for graph holds properties as strings */
typedef struct NODE_T {

        size_t unique_tags;  // unique expression tags
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
        unique_tag <<= 1;

        printf("  Where's %s.\n", lval.name);

        for (size_t inode = 0; inode < am_dims; inode++)
                for (size_t iprop = 0; iprop < am_nodes[inode].nprops; iprop++)
                        if (!strcmp(am_nodes[inode].props[iprop], lval.name)) {
                                am_nodes[inode].unique_tags |= unique_tag;
                                printf("    Tagged %lu.\n", inode+1);
                                break;
                        }

        return unique_tag;
}

size_t exproc_or(lval_t lva, lval_t lvb)
{
        unique_tag <<= 1;

        printf("  Where's %lu OR %lu.\n", lva.value, lvb.value);

        for (size_t inode = 0; inode < am_dims; inode++)
                if((am_nodes[inode].unique_tags & lva.value) ||
                   (am_nodes[inode].unique_tags & lvb.value)) {
                        am_nodes[inode].unique_tags |= unique_tag;
                        printf("    Tagged %lu.\n", inode+1);
                }

        return unique_tag;
}

size_t exproc_and(lval_t lva, lval_t lvb)
{
        unique_tag <<= 1;

        printf("  Where's %lu AND %lu.\n", lva.value, lvb.value);

        for (size_t inode = 0; inode < am_dims; inode++)
                if((am_nodes[inode].unique_tags & lva.value) &&
                   (am_nodes[inode].unique_tags & lvb.value)) {
                        am_nodes[inode].unique_tags |= unique_tag;
                        printf("    Tagged %lu.\n", inode+1);
                }

        return unique_tag;
}

size_t exproc_imp(lval_t lva, lval_t lvb)
{
        unique_tag <<= 1;

        printf("  Where's %lu -> %lu.\n", lva.value, lvb.value);

        for (size_t inode = 0; inode < am_dims; inode++)
                if(!(am_nodes[inode].unique_tags & lva.value) ||
                   (am_nodes[inode].unique_tags & lvb.value)) {
                        am_nodes[inode].unique_tags |= unique_tag;
                        printf("    Tagged %lu.\n", inode+1);
                }

        return unique_tag;
}

size_t exproc_iff(lval_t lva, lval_t lvb)
{
        size_t decomp_a = exproc_imp(lva, lvb);
        size_t decomp_b = exproc_imp(lvb, lva);

        unique_tag <<= 1;

        printf("  Where's %lu <-> %lu.\n", lva.value, lvb.value);

        for (size_t inode = 0; inode < am_dims; inode++)
                if((am_nodes[inode].unique_tags & decomp_a) &&
                   (am_nodes[inode].unique_tags & decomp_b)) {
                        am_nodes[inode].unique_tags |= unique_tag;
                        printf("    Tagged %lu.\n", inode+1);
                }

        return unique_tag;
}

size_t exproc_not(lval_t lval)
{
        unique_tag <<= 1;

        printf("  Where's not %lu.\n", lval.value);

        for (size_t inode = 0; inode < am_dims; inode++)
                if(!(am_nodes[inode].unique_tags & lval.value)) {
                        am_nodes[inode].unique_tags |= unique_tag;
                        printf("    Tagged %lu.\n", inode+1);
                }

        return unique_tag;
}

size_t exproc_af(lval_t lval)
{
        lval_t expr_builder;

        // AF(p) = not(EG(not(p)))
        expr_builder.value = exproc_not(lval);
        expr_builder.value = exproc_eg(expr_builder);
        expr_builder.value = exproc_not(expr_builder);

        return expr_builder.value;
}

size_t exproc_ef(lval_t lval)
{
        lval_t expr_builder;

        // EF(p) = not(AG(not(p)))
        expr_builder.value = exproc_not(lval);
        expr_builder.value = exproc_ag(expr_builder);
        expr_builder.value = exproc_not(expr_builder);

        return expr_builder.value;
}

size_t exproc_ag(lval_t lval)
{
        unique_tag <<= 1;
        size_t local_tag = unique_tag;

        printf("  Is %lu everywhere? ", lval.value);

        // AG or all-across-all-paths means every node, basically
        for (size_t inode = 0; inode < am_dims; inode++) {
                if (!(am_nodes[inode].unique_tags & lval.value)) {
                        unique_tag >>= 1;
                        local_tag = 0;
                        break;
                }
        }

        printf("%s.\n", (local_tag ? "Yes" : "No"));

        // Tag all the nodes unconditionally
        for (size_t inode = 0; inode < am_dims; inode++)
                am_nodes[inode].unique_tags |= local_tag;

        // The return key is either unique or always False
        return local_tag;
}

// TODO can this be defined inside exproc_eg?
char _exproc_eg_dfs(size_t inode, size_t value, char *visited)
{
        visited[inode] = 1;

        // If condition is not satisfacted, return immediately
        if (!(am_nodes[inode].unique_tags & value))
                return 0;

        // If there's neighbours, then at least one must succeed
        char has_invalid_paths = 0;
        for (size_t inext = 0; inext < am_dims; inext++) {

                if (am_graph[inode*am_dims+inext]) {                                    // if it's a neighbour (including self)...

                        if (visited[inext] && (am_nodes[inext].unique_tags & value)) {  // if it's visited and has the property, it's a loop...
                                printf("    EG stack: success for %lu. Returning.\n", inode+1);
                                return 1;
                        }
                        if (!visited[inext] && _exproc_eg_dfs(inext, value, visited)) { // if it's unvisited and the recursive call succeeds...
                                printf("    EG stack: success for %lu. Returning.\n", inode+1);
                                return 1;
                        }
                        has_invalid_paths = 1;                                          // if theres neighbours, but all turn out invalid, no success...
                }
        }

        if (!has_invalid_paths)
                printf("    EG stack: success on shallow check for %lu.\n", inode+1);

        // If neighbours were found but all fail, then fail self as well
        return !has_invalid_paths;
}

size_t exproc_eg(lval_t lval)
{
        unique_tag <<= 1;
        size_t local_tag = unique_tag;

        printf("  Where's EG(%lu).\n", lval.value);

        // Array of visits for the DF search
        char *visited = calloc(am_dims, 1);

        // Generate a unique tag only if expr is true
        if (!_exproc_eg_dfs(0, lval.value, visited)) {
                unique_tag >>= 1;
                local_tag = 0;
        }

        free(visited);

        // Tag all the nodes unconditionally
        for (size_t inode = 0; inode < am_dims; inode++)
                am_nodes[inode].unique_tags |= local_tag;

        // The return key is either unique or always False
        return local_tag;
}

void print_node_info()
{
        printf("\nPrinting: graph node info\n\n");

        // Print: adj-matrix nodes
        for (size_t inode = 0; inode < am_dims; inode++) {
                printf("Node %lu:", inode+1);

                printf("\n  Has neighbours: ");
                for (size_t inext = 0; inext < am_dims; inext++)
                        if (am_graph[inode*am_dims+inext])
                                printf("%lu ", inext+1);

                printf("\n  Has properties: ");
                for (size_t iprop = 0; iprop < am_nodes[inode].nprops; iprop++)
                        printf("%s ", am_nodes[inode].props[iprop]);

                printf("\n  Tagged with: ");
                size_t all_tags = unique_tag;
                while (all_tags > 1) {
                        if (all_tags & am_nodes[inode].unique_tags)
                                printf("%lu ", all_tags);
                        all_tags >>= 1;
                }

                printf("\n");
        }
}

int main(int argc, char *argv[])
{
        pgname = argv[0];

        /*
         * Read graph
         */
        printf("\nReading graph...\n\n");

        // Read: number of nodes in graph
        scanf("%lu", &am_dims);
        am_graph = calloc(am_dims * am_dims, 1);
        am_nodes = malloc(am_dims * sizeof(*am_nodes));

        // Read: nodes in graph
        for (size_t inode = 0; inode < am_dims; inode++) {

                // Current node
                size_t currentnode;
                scanf("%lu", &currentnode);

                // Following nodes
                size_t nnextnodes;
                size_t nodereader;

                // Following props
                size_t nnextprops;
                char   propreader[2048];

                // Read: n next props
                scanf("%lu", &nnextprops);
                am_nodes[currentnode-1].unique_tags = 1;
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
                scanf("%lu", &nnextnodes);

                // Read: next nodes
                for (size_t inode = 0; inode < nnextnodes; inode++) {
                        scanf("%lu", &nodereader);
                        size_t idx = (currentnode-1)*am_dims+nodereader-1;
                        am_graph[idx] = 1;
                }
        }

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

        printf("\nBegin CTL expression parsing...\n\n");

        yyparse();

        printf("\nParsing successful. Doing other stuff...\n\n");

        /*
         * Free graph
         */
        printf("Deallocating graph...\n\n");

        // Free: node props
        for (size_t inode = 0; inode < am_dims; inode++) {
                for (size_t iprop = 0; iprop < am_nodes[inode].nprops; iprop++)
                        free(am_nodes[inode].props[iprop]);
                free(am_nodes[inode].props);

                printf("  Freed node %lu prop array.\n", inode+1);
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
        return 1;
}

/* Called when parsing reaches EOF */
int yywrap()
{
        return 1;
}

/* High-level expression cleanup */
void cleanup()
{
        print_node_info();  // show me the goods before you leave

        for (size_t inode = 0; inode < am_dims; inode++)
                am_nodes[inode].unique_tags = 1;

        unique_tag = 1;
}
