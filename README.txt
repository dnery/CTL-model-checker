# CTL Model Checker

This requires:
- Bison
- Flex
- GCC

Run:
  bison -d grammar.y

  flex lexical.l

  gcc lex.yy.c grammar.tab.c -o <executable>

  ./<executable>
