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

pub type Expr = ArrayLiteral | AsExpr | BoolLiteral | CallCommandExpr | CallExpr | DefaultValue |
	FloatLiteral | IndexExpr | InfixExpr | IntLiteral | MapLiteral | NamespaceItem | ParenExpr |
	Pipeline | PrefixExpr | StringLiteral | Var

pub fn (expr Expr) children() []Node {
	return match expr {
		DefaultValue, BoolLiteral, FloatLiteral, IntLiteral, Var {
			[]Node{}
		}
		ArrayLiteral, AsExpr, CallCommandExpr, CallExpr, IndexExpr, InfixExpr, MapLiteral,
		NamespaceItem, ParenExpr, Pipeline, PrefixExpr {
			expr.children()
		}
		StringLiteral {
			// V says, error: method `ast.StringLiteral.children` signature is different
			expr.children()
		}
	}
}

fn (mut r Resolver) exprs(exprs []Expr) {
	for expr in exprs {
		r.expr(expr)
	}
}

fn (mut r Resolver) expr(expr Expr) {
	match mut expr {
		ArrayLiteral { r.array_literal(mut expr) }
		AsExpr { r.as_expr(expr) }
		BoolLiteral { r.bool_literal(expr) }
		CallCommandExpr { r.call_command_expr(expr) }
		CallExpr { r.call_expr(mut expr) }
		DefaultValue { r.default_value(expr) }
		FloatLiteral { r.float_literal(expr) }
		IndexExpr { r.index_expr(expr) }
		InfixExpr { r.infix_expr(expr) }
		IntLiteral { r.int_literal(expr) }
		MapLiteral { r.map_literal(mut expr) }
		NamespaceItem { r.namespace_item(mut expr) }
		ParenExpr { r.paren_expr(expr) }
		Pipeline { r.pipeline(expr) }
		PrefixExpr { r.prefix_expr(mut expr) }
		StringLiteral { r.string_literal(expr) }
		Var { r.var_(mut expr) }
	}
}

pub fn (e InfixExpr) pos() Pos {
	return e.left.pos().merge(e.right.pos())
}

pub fn (expr Expr) pos() Pos {
	return match expr {
		ArrayLiteral, AsExpr, CallCommandExpr, CallExpr, DefaultValue, ParenExpr, IndexExpr,
		MapLiteral {
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
	return match e.exprs.len {
		0 {
			e.scope.lookup_or_register_tuple_type().typ
		}
		1 {
			e.exprs[0].typ()
		}
		else {
			e.scope.lookup_or_register_tuple_type(
				elements: e.exprs.map(TupleElement{ typ: it.typ() })
			).typ
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
		AsExpr {
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

fn (mut r Resolver) as_expr(expr AsExpr) {
	$if trace_resolver ? {
		r.trace_begin(@FN)
		defer {
			r.trace_end()
		}
	}

	r.expr(expr.expr)
}

pub struct DefaultValue {
pub:
	scope &Scope
	typ   Type
	pos   Pos
}

fn (mut r Resolver) default_value(expr DefaultValue) {
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

fn (mut r Resolver) infix_expr(expr InfixExpr) {
	$if trace_resolver ? {
		r.trace_begin(@FN)
		defer {
			r.trace_end()
		}
	}

	r.expr(expr.left)
	r.expr(expr.right)
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

fn (mut r Resolver) index_expr(expr IndexExpr) {
	$if trace_resolver ? {
		r.trace_begin(@FN)
		defer {
			r.trace_end()
		}
	}

	r.expr(expr.left)
	r.expr(expr.index)
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

fn (mut r Resolver) namespace_item(mut expr NamespaceItem) {
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
		r.expr(expr.item)
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

fn (mut r Resolver) paren_expr(expr ParenExpr) {
	$if trace_resolver ? {
		r.trace_begin(@FN)
		defer {
			r.trace_end()
		}
	}

	r.exprs(expr.exprs)
}

// expr |> expr |> expr
pub struct Pipeline {
pub:
	scope &Scope
pub mut:
	exprs []Expr
}

[inline]
pub fn (expr &Pipeline) children() []Node {
	return expr.exprs.map(Node(it))
}

fn (mut r Resolver) pipeline(expr Pipeline) {
	$if trace_resolver ? {
		r.trace_begin(@FN)
		defer {
			r.trace_end()
		}
	}

	r.exprs(expr.exprs)
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

fn (mut r Resolver) prefix_expr(mut expr PrefixExpr) {
	$if trace_resolver ? {
		r.trace_begin(@FN)
		defer {
			r.trace_end()
		}
	}

	r.expr(expr.expr)
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

fn (mut r Resolver) var_(mut v Var) {
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
		if sym := v.scope().lookup_var_with_pos(name, v.pos()) {
			v.sym = sym
		} else {
			r.error('undefined variable `$name`', v.pos())
		}
	}
}
