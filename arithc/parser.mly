
/* parser para  Arith */

%{
  open Ast
%}

%token <int> INT
%token <string> STR
%token <string> IDENT
%token <bool>  BOOL
%token <Ast.command> CMD 
%token <Ast.operation> OPS
%token <Ast.print> PRINT
%token IF ELSE WHILE PROC IN END
%token EOF

/* Ponto de entrada da gramática */
%start prog

/* Tipo dos valores devolvidos pelo parser */
%type <Ast.program> prog

%%

prog:
| p = stmts EOF { List.rev p }

stmts:
| i = expr           { [i] }
| l = stmts i = expr { i :: l }
;

ident:
  id = IDENT { id }

expr:
| i  = INT                                     { Int  i }
| s  = STR                                     { Str  s }
| b  = BOOL                                    { Bool b }
| c  = CMD                                     { Cmd c  }
| o  = OPS                                     { Ops o  }
| prnt = PRINT                                 { Print prnt}
| id = ident                                   { Ident id }
| IF body1 = stmts ELSE body2 = stmts END      { If (body1, body2) } 
| WHILE cond = expr IN body = stmts END        { While (cond, body) }
| PROC name = ident IN body = stmts END        { Proc (name, body) }
;