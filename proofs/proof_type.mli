(************************************************************************)
(*  v      *   The Coq Proof Assistant  /  The Coq Development Team     *)
(* <O___,, *   INRIA - CNRS - LIX - LRI - PPS - Copyright 1999-2012     *)
(*   \VV/  **************************************************************)
(*    //   *      This file is distributed under the terms of the       *)
(*         *       GNU Lesser General Public License Version 2.1        *)
(************************************************************************)

open Environ
open Evd
open Names
open Libnames
open Term
open Context
open Pp
open Tacexpr
open Glob_term
open Genarg
open Nametab
open Pattern
open Misctypes

(** This module defines the structure of proof tree and the tactic type. So, it
   is used by [Proof_tree] and [Refiner] *)

type prim_rule =
  | Intro of Id.t
  | Cut of bool * bool * Id.t * types
  | FixRule of Id.t * int * (Id.t * int * constr) list * int
  | Cofix of Id.t * (Id.t * constr) list * int
  | Refine of constr
  | Convert_concl of types * cast_kind
  | Convert_hyp of named_declaration
  | Thin of Id.t list
  | ThinBody of Id.t list
  | Move of bool * Id.t * Id.t move_location
  | Order of Id.t list
  | Rename of Id.t * Id.t
  | Change_evars

(** Nowadays, the only rules we'll consider are the primitive rules *)

type rule = prim_rule

(** The type [goal sigma] is the type of subgoal. It has the following form
{v   it    = \{ evar_concl = [the conclusion of the subgoal]
             evar_hyps = [the hypotheses of the subgoal]
             evar_body = Evar_Empty;
             evar_info = \{ pgm    : [The Realizer pgm if any]
                           lc     : [Set of evar num occurring in subgoal] \}\}
   sigma = \{ stamp = [an int chardacterizing the ed field, for quick compare]
             ed : [A set of existential variables depending in the subgoal]
               number of first evar,
               it = \{ evar_concl = [the type of first evar]
                      evar_hyps = [the context of the evar]
                      evar_body = [the body of the Evar if any]
                      evar_info = \{ pgm    : [Useless ??]
                                    lc     : [Set of evars occurring
                                              in the type of evar] \} \};
               ...
               number of last evar,
               it = \{ evar_concl = [the type of evar]
                      evar_hyps = [the context of the evar]
                      evar_body = [the body of the Evar if any]
                      evar_info = \{ pgm    : [Useless ??]
                                    lc     : [Set of evars occurring
                                              in the type of evar] \} \} \} v}
*)

type goal = Goal.goal

type tactic = goal sigma -> goal list sigma

(** Ltac traces *)

type ltac_call_kind =
  | LtacNotationCall of string
  | LtacNameCall of ltac_constant
  | LtacAtomCall of glob_atomic_tactic_expr
  | LtacVarCall of Id.t * glob_tactic_expr
  | LtacConstrInterp of glob_constr *
      (extended_patvar_map * (Id.t * Id.t option) list)

type ltac_trace = (int * Loc.t * ltac_call_kind) list

(** Invariant: the exceptions embedded in LtacLocated satisfy
    Errors.noncritical *)

exception LtacLocated of ltac_trace * Loc.t * exn
