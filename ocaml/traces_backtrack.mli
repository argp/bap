(** Backwards taint analysis on traces.

    Given a list of data sink locations, computes the set of data source
    locations whose data flowed to user specific sinks.

    @author Brian Pak
*)

(** A location is a register (BAP variable) or a memory location
    (address) *)
module Loc :
sig
  type t = V of Var.t | M of Big_int_Z.big_int
  val compare : t -> t -> int
end
module LocSet : Set.S with type elt = Loc.t

(** [backwards_taint t sinkset] returns the set of all source
    locations (input bytes) from which data flowed to at least one
    location in [sinkset] in the trace [t].

    For example, if [sinkset] is a faulting operand, the function will
    return the list of input bytes whose data contributed to that
    operand.

    Note: This function performs taint analysis, which is a data analysis,
    and does not capture control dependencies, which can also be used
    to affect program values.
*)
val backwards_taint : Ast.stmt list -> LocSet.t -> LocSet.t

(** Prints the contents of a location set to [stdout]. *)
val print_locset : LocSet.t -> unit
