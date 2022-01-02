// Copyright (c) 2021 zakuro <z@kuro.red>. All rights reserved.
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
module ast

import cotowali.source { Pos }
import cotowali.token { Token }
import cotowali.symbols {
	Scope,
	TupleElement,
	Type,
	TypeSymbol,
	builtin_type,
}
import cotowali.messages { undefined }
import cotowali.util { li_panic, nil_to_none }

pub type Expr = ArrayLiteral
	| AsExpr
	| BoolLiteral
	| CallCommandExpr
	| CallExpr
	| DecomposeExpr
	| DefaultValue
	| Empty
	| FloatLiteral
	| IndexExpr
	| InfixExpr
	| IntLiteral
	| MapLiteral
	| ModuleItem
	| Nameof
	| NullLiteral
	| ParenExpr
	| Pipeline
	| PrefixExpr
	| SelectorExpr
	| StringLiteral
	| Typeof
	| Var

pub fn (expr Expr) children() []Node {
	return match expr {
		DefaultValue, Empty, BoolLiteral, FloatLiteral, IntLiteral, NullLiteral, Var {
			[]Node{}
		}
		ArrayLiteral, AsExpr, CallCommandExpr, CallExpr, DecomposeExpr, IndexExpr, InfixExpr,
		MapLiteral, ModuleItem, Nameof, ParenExpr, Pipeline, PrefixExpr, SelectorExpr, Typeof {
			expr.children()
		}
		StringLiteral {
			// V says, error: method `ast.StringLiteral.children` signature is different
			expr.children()
		}
	}
}

fn (mut r Resolver) exprs(exprs []Expr, opt ResolveExprOpt) {
	for expr in exprs {
		r.expr(expr, opt)
	}
}

[params]
struct ResolveExprOpt {
	is_left_of_assignment bool
}

fn (mut r Resolver) expr(expr Expr, opt ResolveExprOpt) {
	match mut expr {
		ArrayLiteral { r.array_literal(mut expr, opt) }
		AsExpr { r.as_expr(expr, opt) }
		BoolLiteral { r.bool_literal(expr, opt) }
		CallCommandExpr { r.call_command_expr(expr, opt) }
		CallExpr { r.call_expr(mut expr, opt) }
		DecomposeExpr { r.decompose_expr(expr, opt) }
		DefaultValue { r.default_value(expr, opt) }
		Empty {}
		FloatLiteral { r.float_literal(expr, opt) }
		IndexExpr { r.index_expr(expr, opt) }
		InfixExpr { r.infix_expr(expr, opt) }
		IntLiteral { r.int_literal(expr, opt) }
		MapLiteral { r.map_literal(mut expr, opt) }
		ModuleItem { r.module_item(mut expr, opt) }
		NullLiteral { r.null_literal(expr, opt) }
		Nameof { r.nameof(expr, opt) }
		ParenExpr { r.paren_expr(expr, opt) }
		Pipeline { r.pipeline(expr, opt) }
		PrefixExpr { r.prefix_expr(mut expr, opt) }
		SelectorExpr { r.selector_expr(expr, opt) }
		StringLiteral { r.string_literal(expr, opt) }
		Typeof { r.typeof_(expr, opt) }
		Var { r.var_(mut expr, opt) }
	}
}

pub fn (e InfixExpr) pos() Pos {
	return e.left.pos().merge(e.right.pos())
}

pub fn (expr Expr) pos() Pos {
	return match expr {
		ArrayLiteral, AsExpr, CallCommandExpr, CallExpr, DecomposeExpr, DefaultValue, ParenExpr,
		IndexExpr, MapLiteral, Empty {
			expr.pos
		}
		InfixExpr {
			expr.pos()
		}
		Var {
			expr.pos()
		}
		ModuleItem {
			expr.pos()
		}
		Nameof {
			expr.pos()
		}
		SelectorExpr {
			expr.pos()
		}
		Typeof {
			expr.pos()
		}
		Pipeline {
			expr.exprs.first().pos().merge(expr.exprs.last().pos())
		}
		PrefixExpr {
			expr.op.pos.merge(expr.expr.pos())
		}
		IntLiteral, FloatLiteral, BoolLiteral, NullLiteral {
			expr.token.pos
		}
		StringLiteral {
			expr.pos()
		}
	}
}

pub fn (mut e InfixExpr) typ() Type {
	if f := e.overloaded_function() {
		return (f.type_symbol().function_info() or { li_panic(@FN, @FILE, @LINE, 'not a function') }).ret
	}

	if e.op.kind.@is(.comparsion_op) || e.op.kind.@is(.logical_infix_op) {
		return builtin_type(.bool)
	} else if e.left.typ() == builtin_type(.float) || e.right.typ() == builtin_type(.float) {
		return builtin_type(.float)
	}

	left_ts_resolved := e.left.type_symbol().resolved()
	right_ts_resolved := e.right.type_symbol().resolved()

	if left_ts_resolved.kind() == .tuple && right_ts_resolved.kind() == .tuple && e.op.kind == .plus {
		left_elements := (left_ts_resolved.tuple_info() or { li_panic(@FN, @FILE, @LINE, '') }).elements
		right_elements := (right_ts_resolved.tuple_info() or { li_panic(@FN, @FILE, @LINE, '') }).elements
		mut elements := []TupleElement{cap: left_elements.len + right_elements.len}
		elements << left_elements
		elements << right_elements
		return e.scope.lookup_or_register_tuple_type(elements: elements).typ
	}

	return e.right.typ()
}

pub fn (e IndexExpr) typ() Type {
	left_ts := e.left.type_symbol().resolved()

	if array_info := left_ts.array_info() {
		return array_info.elem
	} else if map_info := left_ts.map_info() {
		return map_info.value
	} else if tuple_info := left_ts.tuple_info() {
		if e.index is IntLiteral {
			i := e.index.int()
			if 0 <= i && i < tuple_info.elements.len {
				return tuple_info.elements[i].typ
			}
		}
	} else if left_ts.typ == builtin_type(.string) {
		return builtin_type(.string)
	}
	return builtin_type(.unknown)
}

pub fn (mut e ParenExpr) typ() Type {
	match e.exprs.len {
		0 {
			return e.scope.lookup_or_register_tuple_type(elements: []).typ
		}
		1 {
			return e.exprs[0].typ()
		}
		else {
			mut elems := []TupleElement{cap: e.exprs.len}
			for expr in e.exprs {
				if expr is DecomposeExpr {
					if tuple_info := Expr(expr).type_symbol().tuple_info() {
						elems << tuple_info.elements
						continue
					}
				}
				elems << TupleElement{
					typ: expr.typ()
				}
			}
			return e.scope.lookup_or_register_tuple_type(elements: elems).typ
		}
	}
}

pub fn (e PrefixExpr) typ() Type {
	if f := e.overloaded_function() {
		return (f.type_symbol().function_info() or { li_panic(@FN, @FILE, @LINE, 'not a function') }).ret
	}

	match e.op.kind {
		.amp {
			return if ref := e.scope.lookup_reference_type(target: e.expr.typ()) {
				ref.typ
			} else {
				builtin_type(.placeholder)
			}
		}
		else {
			return e.expr.typ()
		}
	}
}

pub fn (e Expr) typ() Type {
	return match mut e {
		ArrayLiteral { e.scope.lookup_or_register_array_type(elem: e.elem_typ).typ }
		AsExpr { e.typ }
		BoolLiteral { builtin_type(.bool) }
		CallCommandExpr { builtin_type(.string) }
		CallExpr { e.typ }
		DecomposeExpr { e.expr.typ() }
		DefaultValue { e.typ }
		Empty { e.typ() }
		FloatLiteral { builtin_type(.float) }
		StringLiteral { e.typ() }
		IntLiteral { builtin_type(.int) }
		Nameof { e.typ() }
		Typeof { e.typ() }
		NullLiteral { builtin_type(.null) }
		ModuleItem { e.typ() }
		ParenExpr { e.typ() }
		Pipeline { e.exprs.last().typ() }
		PrefixExpr { e.typ() }
		SelectorExpr { e.typ() }
		InfixExpr { e.typ() }
		IndexExpr { e.typ() }
		MapLiteral { e.scope.lookup_or_register_map_type(key: e.key_typ, value: e.value_typ).typ }
		Var { e.typ() }
	}
}

pub fn (e Expr) resolved_typ() Type {
	return e.type_symbol().resolved().typ
}

pub fn (e Expr) type_symbol() &TypeSymbol {
	return e.scope().must_lookup_type(e.typ())
}

pub fn (e Expr) scope() &Scope {
	return match e {
		AsExpr, DecomposeExpr {
			e.expr.scope()
		}
		IndexExpr {
			e.left.scope()
		}
		Var {
			e.scope()
		}
		ModuleItem {
			e.scope()
		}
		Nameof {
			e.scope()
		}
		SelectorExpr {
			e.scope()
		}
		Typeof {
			e.scope()
		}
		ArrayLiteral, BoolLiteral, CallCommandExpr, CallExpr, DefaultValue, Empty, FloatLiteral,
		InfixExpr, IntLiteral, MapLiteral, NullLiteral, ParenExpr, Pipeline, PrefixExpr,
		StringLiteral {
			e.scope
		}
	}
}

pub fn (e Expr) is_glob_literal() bool {
	return if e is StringLiteral { e.is_glob() } else { false }
}

pub fn (e &Expr) @as(typ Type) AsExpr {
	return AsExpr{
		expr: e
		typ: typ
	}
}

pub struct AsExpr {
pub:
	pos  Pos
	expr Expr
	typ  Type
}

pub fn (expr &AsExpr) overloaded_function() ?&symbols.Var {
	f := Expr(expr).scope().lookup_cast_function(from: expr.expr.typ(), to: expr.typ) ?
	if !f.is_function() {
		li_panic(@FN, @FILE, @LINE, 'not a function')
	}
	return f
}

pub fn (expr &AsExpr) overloaded_function_call_expr() ?CallExpr {
	sym := expr.overloaded_function() ?
	scope := Expr(expr).scope()
	return CallExpr{
		scope: scope
		func: Var{
			sym: sym
			ident: Ident{
				scope: scope
				text: sym.name
			}
		}
		args: [expr.expr]
	}
}

pub fn (expr &AsExpr) children() []Node {
	return [Node(expr.expr)]
}

fn (mut r Resolver) as_expr(expr AsExpr, opt ResolveExprOpt) {
	$if trace_resolver ? {
		r.trace_begin(@FN)
		defer {
			r.trace_end()
		}
	}

	r.expr(expr.expr, opt)
}

// ...(expr)
pub struct DecomposeExpr {
pub:
	pos  Pos
	expr Expr
}

pub fn (expr &DecomposeExpr) children() []Node {
	return [Node(expr.expr)]
}

fn (mut r Resolver) decompose_expr(expr DecomposeExpr, opt ResolveExprOpt) {
	$if trace_resolver ? {
		r.trace_begin(@FN)
		defer {
			r.trace_end()
		}
	}

	r.expr(expr.expr, opt)
}

pub struct DefaultValue {
pub:
	scope &Scope
	typ   Type
	pos   Pos
}

fn (mut r Resolver) default_value(expr DefaultValue, opt ResolveExprOpt) {
	$if trace_resolver ? {
		r.trace_begin(@FN)
		defer {
			r.trace_end()
		}
	}
}

pub struct Empty {
pub:
	scope &Scope = 0
	pos   Pos
}

pub fn (e &Empty) typ() Type {
	return builtin_type(.void)
}

pub struct InfixExpr {
pub:
	op Token
pub mut:
	scope &Scope
	left  Expr
	right Expr
}

pub fn (expr &InfixExpr) overloaded_function() ?&symbols.Var {
	left_ts := expr.left.type_symbol()
	right_ts := expr.right.type_symbol()
	fn_var := expr.scope.lookup_infix_op_function(expr.op, left_ts.typ, right_ts.typ) ?
	if !fn_var.is_function() {
		li_panic(@FN, @FILE, @LINE, 'not a function')
	}
	return fn_var
}

pub fn (expr &InfixExpr) overloaded_function_call_expr() ?CallExpr {
	sym := expr.overloaded_function() ?
	return CallExpr{
		scope: expr.scope
		func: Var{
			sym: sym
			ident: Ident{
				scope: expr.scope
				text: sym.name
			}
		}
		args: [expr.left, expr.right]
	}
}

[inline]
pub fn (expr &InfixExpr) children() []Node {
	return [Node(expr.left), Node(expr.right)]
}

fn (mut r Resolver) infix_expr(expr InfixExpr, opt ResolveExprOpt) {
	$if trace_resolver ? {
		r.trace_begin(@FN)
		defer {
			r.trace_end()
		}
	}

	r.expr(expr.left, opt)
	r.expr(expr.right, opt)
}

pub struct IndexExpr {
pub:
	pos   Pos
	left  Expr
	index Expr
}

[inline]
pub fn (expr &IndexExpr) children() []Node {
	return [Node(expr.left), Node(expr.index)]
}

fn (mut r Resolver) index_expr(expr IndexExpr, opt ResolveExprOpt) {
	$if trace_resolver ? {
		r.trace_begin(@FN)
		defer {
			r.trace_end()
		}
	}

	r.expr(expr.left, opt)
	r.expr(expr.index, opt)
}

pub struct ModuleItem {
	scope &Scope
mut:
	is_resolved bool
pub:
	is_global bool
pub mut:
	modules []Ident
	item    Var
}

[inline]
pub fn (expr &ModuleItem) is_resolved() bool {
	return expr.is_resolved
}

pub fn (expr &ModuleItem) typ() Type {
	return expr.item.typ()
}

pub fn (expr &ModuleItem) scope() &Scope {
	return expr.scope
}

pub fn (expr &ModuleItem) pos() Pos {
	return expr.modules.first().pos.merge(expr.item.pos())
}

pub fn (expr &ModuleItem) children() []Node {
	mut nodes := expr.modules.map(Node(it))
	nodes << Expr(expr.item)
	return nodes
}

fn (mut r Resolver) module_item(mut expr ModuleItem, opt ResolveExprOpt) {
	$if trace_resolver ? {
		r.trace_begin(@FN)
		defer {
			r.trace_end()
		}
	}

	mut scope := expr.scope

	if expr.is_global {
		scope = scope.root()
	} else {
		$if !prod {
			if expr.modules.len == 0 {
				li_panic(@FN, @FILE, @LINE, 'module item: modules.len = 0')
			}
		}

		// lookup first mod.
		first_mod := expr.modules[0]
		for {
			if _ := scope.get_child(first_mod.text) {
				break
			}
			scope = scope.parent() or {
				r.error(undefined(.mod, first_mod.text), first_mod.pos)
				return
			}
		}
	}

	// get submod
	expr.is_resolved = true
	for mod in expr.modules {
		scope = scope.get_child(mod.text) or {
			r.error(undefined(.mod, mod.text), mod.pos)
			expr.is_resolved = false
			break
		}
	}

	if expr.is_resolved {
		expr.item.ident.scope = scope
		r.var_(mut expr.item, opt)
	}
}

pub struct ParenExpr {
pub:
	pos   Pos
	exprs []Expr
pub mut:
	scope &Scope
}

[inline]
pub fn (expr &ParenExpr) children() []Node {
	return expr.exprs.map(Node(it))
}

fn (mut r Resolver) paren_expr(expr ParenExpr, opt ResolveExprOpt) {
	$if trace_resolver ? {
		r.trace_begin(@FN)
		defer {
			r.trace_end()
		}
	}

	r.exprs(expr.exprs, opt)
}

// TODO: merge into InfixExpr
// expr |> expr |> expr
pub struct Pipeline {
pub:
	scope     &Scope
	is_append bool // expr |>> "file"
pub mut:
	exprs []Expr
}

fn is_str_or_null(t Type) bool {
	return t in [builtin_type(.string), builtin_type(.null)]
}

pub fn (expr &Pipeline) has_redirect() bool {
	last := expr.exprs.last()
	return if last is CallExpr {
		fn_info := last.func.type_symbol().function_info() or { return false }
		fn_info.pipe_in == builtin_type(.void) && is_str_or_null(fn_info.ret)
	} else {
		last !is CallCommandExpr && is_str_or_null(last.resolved_typ())
	}
}

[inline]
pub fn (expr &Pipeline) children() []Node {
	return expr.exprs.map(Node(it))
}

fn (mut r Resolver) pipeline(expr Pipeline, opt ResolveExprOpt) {
	$if trace_resolver ? {
		r.trace_begin(@FN)
		defer {
			r.trace_end()
		}
	}

	r.exprs(expr.exprs, opt)
}

pub struct PrefixExpr {
pub:
	op Token
pub mut:
	scope &Scope
	expr  Expr
}

[inline]
pub fn (expr &PrefixExpr) children() []Node {
	return [Node(expr.expr)]
}

pub fn (expr &PrefixExpr) is_literal() bool {
	return match expr.expr {
		PrefixExpr { expr.expr.is_literal() }
		IntLiteral, FloatLiteral { true }
		else { false }
	}
}

pub fn (expr &PrefixExpr) int() int {
	n := match expr.expr {
		PrefixExpr { expr.expr.int() }
		IntLiteral { expr.expr.int() }
		else { 0 }
	}
	return if expr.op.kind == .minus { -n } else { n }
}

pub fn (expr &PrefixExpr) overloaded_function() ?&symbols.Var {
	operand_typ := expr.expr.typ()
	fn_var := expr.scope.lookup_prefix_op_function(expr.op, operand_typ) ?
	if !fn_var.is_function() {
		li_panic(@FN, @FILE, @LINE, 'not a function')
	}
	return fn_var
}

pub fn (expr &PrefixExpr) overloaded_function_call_expr() ?CallExpr {
	sym := expr.overloaded_function() ?
	return CallExpr{
		scope: expr.scope
		func: Var{
			sym: sym
			ident: Ident{
				scope: expr.scope
				text: sym.name
			}
		}
		args: [expr.expr]
	}
}

pub fn (expr &PrefixExpr) convert_to_infix_expr() ?InfixExpr {
	if expr.op.kind == .minus {
		return InfixExpr{
			scope: expr.scope
			left: IntLiteral{
				scope: expr.scope
				token: Token{
					kind: .int_literal
					text: '-1'
				}
			}
			right: expr.expr
			op: Token{
				kind: .mul
				text: '*'
			}
		}
	}
	return none
}

fn (mut r Resolver) prefix_expr(mut expr PrefixExpr, opt ResolveExprOpt) {
	$if trace_resolver ? {
		r.trace_begin(@FN)
		defer {
			r.trace_end()
		}
	}

	r.expr(expr.expr, opt)
	if expr.op.kind == .amp && expr.expr.typ() != builtin_type(.placeholder) {
		expr.scope.lookup_or_register_reference_type(target: expr.expr.typ())
	}
}

// TODO: merge Var to Ident
pub struct Ident {
pub mut:
	scope &Scope
pub:
	pos  Pos
	text string
}

pub struct SelectorExpr {
pub mut:
	left  Expr
	ident Var
}

pub fn (expr &SelectorExpr) typ() Type {
	return expr.ident.typ()
}

pub fn (expr &SelectorExpr) scope() &Scope {
	return expr.ident.scope()
}

pub fn (expr &SelectorExpr) pos() Pos {
	return expr.left.pos().merge(expr.ident.pos())
}

pub fn (expr &SelectorExpr) children() []Node {
	return [Node(expr.left), Node(Expr(expr.ident))]
}

fn (mut r Resolver) selector_expr(expr SelectorExpr, opt ResolveExprOpt) {
	$if trace_resolver ? {
		r.trace_begin(@FN)
		defer {
			r.trace_end()
		}
	}

	r.expr(expr.left)
}

pub struct Var {
mut:
	sym &symbols.Var = 0
pub mut:
	ident Ident
}

pub fn (v Var) pos() Pos {
	return v.ident.pos
}

pub fn (v Var) scope() &Scope {
	return v.ident.scope
}

pub fn (v Var) typ() Type {
	return if sym := v.sym() { sym.typ } else { builtin_type(.placeholder) }
}

pub fn (v Var) sym() ?&symbols.Var {
	return nil_to_none(v.sym)
}

pub fn (v Var) name() string {
	return v.ident.text
}

[inline]
pub fn (v Var) children() []Node {
	return [Node(v.ident)]
}

fn (mut r Resolver) var_(mut v Var, opt ResolveExprOpt) {
	$if trace_resolver ? {
		r.trace_begin(@FN)
		defer {
			r.trace_end()
		}
	}

	$if !prod {
		if !isnil(v.sym) && v.sym.name != v.ident.text {
			li_panic(@FN, @FILE, @LINE, 'mismatched name: sym.name = $v.sym.name, ident.text = $v.ident.text')
		}
	}

	if v.typ() == builtin_type(.placeholder) {
		name := if isnil(v.sym) { v.ident.text } else { v.sym.name }
		if name == '_' && opt.is_left_of_assignment {
			v.sym = &symbols.Var{
				name: name
				typ: builtin_type(.any)
			}
		} else if sym := v.scope().lookup_var_with_pos(name, v.pos()) {
			v.sym = sym
		} else if sym := v.scope().lookup_function(name) {
			v.sym = sym
		} else {
			r.error(undefined(.variable, name), v.pos())
		}
	}
}
