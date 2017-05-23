# CTL Model Checker

This requires:
- Bison
- Flex
- GCC


Provide the parser with an FSM in an established KISS format,
followed by CTL expressions to evaluate. Any number of CTL expressions
can be input for parsing. An input file can be provided or the data can
be given directly through standard input.


An example file `oven_large.txt` is provided for testing. The evaluator is
guaranteed to work _at least_ for the expressions present in the file :).


To run it:
```
bison -d grammar.y                               # generate parser
flex lexical.l                                   # generate lexer
gcc lex.yy.c grammar.tab.c -lfl -o <executable>  # link everything
./<executable> [optional_input_file]             # run the executable
```
