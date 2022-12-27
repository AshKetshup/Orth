

(* Lexer para Arith *)

{
  open Lexing
  open Parser

  exception Lexing_error of char

  (*
  let id_or_kwd =
    let h = Hashtbl.create 32 in
    List.iter (fun (s, tok) -> Hashtbl.add h s tok)
      ["dup",DUP; "swap",SWAP; "drop",DROP; 
      "print",PRINT; "over",OVER; "rot",ROT
      "if", IF; "else", ELSE;
      "while", WHILE; "in", IN;
      "true", CST (Cbool true);
      "false", CST (Cbool false);
  fun s -> try Hashtbl.find h s with Not_found -> IDENT s
  *)
  let kwd_tbl = ["dup",DUP; "swap",SWAP; "drop",DROP; 
                 "print",PRINT; "over",OVER; "rot",ROT;
                 "true", BOOL (true); "false", BOOL (false);
                ]
                 (*
                 "if", IF; "else", ELSE;
                 "while", WHILE; "in", IN;]
                 *)
  let id_or_kwd s = try List.assoc s kwd_tbl with _ -> IDENT s


}

let letter = ['a'-'z' 'A'-'Z']
let digit = ['0'-'9']
let ident = letter (letter | digit)*
let integer = ['0'-'9']+
let space = [' ' '\t']

rule token = parse
  | '\n'    { new_line lexbuf; token lexbuf }
  | "#" [^'\n']* '\n' { new_line lexbuf; token lexbuf }
  | space+  { token lexbuf }
  | ident as id { id_or_kwd id }
  | '+'     { PLUS }
  | '-'     { MINUS }
  | '*'     { TIMES }
  | '/'     { DIV }
  | '='     { EQ }
  | integer as s { INT (int_of_string s) }
  | eof     { EOF }
  | _ as c  { raise (Lexing_error c) }
