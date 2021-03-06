(*
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 * http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 *)

(** Ergo is a language for expressing contract logic. *)

(** * Abstract Syntax *)

Require Import String.
Require Import List.
Require Import EquivDec.

Require Import ErgoSpec.Common.Utils.EResult.
Require Import ErgoSpec.Common.Utils.EError.
Require Import ErgoSpec.Common.Utils.ENames.
Require Import ErgoSpec.Common.CTO.CTO.
Require Import ErgoSpec.Backend.ErgoBackend.
Require Import ErgoSpec.Ergo.Lang.ErgoBase.

Section Ergo.

  Inductive match_case_kind :=
  | CaseValue : ErgoData.data -> match_case_kind    (**r match against value *)
  | CaseType : string -> match_case_kind   (**r match against type *)
  .

  Definition match_case :=
    (option string * match_case_kind)%type. (**r optional variable and case kind *)

  (** Expression *)
  Inductive ergo_expr :=
  | EThisContract : ergo_expr (**r this contract *)
  | EThisClause : ergo_expr (**r this clause *)
  | EThisState : ergo_expr (**r this state *)
  | EVar : string -> ergo_expr (**r variable *)
  | EConst : ErgoData.data -> ergo_expr (**r constant *)
  | EArray : list ergo_expr -> ergo_expr (**r array constructor *) 
  | EUnaryOp : ErgoOps.Unary.op -> ergo_expr -> ergo_expr (**r unary operator *)
  | EBinaryOp : ErgoOps.Binary.op -> ergo_expr -> ergo_expr -> ergo_expr (**r binary operator *)
  | EIf : ergo_expr -> ergo_expr -> ergo_expr -> ergo_expr (**r conditional *)
  | EEnforce : ergo_expr -> option ergo_expr -> ergo_expr -> ergo_expr (**r enforce *)
  | ELet : string -> option cto_type -> ergo_expr -> ergo_expr -> ergo_expr (**r local variable binding *)
  | ERecord : list (string * ergo_expr) -> ergo_expr (**r create a new record *)
  | ENew : class_ref -> list (string * ergo_expr) -> ergo_expr (**r create a new concept/object *)
  | EThrow : class_ref -> list (string * ergo_expr) -> ergo_expr (**r create a new concept/object *)
  | ECall : string -> list ergo_expr -> ergo_expr (**r function call *)
  | EMatch : ergo_expr -> list (match_case * ergo_expr) -> ergo_expr -> ergo_expr (**r match-case *)
  | EFor : string -> ergo_expr -> option ergo_expr -> ergo_expr -> ergo_expr (**r for loop with optional where *)
  .

  (** Clause *)
  Definition ergo_clause := @clause ergo_expr.

  (** Function *)
  Definition ergo_function := @function ergo_expr.

  (** Declaration *)
  Definition ergo_declaration := @declaration ergo_expr.

  (** Contract *)
  Definition ergo_contract := @contract ergo_expr.

  (** Statement *)
  Definition ergo_stmt := @stmt ergo_expr.

  (** Package. *)
  Definition ergo_package := @package ergo_expr.

End Ergo.

