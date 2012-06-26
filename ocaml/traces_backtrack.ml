(* Backwards taint analysis on traces *)

open Ast
open Big_int_convenience
open Type

module D = Debug.Make(struct let name = "Exploitable" and default=`Debug end)
open D

(* Represent a location, which is either a variable (register) or a
   memory address. *)
module Loc = struct
  type t = V of Var.t | M of Big_int_Z.big_int
  let compare mv1 mv2 =
    match (mv1,mv2) with
    | ((V x),(V y)) -> compare x y
    | ((M x),(M y)) -> Big_int_Z.compare_big_int x y
    | ((V _),(M _)) -> -1
    | ((M _),(V _)) -> 1
end

module LocSet = Set.Make(Loc)
module VH = Var.VarHash

let print_locset vars =
  dprintf "  [+] Cardinality of Set: %d" (LocSet.cardinal vars);
  LocSet.iter (fun k -> match k with
  | Loc.V(x) -> dprintf "   [-] Var name: %s" (Pp.var_to_string x)
  | Loc.M(x) -> dprintf "   [-] Addr: %s" (Util.hex_of_big_int x)) vars

(* Given an expression e, recursively adds referenced locations to the
 * given set.
 *)
let add_referenced vars e =
  let varvis = object(self)
    inherit Ast_visitor.nop

    method visit_exp e =
      match e with
      | Let (v, e1, e2) ->
        (* Let requires a little special handling *)
        ignore(Ast_visitor.exp_accept self e1);
        vars := LocSet.add (Loc.V v) !vars;
        ignore(Ast_visitor.exp_accept self e2);
        (* XXX: This doesn't handle shadowing Lets properly, e.g., let v
	   = 5 in let v = 4 in v *)
        vars := LocSet.remove (Loc.V v) !vars;
        `SkipChildren
      | Load (_,Int(addr,_),_,_) ->
        vars := LocSet.add (Loc.M addr) !vars;
        `DoChildren
      | Load _ as e ->
        failwith (Printf.sprintf "Found a non-concretized memory read %s, but expected all memory addresses to be concretized" (Pp.ast_exp_to_string e))
      | _ -> `DoChildren
    method visit_rvar r =
      if not (LocSet.mem (Loc.V r) !vars) then
	if Typecheck.is_integer_type (Var.typ r) then
	  vars := LocSet.add (Loc.V r) !vars;
      `DoChildren
  end
  in
  ignore(Ast_visitor.exp_accept varvis e);
  !vars

(* Given an expression e, returns true if the expression is a memory
   write to a location in the interesting set.  *)
let interesting_mem_write vars e =
  let interesting_flag = ref false in
  let mems = ref LocSet.empty in
  let memvis_one = object(self)
  inherit Ast_visitor.nop

  method visit_exp e =
    match e with
    | Store(_,Int(addr,_),value,_,_) ->
      if (LocSet.mem (Loc.M addr) !vars) then (
        mems := LocSet.add (Loc.M addr) !mems;
        interesting_flag := true;
        `SkipChildren)
      else
        `DoChildren
    | _ -> `DoChildren
  end
  in
  ignore(Ast_visitor.exp_accept memvis_one e);
  (!interesting_flag, !mems)

(* Given a trace and an initial location set, finds the starting
   locations that influenced that operand. *)
let backwards_taint stmts locset =
  let rev_stmts = List.rev stmts in
  let vars = ref locset in
  List.iter (fun stmt ->
    (match stmt with
    | Move(l, e, _) ->
      (* If l is interesting, then any location referenced in e is
	 interesting too. *)
      if (LocSet.mem (Loc.V l) !vars &&
	    Typecheck.is_integer_type (Var.typ l)) then (
        vars := (LocSet.remove (Loc.V l) !vars);
        vars := add_referenced vars e
      ) else (
	(* Alternatively, if there is a write to an interesting memory
	   location, then we should also add any referenced
	   locations. *)
        let flag,mems = interesting_mem_write vars e in
        if flag then (
          vars := LocSet.diff !vars mems;
          vars := add_referenced vars e)
      )
    | _ -> ();
    );
  ) rev_stmts;
  !vars
