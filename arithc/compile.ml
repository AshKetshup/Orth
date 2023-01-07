(* Produção de código para a linguagem Arith *)

open Format
open X86_64
open Ast

(* TIPAGEM *)
type types = Tint | Tbool | Tstr

exception TypeError of string


let types_to_str = function
  | Tint  -> "[Int]"
  | Tbool -> "[Bool]"
  | Tstr  -> "[Str]"

let cmd_to_str = function
  | Ops Add   -> "<Add>"
  | Ops Sub   -> "<Sub>"
  | Ops Mul   -> "<Mul>"
  | Ops Div   -> "<Div>"
  | Ops Mod   -> "<Mod>"
  | Ops Min   -> "<Min>"
  | Ops Max   -> "<Max>"
  | Ops Neg   -> "<Neg>"
  | Ops Equal -> "<Equal>"
  | Ops Diff  -> "<Diff>"
  | Ops Gt    -> "<Gt>"
  | Ops Ge    -> "<Ge>"
  | Ops Lt    -> "<Lt>"
  | Ops Le    -> "<Le>"
  | Ops And   -> "<And>"
  | Ops Or    -> "<Or>"
  | Cmd Dup   -> "<Dup>"
  | Cmd Swap  -> "<Swap>"
  | Cmd Drop  -> "<Drop>"
  | Cmd Over  -> "<Over>"
  | Cmd Rot   -> "<Rot>"
  | Print Printi -> "<Printi>"
  | Print Printb -> "<Printb>"
  | Print Prints -> "<Prints>"
  | _ -> failwith "Erro: Entrei aqui!"

let rec print_stack st = 
  match st with
  | [] -> "\n"
  | t1 :: rest -> (types_to_str t1) ^ " " ^ (print_stack rest)

let binop_exc cmd t1 t2 =
  match cmd with
  | Ops Add | Ops Sub | Ops Mul | Ops Div | Ops Mod | Ops Min | Ops Max ->
    (cmd_to_str cmd) ^ " necessita de [Int, Int] no fundo da pilha, mas foram encontrados: " ^ (types_to_str t1) ^ ", " ^ (types_to_str t2)
  | Ops Equal | Ops Diff | Ops Gt | Ops Lt | Ops Ge | Ops Le | Ops And | Ops Or -> 
    (cmd_to_str cmd) ^ " necessita de [Int, Int] ou [Bool, Bool] no fundo da pilha, mas foram encontrados: " ^ (types_to_str t1) ^ ", " ^ (types_to_str t2)
  | _ -> failwith "Erro: Entrei aqui!"

let unop_exc cmd t1 =
  match cmd with
  | Ops Neg -> 
    (cmd_to_str cmd) ^ " necessita de [Int] ou [Bool] no fundo da pilha, mas foi encontrado: " ^ (types_to_str t1)
  | Cmd Dup ->
    (cmd_to_str cmd) ^ " necessita de [Int], [Bool] ou [Str] no fundo da pilha, mas foi encontrado: " ^ (types_to_str t1)
  | _ -> failwith "Erro: Entrei aqui!"
  
let print_exc cmd t1 =
  match cmd with
  | Print Printi -> "[Int], mas foi encontrado: " ^ (types_to_str t1)
  | Print Printb -> "[Bool], mas foi encontrado: " ^ (types_to_str t1)
  | Print Prints -> "[Str], mas foi encontrado: " ^ (types_to_str t1)
  | _ -> failwith "Erro: Entrei aqui!"
  

let need_two_elems cmd = (cmd_to_str cmd) ^ " requer pelo menos dois elementos no fundo da pilha."
let need_one_elems cmd = (cmd_to_str cmd) ^ " requer pelo menos um elemento no fundo da pilha."

let push_type = function
  | Ops Add | Ops Sub | Ops Mul | Ops Div | Ops Mod | Ops Min | Ops Max | Ops Neg -> [Tint]
  | Ops Equal | Ops Diff | Ops Gt | Ops Lt | Ops Ge | Ops Le | Ops And | Ops Or   -> [Tbool]
  | _ -> failwith "Erro: Entrei aqui!"

let type_binop_arith st cmd = 
  match st with
  | Tint :: Tint :: rest -> (push_type cmd) @ rest
  | t1 :: t2 :: rest     -> raise (TypeError (binop_exc cmd t1 t2))
  | _                    -> raise (TypeError (need_two_elems cmd))

let type_binop_comp st cmd = 
  match st with
  | Tint :: Tint :: rest   -> (push_type cmd) @ rest
  | Tbool :: Tbool :: rest -> (push_type cmd) @ rest
  | t1 :: t2 :: rest       -> raise (TypeError (binop_exc cmd t1 t2))
  | _                      -> raise (TypeError (need_two_elems cmd))

let type_unop_cmd st cmd =
  match st with
  | Tint :: rest                -> (push_type cmd) @ rest
  | Tbool :: rest               -> (push_type cmd) @ rest
  | t1 :: rest                  -> raise (TypeError (unop_exc cmd t1))
  | _                           -> raise (TypeError (need_one_elems cmd))

let type_binop_cmd st cmd = 
  match st with
  | t1 :: rest when cmd = Cmd Dup        -> t1 :: t1 :: rest
  | t1 :: rest when cmd = Cmd Drop       -> rest
  | t1 :: t2 :: rest when cmd = Cmd Swap -> t2 :: t1 :: rest
  | t1 :: t2 :: rest when cmd = Cmd Over -> t1 :: t2 :: t1 :: rest
  | t1 :: t2 :: t3 :: rest when cmd = Cmd Rot -> t1 :: t3 :: t2 :: rest
  | _ when cmd = Cmd Dup || cmd = Cmd Drop    -> raise (TypeError ((cmd_to_str cmd) ^ " requer pelo menos e apenas um [Int], [Bool] ou [Str]."))
  | _                                    -> raise (TypeError (need_two_elems cmd))


let type_unop_print st cmd =
  match st with
  | Tint :: rest when cmd = Print Printi -> rest
  | Tbool :: rest when cmd = Print Printb -> rest
  | Tstr :: rest when cmd = Print Prints -> rest
  | t1 :: rest -> raise (TypeError ((cmd_to_str cmd) ^ " aceita apenas elementos do tipo " ^ (print_exc cmd t1)))
  | _ -> raise (TypeError ((cmd_to_str cmd) ^ " requer pelo menos um elemento no fundo da pilha."))

let check_if_cond st =
  match st with
  | Tbool :: rest -> rest
  | t1 :: rest -> raise (TypeError ("<If> requer um [Bool] no fundo da pilha, mas foi encontrado: " ^ (types_to_str t1)))
  | _ -> failwith "Erro: Entrei aqui!"

let check_while_cond st =
  match st with
  | Tbool :: rest -> rest
  | t1 :: rest -> raise (TypeError ("<While> requer um [Bool] no corpo da condicao, mas foi encontrado: " ^ (types_to_str t1)))
  | _ -> failwith "Erro: Entrei aqui!"

(*
*)
let rec type_program st cmd = 
  match cmd with
  | Ops Add | Ops Sub | Ops Mul | Ops Div | Ops Mod | Ops Min | Ops Max -> type_binop_arith st cmd
  | Ops Equal | Ops Diff | Ops Gt | Ops Lt | Ops Ge | Ops Le | Ops And | Ops Or -> type_binop_comp st cmd
  | Cmd Dup | Cmd Swap | Cmd Drop | Cmd Over | Cmd Rot -> type_binop_cmd st cmd
  | Print Printi | Print Printb | Print Prints -> type_unop_print st cmd
  | Ops Neg -> type_unop_cmd st cmd
  | _ -> failwith "Erro: Entrei aqui!"

(*
let type_program st cmd =
  match cmd with
  | _ -> st
   *)
(* TIPAGEM *)


(* Exceção por lançar quando uma variável (local ou global) é mal utilizada *)
exception VarUndef of string


(*a tabela de variáveis guarda uma string (nome da variável) e um inteiro. O inteiro serve para identificar se é um int ou bool, ou uma string.
   Caso seja uma string o inteiro serve para guardar o str_index, número que identifica a label da string.
   Caso seja int ou bool é igual a -1*)
let (var_tbl : (string, int) Hashtbl.t) = Hashtbl.create 17
let (str_tbl : (int, string) Hashtbl.t) = Hashtbl.create 17

let str_index = ref 0
let ifelse_index = ref 0
let ifthen_index = ref 0
let while_index = ref 0
let label_count = ref 0
let stack_types = ref []
let procs_tbl = Hashtbl.create 17

(* Utiliza-se  uma tabela associativa cujas chaves são as variáveis locais
   (strings) cujo valor associado é a posição da variável relativamente
   a $fp/%rsb (em bytes)
*)
module StrMap = Map.Make(String)

let compile_print = function
  | Printi -> 
    (* Print de debug *)
    Printf.printf "PRINTI ";
    Printf.printf "%s" (print_stack !stack_types);
    (* Atualizar stack de tipos *)
    stack_types := (type_program !stack_types (Print Printi));
    (* Assembly do printi*)
    popq rdi ++
    call "print_int"

  | Printb -> 
    (* Print de debug *)
    Printf.printf "PRINTB  ";
    Printf.printf "%s" (print_stack !stack_types);
    (* Atualizar stack de tipos *)
    stack_types := (type_program !stack_types (Print Printb));
    (* Assembly do printb*)
    popq rdi ++
    call "print_bool"

  | Prints -> 
    (* Print de debug *)
    Printf.printf "PRINTS  ";
    Printf.printf "%s" (print_stack !stack_types);
    (* Atualizar stack de tipos *)
    stack_types := (type_program !stack_types (Print Prints));
    (* Assembly do prints*)
    popq rdi ++
    call "print_str"

let compile_cmds = function
  | Dup   -> 
    (* Print de debug *)
    Printf.printf "DUP  "; 
    Printf.printf "%s" (print_stack !stack_types);
    (* Atualizar stack de tipos *)
    stack_types := (type_program !stack_types (Cmd Dup));
    (* Assembly*)
    popq rdi ++
    pushq !%rdi ++
    pushq !%rdi

  | Swap  -> 
    (* Print de debug *)
    Printf.printf "SWAP  ";
    Printf.printf "%s" (print_stack !stack_types);
    (* Atualizar stack de tipos *)
    stack_types := (type_program !stack_types (Cmd Swap));
    (* Assembly*)
    popq rdi ++
    popq rsi ++
    pushq !%rdi ++
    pushq !%rsi 

  | Drop  -> 
    (* Print de debug *)
    Printf.printf "DROP  ";
    Printf.printf "%s" (print_stack !stack_types);
    (* Atualizar stack de tipos *)
    stack_types := (type_program !stack_types (Cmd Drop));
    (* Assembly*)
    popq rdi

  | Over  -> 
    (* Print de debug *)
    Printf.printf "Over  ";
    Printf.printf "%s" (print_stack !stack_types);
    (* Atualizar stack de tipos *)
    stack_types := (type_program !stack_types (Cmd Over));
    (* Assembly*)
    popq rdi ++
    popq rsi ++
    pushq !%rsi ++
    pushq !%rdi ++
    pushq !%rsi

  | Rot   -> 
    (* Print de debug *)
    Printf.printf "ROT  ";
    Printf.printf "%s" (print_stack !stack_types);
    (* Atualizar stack de tipos *)
    stack_types := (type_program !stack_types (Cmd Rot));
    (* Assembly*)
    popq rdi ++ 
    popq rsi ++ 
    popq rcx ++ 
    pushq !%rsi ++ 
    pushq !%rdi ++ 
    pushq !%rcx    

let compile_ops = function
  (* Aritmetica *)
  | Add   -> 
            (* Print de debug *)
            Printf.printf "Add  "; 
            Printf.printf "%s" (print_stack !stack_types);
            (* Atualizar stack de tipos *)
            stack_types := (type_program !stack_types (Ops Add));
            (* Assembly*)
            popq rbx ++
            popq rax ++
            addq !%rbx !%rax ++
            pushq !%rax
  | Sub   -> 
            (* Print de debug *)
            Printf.printf "Sub  "; 
            Printf.printf "%s" (print_stack !stack_types);
            (* Atualizar stack de tipos *)
            stack_types := (type_program !stack_types (Ops Sub));
            (* Assembly*)
            popq rbx ++
            popq rax ++
            subq !%rbx !%rax ++
            pushq !%rax
  | Mul   -> 
            (* Print de debug *)
            Printf.printf "Mul  "; 
            Printf.printf "%s" (print_stack !stack_types);
            (* Atualizar stack de tipos *)
            stack_types := (type_program !stack_types (Ops Mul));
            (* Assembly*)
            popq rbx ++
            popq rax ++
            imulq !%rbx !%rax ++
            pushq !%rax 
  | Div   -> 
            (* Print de debug *)
            Printf.printf "Div  "; 
            Printf.printf "%s" (print_stack !stack_types);
            (* Atualizar stack de tipos *)
            stack_types := (type_program !stack_types (Ops Div));
            (* Assembly*)
            popq rdi ++ 
            popq rax ++ 
            movq (imm 0) !%rdx ++ 
            idivq !%rdi ++ 
            pushq !%rax
  | Neg   -> 
            (* Print de debug *)
            Printf.printf "Neg  ";
            Printf.printf "%s" (print_stack !stack_types);
            (* Atualizar stack de tipos *)
            stack_types := (type_program !stack_types (Ops Neg));
            (* Assembly*)
            popq rax ++
            movq (imm (-1)) !%rbx ++
            imulq !%rbx !%rax ++
            pushq !%rax 
  | Mod   -> 
            (* Print de debug *)
            Printf.printf "Mod  ";
            Printf.printf "%s" (print_stack !stack_types);
            (* Atualizar stack de tipos *)
            stack_types := (type_program !stack_types (Ops Mod));
            (* Assembly*)
            popq rdi ++ 
            popq rax ++ 
            movq (imm 0) !%rdx ++ 
            idivq !%rdi ++ 
            pushq !%rdx
  | Min   -> 
            (* Print de debug *)
            Printf.printf "Min  ";
            Printf.printf "%s" (print_stack !stack_types);
            (* Atualizar stack de tipos *)
            stack_types := (type_program !stack_types (Ops Min));
            label_count := !label_count + 2;
            (* Assembly*)
            popq rax ++
            popq rbx ++
            cmpq !%rax !%rbx ++
            jg (".L"^string_of_int (!label_count-1)) ++ (*caso o número no rax seja o menor*)
            pushq !%rbx ++
            jmp (".L"^string_of_int !label_count) ++ 
            label (".L"^string_of_int (!label_count-1)) ++ 
            pushq !%rax ++
            label (".L"^string_of_int !label_count)
  | Max   -> 
            (* Print de debug *)
            Printf.printf "Max  ";
            Printf.printf "%s" (print_stack !stack_types);
            (* Atualizar stack de tipos *)
            stack_types := (type_program !stack_types (Ops Max));
            label_count := !label_count + 2;
            (* Assembly*)
            popq rax ++
            popq rbx ++
            cmpq !%rax !%rbx ++
            jg (".L"^string_of_int (!label_count-1)) ++ (*caso o número no rax seja o maior*)
            pushq !%rax ++
            jmp (".L"^string_of_int !label_count) ++ 
            label (".L"^string_of_int (!label_count-1)) ++ 
            pushq !%rbx ++
            label (".L"^string_of_int !label_count)
  (* Comparacao *)
  | Equal -> 
            (* Print de debug *)
            Printf.printf "Equal  "; 
            Printf.printf "%s" (print_stack !stack_types);
            (* Atualizar stack de tipos *)
            stack_types := (type_program !stack_types (Ops Equal));
            label_count := !label_count + 2;
            (* Assembly *)
            popq rbx ++
            popq rax ++
            cmpq !%rbx !%rax ++
            je (".L"^string_of_int (!label_count-1)) ++ (*caso sejam iguais, saltar para L1*)
            movq (imm 0) !%rax ++ (*caso sejam diferentes colocar 0 no registo*)
            jmp (".L"^string_of_int !label_count) ++ (*saltar para a segunda label*)
            label (".L"^string_of_int (!label_count-1)) ++ (*L1*)
            movq (imm 1) !%rax ++
            label (".L"^string_of_int (!label_count)) ++ (*L2*)
            pushq !%rax
  | Diff   -> 
            (* Print de debug *)
            Printf.printf "Diff  ";
            Printf.printf "%s" (print_stack !stack_types);
            (* Atualizar stack de tipos *)
            stack_types := (type_program !stack_types (Ops Diff));
            label_count := !label_count + 2;
            (* Assembly *)
            popq rbx ++
            popq rax ++
            cmpq !%rbx !%rax ++
            je (".L"^string_of_int (!label_count-1)) ++ 
            movq (imm 1) !%rax ++ 
            jmp (".L"^string_of_int !label_count) ++ 
            label (".L"^string_of_int (!label_count-1)) ++ 
            movq (imm 0) !%rax ++
            label (".L"^string_of_int (!label_count)) ++ 
            pushq !%rax
  | Gt     -> 
            (* Print de debug *)
            Printf.printf "Gt  ";
            Printf.printf "%s" (print_stack !stack_types);
            (* Atualizar stack de tipos *)
            stack_types := (type_program !stack_types (Ops Gt));
            label_count := !label_count + 2;
            (* Assembly *)
            popq rax ++ 
            popq rbx ++ 
            cmpq !%rax !%rbx ++ 
            jg (".L"^string_of_int (!label_count-1)) ++ 
            movq (imm 0) !%rax ++
            jmp (".L"^string_of_int !label_count) ++ 
            label (".L"^string_of_int (!label_count-1)) ++ 
            movq (imm 1) !%rax ++
            label (".L"^string_of_int !label_count) ++
            pushq !%rax 
  | Lt     -> 
            (* Print de debug *)
            Printf.printf "Lt  ";
            Printf.printf "%s" (print_stack !stack_types);
            (* Atualizar stack de tipos *)
            stack_types := (type_program !stack_types (Ops Lt));
            label_count := !label_count + 2;
            (* Assembly *)
            popq rax ++
            popq rbx ++
            cmpq !%rax !%rbx ++
            jl (".L"^string_of_int (!label_count-1)) ++ 
            movq (imm 0) !%rax ++
            jmp (".L"^string_of_int !label_count) ++ 
            label (".L"^string_of_int (!label_count-1)) ++ 
            movq (imm 1) !%rax ++
            label (".L"^string_of_int !label_count) ++
            pushq !%rax
  | Ge     -> 
            (* Print de debug *)
            Printf.printf "Ge  ";
            Printf.printf "%s" (print_stack !stack_types);
            (* Atualizar stack de tipos *)
            stack_types := (type_program !stack_types (Ops Ge));
            label_count := !label_count + 2;
            (* Assembly *)
            popq rax ++
            popq rbx ++
            cmpq !%rax !%rbx ++
            jge (".L"^string_of_int (!label_count-1)) ++ 
            movq (imm 0) !%rax ++
            jmp (".L"^string_of_int !label_count) ++ 
            label (".L"^string_of_int (!label_count-1)) ++ 
            movq (imm 1) !%rax ++
            label (".L"^string_of_int !label_count) ++
            pushq !%rax
  | Le     -> 
            (* Print de debug *)
            Printf.printf "Le  ";
            Printf.printf "%s" (print_stack !stack_types);
            (* Atualizar stack de tipos *)
            stack_types := (type_program !stack_types (Ops Le));
            label_count := !label_count + 2;
            (* Assembly *)
            popq rax ++
            popq rbx ++
            cmpq !%rax !%rbx ++
            jle (".L"^string_of_int (!label_count-1)) ++ 
            movq (imm 0) !%rax ++
            jmp (".L"^string_of_int !label_count) ++ 
            label (".L"^string_of_int (!label_count-1)) ++ 
            movq (imm 1) !%rax ++
            label (".L"^string_of_int !label_count) ++
            pushq !%rax
  | And    -> 
            (* Print de debug *)
            Printf.printf "And  "; 
            Printf.printf "%s" (print_stack !stack_types);
            (* Atualizar stack de tipos *)
            stack_types := (type_program !stack_types (Ops And));
            (* Assembly *)
            popq rax ++
            popq rbx ++
            andq !%rbx !%rax ++
            pushq !%rax
  | Or     -> 
            (* Print de debug *)
            Printf.printf "Or  ";
            Printf.printf "%s" (print_stack !stack_types);
            (* Atualizar stack de tipos *)
            stack_types := (type_program !stack_types (Ops Or));
            (* Assembly *)
            popq rax ++
            popq rbx ++
            orq !%rbx !%rax ++
            pushq !%rax 

(* Compilação de uma expressão *)
let rec comprec = function
  | Int i ->
      (* Print de debug *)
      Printf.printf "INT: %d  " i;
      Printf.printf "%s" (print_stack !stack_types);
      (* Atualizar stack de tipos *)
      stack_types := Tint :: !stack_types;
      (* Assembly *)
      pushq (imm i)
  | Bool b ->
      (* Print de debug *)
      Printf.printf "BOOL: %b  " b;
      Printf.printf "%s" (print_stack !stack_types);
      (* Atualizar stack de tipos *)
      stack_types := Tbool :: !stack_types;
      (* Assembly *)
      if b then pushq (imm 1) else pushq (imm 0) 
  | Str s ->
      (* Print de debug *)
      Printf.printf "STR: %s  " s;
      Printf.printf "%s" (print_stack !stack_types);
      (* Atualizar stack de tipos *)
      stack_types := Tstr :: !stack_types;
      (* Atualizar tabela de hash *)
      str_index := !str_index + 1;
      Hashtbl.add str_tbl !str_index s;
      (* Assembly *)
      pushq (ilab ("str_" ^ (string_of_int !str_index)));
  | Cmd c ->
      Printf.printf "CMD: ";
      compile_cmds c;
  | Ops o ->
      Printf.printf "OPS: ";
      compile_ops o;
  | Print p ->
      Printf.printf "PRINT: ";
      compile_print p;
  | Ifelse (b1, b2) ->
      (* Print de debug *)
      Printf.printf "IF: %d  " !ifelse_index;
      Printf.printf "%s" (print_stack !stack_types);
      (* Verificar se o ultimo elemento da pilha é um bool *)
      stack_types := (check_if_cond !stack_types);
      (* Contador para a label do if else *)
      ifelse_index := !ifelse_index + 1;
      let cond_num = !ifelse_index in
      let stack_before_b1 = !stack_types in
      let body1 = 
        (* compila o corpo do if *)
        (List.fold_left (++) nop (List.map comprec (List.rev b1))) 
      in 
      if stack_before_b1 <> !stack_types 
      then raise (TypeError "A pilha deve ser a mesma, antes e depois do corpo do if")
      else (
        let stack_before_b2 = !stack_types in
        let body2 = 
          (* compila o corpo do else *)
          (List.fold_left (++) nop (List.map comprec (List.rev b2)))
        in 
        if stack_before_b2 <> !stack_types
        then raise (TypeError "A pilha deve ser a mesma, antes e depois do corpo do else")
        else (
          (comment ("If: " ^ (string_of_int cond_num))) ++
          (* Extrai o ultimo valor da pilha e compara-o com zero*)
          popq rbx ++
          cmpq (imm 0) !%rbx ++
          (* Se for zero salta para a label do else *)
          je ("else_"^(string_of_int cond_num)) ++
          (* Corpo do if *)
          body1 ++
          jmp ("ifelse_continua_"^(string_of_int cond_num)) ++
          (* Cria label do else *)
          label ("else_"^(string_of_int cond_num)) ++
          body2 ++
          jmp ("ifelse_continua_"^(string_of_int cond_num)) ++
          (* Cria label para o programa continuar*)
          label ("ifelse_continua_" ^ (string_of_int cond_num))
        )
      )
  | Ifthen b ->
    (* Print de debug *)
    Printf.printf "IF then: ";
    Printf.printf "%s" (print_stack !stack_types);
    (* Verificar se o ultimo elemento da pilha é um bool *)
    stack_types := (check_if_cond !stack_types);
    (* Contador para a label do if else *)
    ifthen_index := !ifthen_index + 1;
    let if_num = !ifthen_index in
    let stack_before_b1 = !stack_types in
    let body1 =
      (* Compilar o corpo do if *) 
      (List.fold_left (++) nop (List.map comprec (List.rev b)))
    in
    if stack_before_b1 <> !stack_types
    then raise (TypeError "A pilha deve ser a mesma, antes e depois do corpo do if")
    else (
      (comment ("If: " ^ (string_of_int if_num))) ++
      (* Extrai o valor da condicao *)
      popq rbx ++
      cmpq (imm 0) !%rbx ++
      (* Se for zero salta para a label do continua *)
      je ("if_continua_"^(string_of_int if_num)) ++
      body1 ++
      (* Criar label para o programa continuar *)
      label ("if_continua_" ^ (string_of_int if_num))
    )
  | While (c, b) ->
      (* Print de debug *)
      Printf.printf "WHILE: ";
      Printf.printf "%s" (print_stack !stack_types);
      (* Contador para a label do if else *)
      while_index := !while_index + 1;
      (* Verificar se a condicao é um bool *)
      let cond = 
        (* Compila a condicao *)
        (List.fold_left (++) nop (List.map comprec (List.rev c)))
      in
      (* Verificar se o ultimo elemento da pilha é um bool *)
      stack_types := (check_while_cond !stack_types);
      let w_num = !while_index in
      let stack_before_b1 = !stack_types in
      let body1 = 
        (* compila o corpo do while *)
        (List.fold_left (++) nop (List.map comprec (List.rev b)))
      in
      if stack_before_b1 <> !stack_types
      then raise (TypeError "A pilha deve ser a mesma, antes e depois do while")
      else (
        (comment ("While: " ^ (string_of_int w_num))) ++
        (* Extrai o valor da condicao *)
        cond ++
        popq rbx ++
        cmpq (imm 0) !%rbx ++
        (* Se for zero salta para a label continua *)
        je ("while_continua_"^(string_of_int w_num)) ++
        (* Cria a label do while *)
        label ("while_"^(string_of_int w_num)) ++
        body1 ++
        (* Compila a condicao novamente *)
        (List.fold_left (++) nop (List.map comprec (List.rev c))) ++
        popq rbx ++
        cmpq (imm 0) !%rbx ++
        (* Continua o loop *)
        jne ("while_"^(string_of_int w_num)) ++
        (* Cria label para o programa continuar *)
        label ("while_continua_"^(string_of_int w_num))
      )
  | Proc (s, b) ->
      Printf.printf "Proc: \n";
      (* Adicionar a proc a Hashtbl *)
      let proc_body = List.rev b in
      let proc_body = List.map comprec proc_body in
      let proc_body = List.fold_left (++) nop proc_body in
        Hashtbl.add procs_tbl s proc_body;
      nop
  | Ident s ->
      Printf.printf "Ident: %s\n" s;
      call s
  | Fetch id ->
      Printf.printf "Var: %s\n" id;
      (*começa por verificar que a variável foi definida*)
      begin
      try 
        let i = (Hashtbl.find var_tbl id) in 
        if i = (-1) then (*caso seja bool ou int*)
          movq (lab id) !%rax ++
          pushq !%rax
        else
          movq (ilab ("str_"^string_of_int i)) !%rax ++
          pushq !%rax
      with Not_found -> Printf.printf "A variável %s não existe." id;nop;
      end;
  | Let (id,v) -> 
      Printf.printf "Let: %s\n" id;
      comprec v ++
      begin
        match v with
        | Str v -> Hashtbl.replace var_tbl id (!str_index + 1); 
                   popq rax  (*o espaço da memória com a label já tem a string, por isso só é preciso tirá-la da pilha*)
        | Int v -> Hashtbl.replace var_tbl id (-1);
                   popq rax ++
                   movq !%rax (lab id)
        | Bool v -> Hashtbl.replace var_tbl id (-1); 
                   popq rax ++
                   movq !%rax (lab id)
        | Fetch v -> Hashtbl.replace var_tbl id (-1); 
                   popq rax ++
                   movq !%rax (lab id)
        | _ -> raise (TypeError (Printf.sprintf "A variável %s tem de ser do tipo Str, Int, Bool ou @Var.\n" id)); nop 
      end

(* Compila o programa p e grava o código no ficheiro ofile *)
let compile_program p ofile =
  let code = List.map comprec p in
  let code = List.fold_left (++) nop code in
  let p =
    { text =
        globl "main" ++ label "main" ++
        code ++
        movq (imm 0) !%rax ++ (* exit *)
        ret ++
        (* print_int *)
        label "print_int" ++
        movq !%rdi !%rsi ++
        leaq (lab ".Sprint_int") rdi ++
        movq (imm 0) !%rax ++
        call "printf" ++
        ret ++
        (* print_bool *)
        label  "print_bool"  ++
        cmpq (imm 0) !%rdi   ++
        je   ".Lfalse"       ++
        movq (ilab "true") !%rdi   ++
        jmp  ".Lprint"       ++
        label  ".Lfalse"     ++
        movq (ilab "false") !%rdi   ++
        label ".Lprint"     ++
        movq (imm 0) !%rax   ++
        call "printf"       ++
        ret ++
        (* print_str *)
        label "print_str" ++
        movq !%rdi !%rsi ++
        leaq (lab ".Sprint_str") rdi ++
        movq (imm 0) !%rax ++
        call "printf" ++
        ret ++
        (* procs *)
        (Hashtbl.fold (fun s b l -> label s ++ b ++ ret ++ l) procs_tbl) nop;
      data =
          Hashtbl.fold (fun x i l -> if i=(-1) then label x ++ dquad [1] ++ l else nop ++ l) var_tbl nop ++
          Hashtbl.fold (fun i s l -> label ("str_" ^ (string_of_int i)) ++ string s ++ l) str_tbl
          (*((Hashtbl.fold (fun i e l -> label ("else_" ^ (string_of_int i)) ++ comprec e ++ l) else_tbl)*)
          (label ".Sprint_int" ++ string "%d\n") ++
          (label ".Sprint_str" ++ string "%s") ++
          (label "true"  ++ string "true\n")  ++
          (label "false" ++ string "false\n")
    }
  in
  let f = open_out ofile in
  let fmt = formatter_of_out_channel f in
  X86_64.print_program fmt p;
  (*  "flush" do buffer para garantir que tudo fica escrito antes do fecho
       deste  *)
  fprintf fmt "@?";
  close_out f
