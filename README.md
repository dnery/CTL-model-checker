# CTL Model Checker

This requires:
- Bison
- Flex
- GCC

To build it:
```
bison -d grammar.y                              # generate parser
flex lexical.l                                  # generate lexer
gcc lex.yy.c grammar.tab.c -o <executable>      # link everything
./<executable>                                  # run the executable
```
