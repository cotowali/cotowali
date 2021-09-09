// Copyright (c) 2021 zakuro <z@kuro.red>. All rights reserved.
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
module ast

import cotowali.source { Pos }
import cotowali.token { Token }
import cotowali.symbols {
	ArrayTypeInfo,
	MapTypeInfo,
	Scope,
	TupleElement,
	Type,
	TypeSymbol,
	builtin_type,
}
import cotowali.errors { unreachable }

pub type Expr = ArrayLiteral | AsExpr | BoolLiteral | CallCommandExpr | CallExpr | DecomposeExpr |
	DefaultValue | FloatLiteral | IndexExpr | InfixExpr | IntLiteral | MapLiteral | NamespaceItem |
	ParenExpr | Pipeline | PrefixExpr | StringLiteral | Var

pub fn (expr Expr) children() []Node {
	return match expr {
		DefaultValue, BoolLiteral, FloatLiteral, IntLiteral, Var {
			[]Node{}
		}
		ArrayLiteral, AsExpr, CallCommandExpr, CallExpr, DecomposeExpr, IndexExpr, InfixExpr,
		MapLiteral, NamespaceItem, ParenExpr, Pipeline, PrefixExpr {
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
		FloatLiteral { r.float_literal(expr, opt) }
		IndexExpr { r.index_expr(expr, opt) }
		InfixExpr { r.infix_expr(expr, opt) }
		IntLiteral { r.int_literal(expr, opt) }
		MapLiteral { r.map_literal(mut expr, opt) }
		NamespaceItem { r.namespace_item(mut expr, opt) }
		ParenExpr { r.paren_expr(expr, opt) }
		Pipeline { r.pipeline(expr, opt) }
		PrefixExpr { r.prefix_expr(mut expr, opt) }
		StringLiteral { r.string_literal(expr, opt) }
		Var { r.var_(mut expr, opt) }
	}
}

pub fn (e InfixExpr) pos() Pos {
	return e.left.pos().merge(e.right.pos())
}

pub fn (expr Expr) pos() Pos {
	return match expr {
		ArrayLiteral, AsExpr, CallCommandExpr, CallExpr, DecomposeExpr, DefaultValue, ParenExpr,
		IndexExpr, MapLiteral {
			expr.pos
		}
		InfixExpr {
			expr.pos()
		}
		Var {
			expr.pos()
		}
		NamespaceItem {
			expr.pos()
		}
		Pipeline {
			expr.exprs.first().pos().merge(expr.exprs.last().pos())
		}
		PrefixExpr {
			expr.op.pos.merge(expr.expr.pos())
		}
		IntLiteral, FloatLiteral, BoolLiteral {
			expr.token.pos
		}
		StringLiteral {
			expr.open.pos.merge(expr.close.pos)
		}
	}
}

pub fn (mut e InfixExpr) typ() Type {
	if e.op.kind.@is(.comparsion_op) || e.op.kind.@is(.logical_infix_op) {
		return builtin_type(.bool)
	} else if e.left.typ() == builtin_type(.float) || e.right.typ() == builtin_type(.float) {
		return builtin_type(.float)
	}

	left_ts := e.left.type_symbol().resolved()
	right_ts := e.right.type_symbol().resolved()

	if left_ts.kind() == .tuple && right_ts.kind() == .tuple && e.op.kind == .plus {
		left_elements := (left_ts.tuple_info() or { panic(unreachable('')) }).elements
		right_elements := (right_ts.tuple_info() or { panic(unreachable('')) }).elements
		mut elements := []TupleElement{cap: left_elements.len + right_elements.len}
		elements << left_elements
		elements << right_elements
		return e.scope.lookup_or_register_tuple_type(elements: elements).typ
	}

	return right_ts.typ
}

pub fn (e IndexExpr) typ() Type {
	left_info := e.left.type_symbol().resolved().info
	return match left_info {
		ArrayTypeInfo { left_info.elem }
		MapTypeInfo { left_info.value }
		else { builtin_type(.unknown) }
	}
}

pub fn (mut e ParenExpr) typ() Type {
	match e.exprs.len {
		0 {
			return e.scope.lookup_or_register_tuple_type().typ
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
		FloatLiteral { builtin_type(.float) }
		StringLiteral { builtin_type(.string) }
		IntLiteral { builtin_type(.int) }
		NamespaceItem { e.typ() }
		ParenExpr { e.typ() }
		Pipeline { e.exprs.last().typ() }
		PrefixExpr { e.typ() }
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
		NamespaceItem {
			e.scope()
		}
		ArrayLiteral, BoolLiteral, CallCommandExpr, CallExpr, DefaultValue, FloatLiteral,
		InfixExpr, IntLiteral, MapLiteral, ParenExpr, Pipeline, PrefixExpr, StringLiteral {
			e.scope
		}
	}
}

pub struct AsExpr {
pub:
	pos  Pos
	expr Expr
	typ  Type
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

pub struct InfixExpr {
pub:
	op Token
pub mut:
	scope &Scope
	left  Expr
	right Expr
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

pub struct NamespaceItem {
mut:
	is_resolved bool
pub mut:
	namespace Ident
	item      Expr
}

[inline]
pub fn (expr &NamespaceItem) is_resolved() bool {
	return expr.is_resolved
}

pub fn (expr &NamespaceItem) typ() Type {
	return expr.item.typ()
}

pub fn (expr &NamespaceItem) scope() &Scope {
	return expr.item.scope()
}

pub fn (expr &NamespaceItem) pos() Pos {
	return expr.namespace.pos.merge(expr.item.pos())
}

[inline]
pub fn (expr &NamespaceItem) children() []Node {
	return [Node(expr.namespace), Node(expr.item)]
}

fn (mut r Resolver) namespace_item(mut expr NamespaceItem, opt ResolveExprOpt) {
	$if trace_resolver ? {
		r.trace_begin(@FN)
		defer {
			r.trace_end()
		}
	}

	if child := expr.namespace.scope.get_child(expr.namespace.text) {
		match mut expr.item {
			NamespaceItem { expr.item.namespace.scope = child }
			Var { expr.item.ident.scope = child }
			else { panic(unreachable('invalid item of namespace')) }
		}
		expr.is_resolved = true
		r.expr(expr.item, opt)
	} else {
		r.error('undefined namespace `$expr.namespace.text`', expr.namespace.pos)
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

// expr |> expr |> expr
pub struct Pipeline {
pub:
	scope &Scope
pub mut:
	exprs []Expr
}

pub fn (expr &Pipeline) has_redirect() bool {
	last := expr.exprs.last()
	return if last is CallExpr {
		fn_info := last.function_info()
		fn_info.pipe_in == builtin_type(.void) && fn_info.ret == builtin_type(.string)
	} else {
		last !is CallCommandExpr && last.resolved_typ() == builtin_type(.string)
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

pub struct Ident {
pub mut:
	scope &Scope
pub:
	pos  Pos
	text string
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
	return if isnil(v.sym) { none } else { v.sym }
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
			panic(unreachable('mismatched name: sym.name = $v.sym.name, ident.text = $v.ident.text'))
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
		} else {
			r.error('undefined variable `$name`', v.pos())
		}
	}
}
