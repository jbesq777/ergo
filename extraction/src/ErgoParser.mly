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

%{
  open Util
  open ErgoComp
%}

%token <int> INT
%token <float> FLOAT
%token <string> STRING
%token <string> IDENT

%token NAMESPACE IMPORT DEFINE FUNCTION
%token CONCEPT TRANSACTION ENUM EXTENDS
%token CONTRACT OVER CLAUSE THROWS

%token ENFORCE IF THEN ELSE
%token LET FOR IN WHERE
%token RETURN THROW STATE
%token VARIABLE AS
%token NEW
%token MATCH TYPEMATCH WITH

%token OR AND NOT

%token NIL
%token TRUE FALSE

%token EQUAL NEQUAL
%token LT GT LTEQ GTEQ
%token PLUS MINUS STAR SLASH
%token PLUSPLUS
%token DOT COMMA COLON SEMI QUESTION
%token LPAREN RPAREN
%token LBRACKET RBRACKET
%token LCURLY RCURLY
%token EOF

%left SEMI
%left ELSE
%left RETURN
%left STATE
%left OR
%left AND
%left EQUAL NEQUAL
%left LT GT LTEQ GTEQ
%left PLUS MINUS
%left STAR SLASH
%left PLUSPLUS
%right NOT
%left DOT

%start <ErgoComp.ErgoCompiler.ergo_package> main

%%

main:
| p = package EOF
    { p }


package:
| NAMESPACE qn = qname_prefix ss = stmts
    { { package_namespace = Util.char_list_of_string qn;
	package_statements = ss; } }

stmts:
|
    { [] }
| s = stmt ss = stmts
    { s :: ss }

stmt:
| DEFINE CONCEPT cn = ident dt = cto_class_decl
    { let (oe,ctype) = dt in EType (ErgoCompiler.mk_cto_declaration cn (CTOConcept (oe,ctype))) }
| DEFINE TRANSACTION cn = ident dt = cto_class_decl
    { let (oe,ctype) = dt in EType (ErgoCompiler.mk_cto_declaration cn (CTOTransaction (oe,ctype))) }
| DEFINE ENUM cn = ident et = cto_enum_decl
    { EType (ErgoCompiler.mk_cto_declaration cn (CTOEnum et)) }
| DEFINE VARIABLE v = ident EQUAL e = expr
    { EGlobal (v, e) }
| DEFINE FUNCTION cn = ident LPAREN RPAREN COLON out = paramtype mt = maythrow LCURLY e = expr RCURLY
    { EFunc
	{ function_name = cn;
	  function_lambda =
	  { lambda_params = [];
            lambda_output = Some out;
	    lambda_throw = mt;
	    lambda_body = e; } } }
| DEFINE FUNCTION cn = ident LPAREN ps = params RPAREN COLON out = paramtype mt = maythrow LCURLY e = expr RCURLY
    { EFunc
	{ function_name = cn;
	  function_lambda =
	  { lambda_params = ps;
            lambda_output = Some out;
	    lambda_throw = mt;
	    lambda_body = e; } } }
| IMPORT qn = qname_prefix
    { EImport (ErgoUtil.cto_import_decl_of_import_namespace qn) }
| c = contract
    { EContract c }

cto_class_decl:
| LCURLY rt = rectype RCURLY
    { (None, rt) }
| EXTENDS en = ident LCURLY rt = rectype RCURLY
    { (Some en, rt) }

cto_enum_decl:
| LCURLY il = identlist RCURLY
    { il }

contract:
| CONTRACT cn = ident OVER tn = ident LCURLY ds = declarations RCURLY
    { { contract_name = cn;
        contract_template = tn;
        contract_declarations = ds; } }

declarations:
| 
    { [] }
| f = func ds = declarations
    { (Function f) :: ds }
| cl = clause ds = declarations
    { (Clause cl) :: ds }

func:
| DEFINE FUNCTION cn = ident LPAREN RPAREN COLON out = paramtype mt = maythrow LCURLY e = expr RCURLY
    { { function_name = cn;
	function_lambda =
	{ lambda_params = [];
          lambda_output = Some out;
	  lambda_throw = mt;
	  lambda_body = e; } } }
| DEFINE FUNCTION cn = ident LPAREN ps = params RPAREN COLON out = paramtype mt = maythrow LCURLY e = expr RCURLY
    { { function_name = cn;
	function_lambda =
	{ lambda_params = ps;
          lambda_output = Some out;
	  lambda_throw = mt;
	  lambda_body = e; } } }

clause:
| CLAUSE cn = ident LPAREN RPAREN COLON out = paramtype mt = maythrow LCURLY e = expr RCURLY
    { { clause_name = cn;
	clause_lambda =
	  { lambda_params = [];
            lambda_output = Some out;
	    lambda_throw = mt;
	    lambda_body = e; } } }
| CLAUSE cn = ident LPAREN ps = params RPAREN COLON out = paramtype mt = maythrow LCURLY e = expr RCURLY
    { { clause_name = cn;
	clause_lambda =
	  { lambda_params = ps;
            lambda_output = Some out;
	    lambda_throw = mt;
	    lambda_body = e; } } }

maythrow:
|
  { None }
| THROWS en = ident
  { Some en }
    
params:
| p = param
    { p :: [] }
| p = param COMMA ps = params
    { p :: ps }

param:
| pn = IDENT
    { (Util.char_list_of_string pn, None) }
| pn = IDENT pt = paramtype
    { (Util.char_list_of_string pn, Some pt) }

paramtype:
| pt = IDENT
    { begin match pt with
      | "Boolean" -> ErgoCompiler.cto_boolean
      | "String" -> ErgoCompiler.cto_string
      | "Double" -> ErgoCompiler.cto_double
      | "Long" -> ErgoCompiler.cto_long
      | "Integer" -> ErgoCompiler.cto_integer
      | "DateTime" -> ErgoCompiler.cto_dateTime
      | _ -> ErgoCompiler.cto_class_ref (Util.char_list_of_string pt)
      end }
| LCURLY rt = rectype RCURLY
    { ErgoCompiler.cto_record rt }
| pt = paramtype LBRACKET RBRACKET
    { ErgoCompiler.cto_array pt }
| pt = paramtype QUESTION
    { ErgoCompiler.cto_option pt }

rectype:
| 
    { [] }
| at = atttype
    { [at] }
| at = atttype COMMA rt = rectype
    { at :: rt }

atttype:
| an = IDENT COLON pt = paramtype
    { (Util.char_list_of_string an, pt) }

expr:
(* Parenthesized expression *)
| LPAREN e = expr RPAREN
    { e }
(* Call *)
| fn = IDENT LPAREN el = exprlist RPAREN
    { ErgoCompiler.ecall (Util.char_list_of_string fn) el }
(* Constants *)
| NIL
    { ErgoCompiler.econst ErgoCompiler.Data.dunit }
| TRUE
    { ErgoCompiler.econst (ErgoCompiler.Data.dbool true) }
| FALSE
    { ErgoCompiler.econst (ErgoCompiler.Data.dbool false) }
| i = INT
    { ErgoCompiler.econst (ErgoCompiler.Data.dnat (Util.coq_Z_of_int i)) }
| f = FLOAT
    { ErgoCompiler.econst (ErgoCompiler.Data.dfloat f) }
| s = STRING
    { ErgoCompiler.econst (ErgoCompiler.Data.dstring (Util.char_list_of_string s)) }
| LBRACKET el = exprlist RBRACKET
    { ErgoCompiler.earray el }
(* Expressions *)
| v = IDENT
    { ErgoCompiler.evar (Util.char_list_of_string v) }
| e = expr DOT a = safeident
    { ErgoCompiler.edot a e }
| IF e1 = expr THEN e2 = expr ELSE e3 = expr
    { ErgoCompiler.eif e1 e2 e3 }
| ENFORCE e1 = expr ELSE e3 = expr SEMI e2 = expr
    { ErgoCompiler.eenforce e1 e2 e3 }
| ENFORCE e1 = expr SEMI e3 = expr
    { ErgoCompiler.eenforce_default_fail e1 e3 }
| RETURN e1 = expr
    { ErgoCompiler.ereturn e1 }
| RETURN e1 = expr STATE e2 = expr
    { ErgoCompiler.ereturnsetstate e1 e2 }
| THROW qn = qname LCURLY r = reclist RCURLY
    { ErgoCompiler.ethrow (fst qn) (snd qn) r }
| NEW qn = qname LCURLY r = reclist RCURLY
    { ErgoCompiler.enew (fst qn) (snd qn) r }
| LCURLY r = reclist RCURLY
    { ErgoCompiler.erecord r }
| CONTRACT
    { ErgoCompiler.ethis_contract }
| CLAUSE
    { ErgoCompiler.ethis_clause }
| STATE
    { ErgoCompiler.ethis_state }
| DEFINE VARIABLE v = ident EQUAL e1 = expr SEMI e2 = expr
    { ErgoCompiler.elet v e1 e2 }
| LET v = ident EQUAL e1 = expr SEMI e2 = expr
    { ErgoCompiler.elet v e1 e2 }
| DEFINE VARIABLE v = ident COLON t = paramtype EQUAL e1 = expr SEMI e2 = expr
    { ErgoCompiler.elet_typed v t e1 e2 }
| LET v = ident COLON t = paramtype EQUAL e1 = expr SEMI e2 = expr
    { ErgoCompiler.elet_typed v t e1 e2 }
| MATCH e0 = expr csd = cases
    { ErgoCompiler.ematch e0 (fst csd) (snd csd) }
| FOR v = ident IN e1 = expr LCURLY e2 = expr RCURLY
    { ErgoCompiler.efor v e1 None e2 }
| FOR v = ident IN e1 = expr WHERE econd = expr LCURLY e2 = expr RCURLY
    { ErgoCompiler.efor v e1 (Some econd) e2 }
(* Unary operators *)
| NOT e = expr
    { ErgoCompiler.eunaryop ErgoCompiler.Ops.Unary.opneg e }
(* Binary operators *)
| e1 = expr EQUAL e2 = expr
    { ErgoCompiler.ebinaryop ErgoCompiler.Ops.Binary.opequal e1 e2 }
| e1 = expr NEQUAL e2 = expr
    { ErgoCompiler.eunaryop ErgoCompiler.Ops.Unary.opneg (ErgoCompiler.ebinaryop ErgoCompiler.Ops.Binary.opequal e1 e2) }
| e1 = expr LT e2 = expr
    { ErgoCompiler.ebinaryop ErgoCompiler.Ops.Binary.oplt e1 e2 }
| e1 = expr LTEQ e2 = expr
    { ErgoCompiler.ebinaryop ErgoCompiler.Ops.Binary.ople e1 e2 }
| e1 = expr GT e2 = expr
    { ErgoCompiler.eunaryop ErgoCompiler.Ops.Unary.opneg (ErgoCompiler.ebinaryop ErgoCompiler.Ops.Binary.ople e1 e2) }
| e1 = expr GTEQ e2 = expr
    { ErgoCompiler.eunaryop ErgoCompiler.Ops.Unary.opneg (ErgoCompiler.ebinaryop ErgoCompiler.Ops.Binary.oplt e1 e2) }
| e1 = expr MINUS e2 = expr
    { ErgoCompiler.ebinaryop ErgoCompiler.Ops.Binary.Float.opminus e1 e2 }
| e1 = expr PLUS e2 = expr
    { ErgoCompiler.ebinaryop ErgoCompiler.Ops.Binary.Float.opplus e1 e2 }
| e1 = expr STAR e2 = expr
    { ErgoCompiler.ebinaryop ErgoCompiler.Ops.Binary.Float.opmult e1 e2 }
| e1 = expr SLASH e2 = expr
    { ErgoCompiler.ebinaryop ErgoCompiler.Ops.Binary.Float.opdiv e1 e2 }
| e1 = expr AND e2 = expr
    { ErgoCompiler.ebinaryop ErgoCompiler.Ops.Binary.opand e1 e2 }
| e1 = expr OR e2 = expr
    { ErgoCompiler.ebinaryop ErgoCompiler.Ops.Binary.opor e1 e2 }
| e1 = expr PLUSPLUS e2 = expr
    { ErgoCompiler.ebinaryop ErgoCompiler.Ops.Binary.opstringconcat e1 e2 }

(* expression list *)
exprlist:
| 
    { [] }
| e = expr
    { [e] }
| e = expr COMMA el = exprlist
    { e :: el }

(* cases *)
cases:
| ELSE e = expr
    { ([],e) }
| WITH d = data THEN e = expr cs = cases
    { (((None,ErgoCompiler.ecasevalue d),e)::(fst cs), snd cs) }
| WITH LET v = ident EQUAL d = data THEN e = expr cs = cases
    { (((Some v,ErgoCompiler.ecasevalue d),e)::(fst cs), snd cs) }
| WITH AS brand = STRING THEN e = expr tcs = cases
    { (((None,ErgoCompiler.ecasetype (Util.char_list_of_string brand)),e)::(fst tcs), snd tcs) }
| WITH LET v = ident AS brand = STRING THEN e = expr tcs = cases
    { (((Some v,ErgoCompiler.ecasetype (Util.char_list_of_string brand)),e)::(fst tcs), snd tcs) }

(* New struct *)
reclist:
| 
    { [] }
| a = att
    { [a] }
| a = att COMMA rl = reclist
    { a :: rl }

att:
| an = IDENT COLON e = expr
    { (Util.char_list_of_string an, e) }

(* Qualified name *)
qname_base:
| STAR
    { (None,"*") }
| i = safeident_base
    { (None,i) }
| i = safeident_base DOT q = qname_base
    { if i = "*"
      then raise (Ergo_Error "'*' can only be last in a qualified name")
      else
        begin match q with
	| (None, last) -> (Some i, last)
	| (Some prefix, last) -> (Some (i ^ "." ^ prefix), last)
	end }

qname:
| qn = qname_base
    { begin match qn with
      | (None,last) -> (None,Util.char_list_of_string last)
      | (Some prefix, last) ->
	  (Some (Util.char_list_of_string prefix), Util.char_list_of_string last)
      end }

qname_prefix:
| qn = qname_base
    { begin match qn with
      | (None,last) -> last
      | (Some prefix, last) -> prefix ^ "." ^ last
      end }

(* data *)
data:
| s = STRING
    { ErgoCompiler.Data.dstring (Util.char_list_of_string s) }
| i = INT
    { ErgoCompiler.Data.dnat i }
| f = FLOAT
    { ErgoCompiler.Data.dfloat f }

(* ident *)
ident:
| i = IDENT
    { Util.char_list_of_string i }

(* identlist *)
identlist:
| i = IDENT
    { (Util.char_list_of_string i)::[] }
| i = IDENT COMMA il = identlist
    { (Util.char_list_of_string i)::il }

(* Safe identifier *)
safeident:
| i = safeident_base
    { Util.char_list_of_string i }

safeident_base:
| i = IDENT { i }
| NAMESPACE { "namespace" }
| IMPORT { "import" }
| DEFINE { "define" }
| FUNCTION { "function" }
| CONTRACT { "contract" }
| CONCEPT { "concept" }
| TRANSACTION { "transaction" }
| ENUM { "enum" }
| EXTENDS { "extends" }
| OVER { "over" }
| CLAUSE { "clause" }
| ENFORCE { "enforce" }
| IF { "if" }
| THEN { "then" }
| ELSE { "else" }
| LET { "let" }
| FOR { "for" }
| IN { "in" }
| WHERE { "where" }
| RETURN { "return" }
| THROW { "throw" }
| THROWS { "throws" }
| STATE { "state" }
| VARIABLE { "variable" }
| AS { "as" }
| NEW { "new" }
| MATCH { "match" }
| TYPEMATCH { "typematch" }
| WITH { "with" }
| OR { "or" }
| AND { "and" }
| NIL { "nil" }
| TRUE { "true" }
| FALSE { "false" }

