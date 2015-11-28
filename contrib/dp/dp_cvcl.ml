
open Format
open Fol

let rec print_list sep print fmt = function
  | [] -> ()
  | [x] -> print fmt x
  | x :: r -> print fmt x; sep fmt (); print_list sep print fmt r

let space fmt () = fprintf fmt "@ "
let comma fmt () = fprintf fmt ",@ "

let rec print_term fmt = function
  | Cst n -> 
      fprintf fmt "%d" n
  | Plus (a, b) ->
      fprintf fmt "@[(%a@ +@ %a)@]" print_term a print_term b
  | Moins (a, b) ->
      fprintf fmt "@[(%a@ -@ %a)@]" print_term a print_term b
  | Mult (a, b) ->
      fprintf fmt "@[(%a@ *@ %a)@]" print_term a print_term b
  | Div (a, b) ->
      fprintf fmt "@[(%a@ /@ %a)@]" print_term a print_term b
  | App (id, []) ->
      fprintf fmt "@[%s@]" id
  | App (id, tl) ->
      fprintf fmt "@[%s(%a)@]" id print_terms tl

and print_terms fmt tl = 
  print_list comma print_term fmt tl

let rec print_predicate fmt p = 
  let pp = print_predicate in 
  match p with
  | True ->
      fprintf fmt "TRUE"
  | False ->
      fprintf fmt "FALSE"
  | Fatom (Eq (a, b)) ->
      fprintf fmt "@[(%a = %a)@]" print_term a print_term b
  | Fatom (Le (a, b)) ->
      fprintf fmt "@[(%a@ <= %a)@]" print_term a print_term b
  | Fatom (Lt (a, b))->
      fprintf fmt "@[(%a@ < %a)@]" print_term a print_term b
  | Fatom (Ge (a, b)) ->
      fprintf fmt "@[(%a@ >= %a)@]" print_term a print_term b
  | Fatom (Gt (a, b)) ->
      fprintf fmt "@[(%a@ > %a)@]" print_term a print_term b
  | Fatom (Pred (id, [])) ->
      fprintf fmt "@[%s@]" id
  | Fatom (Pred (id, tl)) ->
      fprintf fmt "@[%s(%a)@]" id print_terms tl
  | Imp (a, b) ->
      fprintf fmt "@[(%a@ => %a)@]" pp a pp b
  | And (a, b) ->
      fprintf fmt "@[(%a@ AND@ %a)@]" pp a pp b
  | Or (a, b) ->
      fprintf fmt "@[(%a@ OR@ %a)@]" pp a pp b
  | Not a ->
      fprintf fmt "@[(NOT@ %a)@]" pp a
  | Forall (id, t, p) -> 
      fprintf fmt "@[(FORALL (%s:%s): %a)@]" id t pp p
  | Exists (id, t, p) -> 
      fprintf fmt "@[(EXISTS (%s:%s): %a)@]" id t pp p

let rec string_of_type_list  = function
  | [] -> assert false
  | [e] -> e
  | e :: l' -> e ^ ", " ^ (string_of_type_list l')

let print_query fmt (decls,concl) =
  let print_decl = function
    | DeclVar (id, [], t) ->
	fprintf fmt "@[%s: %s;@]@\n" id t
    | DeclVar (id, [e], t) ->
	fprintf fmt "@[%s: [%s -> %s];@]@\n"
	  id e t
    | DeclVar (id, l, t) ->
	fprintf fmt "@[%s: [[%s] -> %s];@]@\n"
	  id (string_of_type_list l) t
    | DeclPred (id, []) ->
	fprintf fmt "@[%s: BOOLEAN;@]@\n" id
     | DeclPred (id, [e]) ->
	fprintf fmt "@[%s: [%s -> BOOLEAN];@]@\n"
	  id e
   | DeclPred (id, l) ->
	fprintf fmt "@[%s: [[%s] -> BOOLEAN];@]@\n"
	  id (string_of_type_list l)
    | DeclType id ->
	fprintf fmt "@[%s: TYPE;@]@\n" id
    | Assert (id, f)  -> 
	fprintf fmt "@[ASSERT %% %s@\n %a;@]@\n" id print_predicate f
  in
  List.iter print_decl decls;
  fprintf fmt "QUERY %a;" print_predicate concl

let call q = 
  let f = Filename.temp_file "coq_dp" ".cvc" in
  let c = open_out f in
  let fmt = formatter_of_out_channel c in
  fprintf fmt "@[%a@]@." print_query q;
  close_out c;
  ignore (Sys.command (sprintf "cat %s" f));
  let cmd = 
    sprintf "timeout 10 cvcl < %s > out 2>&1 && grep -q -w Valid out" f
  in
  prerr_endline cmd; flush stderr;
  let out = Sys.command cmd in
  if out = 0 then Valid else if out = 1 then Invalid else Timeout
  (* TODO: effacer le fichier f et le fichier out *)

