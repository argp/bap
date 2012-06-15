(*pp camlp4o pa_macro.cmo *)

let usage = "Usage: "^Sys.argv.(0)^" <input options> [transformations and outputs]\n\
             Transform BAP IL programs. "

open Ast

type ast = Ast.program
type astcfg = Cfg.AST.G.t
type ssa = Cfg.SSA.G.t

type prog =
  | Ast of ast
  | AstCfg of astcfg
  | Ssa of ssa

type cmd = 
  | TransformAst of (ast -> ast)
  | TransformAstCfg of (astcfg -> astcfg)
  | TransformSsa of (ssa -> ssa)
  | ToCfg
  | ToAst
  | ToSsa
 (* add more *)

let pipeline = ref []

(* Initialization statements *)
let inits = ref []

let scope = ref (Grammar_private_scope.default_scope ())

let init_stmts () =
  List.fold_left (fun l (v,e) -> Move(v,e,[])::l) [] !inits

let cexecute_at s p =
  let () = ignore(Symbeval.concretely_execute p ~i:(init_stmts ()) ~s) in
  p

let cexecute p =
  let () = ignore(Symbeval.concretely_execute p ~i:(init_stmts ())) in
  p

let jitexecute p =
IFDEF WITH_LLVM THEN
  let cfg = Cfg_ast.of_prog p in
  let cfg = Prune_unreachable.prune_unreachable_ast cfg in
  let codegen = new Llvm_codegen.codegen Llvm_codegen.FuncMulti in
  let jit = codegen#convert_cfg cfg in
  let r = codegen#eval_fun ~ctx:(List.rev !inits) jit in
  Printf.printf "Result: %s\n" (Pp.ast_exp_to_string r);
  p
ELSE
  failwith "LLVM not enabled"
END;;

let add c =
  pipeline := c :: !pipeline

let uadd c =
  Arg.Unit(fun()-> add c)

let mapv v e =
  let e,ns = Parser.exp_from_string ~scope:!scope e in
  let t = Typecheck.infer_ast e in
  let ts = Pp.typ_to_string t in
  let v,ns = match Parser.exp_from_string ~scope:ns (v ^ ":" ^ ts) with
    | Var(v), ns -> v, ns
    | _ -> assert false
  in
  scope := ns;
  inits := (v, e) :: !inits
  (* let s = Move(v, e, []) in *)
  (* inits := s :: !inits *)

let mapmem a e =
  let a,ns = Parser.exp_from_string ~scope:!scope a in
  let e,ns = Parser.exp_from_string ~scope:ns e in
  let t = Typecheck.infer_ast e in
  (* XXX: Fix parser/asmir so that we don't have to do this! *)
  let m,ns = match Parser.exp_from_string ~scope:ns "mem_45:?u32" with
    | Var(v), ns -> v, ns
    | _ -> assert false
  in
  scope := ns;
  (* let s = Move(m, Store(Var(m), a, e, exp_false, t), []) in *)
  inits := (m, Store(Var(m), a, e, exp_false, t)) :: !inits
  (* inits := s :: !inits *)

let speclist =
  ("-eval", 
     Arg.Unit (fun () -> add(TransformAst cexecute)),
     "Concretely execute the IL from the beginning of the program")
  ::("-eval-at", 
     Arg.String (fun s -> add(TransformAst (cexecute_at (Int64.of_string s)))),
     "<pc> Concretely execute the IL from pc")
  ::("-jiteval",
     Arg.Unit (fun () -> add(TransformAst jitexecute)),
     "Concretely execute the IL using the LLVM JIT compiler")
  ::("-init-var",
     Arg.Tuple 
       (let vname = ref "" and vval = ref "" in
	[
	  Arg.Set_string vname; Arg.Set_string vval;
	  Arg.Unit (fun () -> mapv !vname !vval)
	]),
     "<var> <expression> Set variable to expression before evaluation.")
  ::("-init-mem",
     Arg.Tuple 
       (let maddr = ref "" and mval = ref "" in
	[
	  Arg.Set_string maddr; Arg.Set_string mval;
	  Arg.Unit (fun () -> mapmem !maddr !mval)
	]),
     "<var> <expression> Set variable to expression before evaluation.")
  :: Input.speclist

let anon x = raise(Arg.Bad("Unexpected argument: '"^x^"'"))
let () = Arg.parse speclist anon usage

let pipeline = List.rev !pipeline

let prog =
  try let p,s = Input.get_program() in
      (* Save scope for expression parsing *)
      scope := s;
      p
  with Arg.Bad s ->
    Arg.usage speclist (s^"\n"^usage);
    exit 1

let rec apply_cmd prog = function
  | TransformAst f -> (
      match prog with
      | Ast p -> Ast(f p)
      | _ -> failwith "need explicit translation to AST"
    )
  | TransformAstCfg f -> (
      match prog with
      | AstCfg p -> AstCfg(f p)
      | _ -> failwith "need explicit translation to AST CFG"
    )
  | TransformSsa f -> (
      match prog with
      | Ssa p -> Ssa(f p)
      | _ -> failwith "need explicit translation to SSA"
    )
  | ToCfg -> (
      match prog with
      | Ast p -> AstCfg(Cfg_ast.of_prog p)
      | Ssa p -> AstCfg(Cfg_ssa.to_astcfg p)
      | AstCfg _ as p -> prerr_endline "Warning: null transformation"; p
    )
  | ToAst -> (
      match prog with
      | AstCfg p -> Ast(Cfg_ast.to_prog p)
      | p -> apply_cmd (apply_cmd p ToCfg) ToAst
    )
  | ToSsa -> (
      match prog with
      | AstCfg p -> Ssa(Cfg_ssa.of_astcfg p)
      | p -> apply_cmd (apply_cmd p ToCfg) ToSsa
    )
;;

List.fold_left apply_cmd (Ast prog) pipeline


