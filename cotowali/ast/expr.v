// Copyright (c) 2021 zakuro <z@kuro.red>. All rights reserved.
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
module ast

import cotowali.source { Pos }
import cotowali.token { Token }
import cotowali.symbols { ArrayTypeInfo, MapTypeInfo, Scope, Type, TypeSymbol, builtin_type }
import cotowali.errors { unreachable }

pub type Expr = ArrayLiteral | AsExpr | BoolLiteral | CallCommandExpr | CallExpr | DefaultValue |
	FloatLiteral | IndexExpr | InfixExpr | IntLiteral | MapLiteral | ParenExpr | Pipeline |
	PrefixExpr | StringLiteral | Var

pub fn (expr Expr) children() []Node {
	return match expr {
		DefaultValue, BoolLiteral, FloatLiteral, IntLiteral, Var {
			[]Node{}
		}
		ArrayLiteral, AsExpr, CallCommandExpr, CallExpr, IndexExpr, InfixExpr, MapLiteral,
		ParenExpr, Pipeline, PrefixExpr {
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
		ParenExpr { r.paren_expr(expr) }
		Pipeline { r.pipeline(expr) }
		PrefixExpr { r.prefix_expr(mut expr) }
		StringLiteral { r.string_literal(expr) }
		Var { r.var_(mut expr) }
	}
}

fn (mut r Resolver) set_typ(e Expr, typ Type) {
	match mut e {
		Var { e.sym.typ = typ }
		else { panic(unreachable(error('cannot set type'))) }
	}
}

pub fn (e InfixExpr) pos() Pos {
	return e.left.pos().merge(e.right.pos())
}

pub fn (expr Expr) pos() Pos {
	return match expr {
		ArrayLiteral, AsExpr, CallCommandExpr, CallExpr, DefaultValue, Var, ParenExpr, IndexExpr,
		MapLiteral {
			expr.pos
		}
		InfixExpr {
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

pub fn (e InfixExpr) typ() Type {
	return if e.op.kind.@is(.comparsion_op) || e.op.kind.@is(.logical_infix_op) {
		builtin_type(.bool)
	} else if e.left.typ() == builtin_type(.float) || e.right.typ() == builtin_type(.float) {
		builtin_type(.float)
	} else {
		e.right.typ()
	}
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
		0 { e.scope.lookup_or_register_tuple_type().typ }
		1 { e.exprs[0].typ() }
		else { e.scope.lookup_or_register_tuple_type(elements: e.exprs.map(it.typ())).typ }
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
		ParenExpr { e.typ() }
		Pipeline { e.exprs.last().typ() }
		PrefixExpr { e.typ() }
		InfixExpr { e.typ() }
		IndexExpr { e.typ() }
		MapLiteral { e.scope.lookup_or_register_map_type(key: e.key_typ, value: e.value_typ).typ }
		Var { e.sym.typ }
	}
}

pub fn (e Expr) resolved_typ() Type {
	return e.type_symbol().resolved().typ
}

[inline]
pub fn (v Var) type_symbol() &TypeSymbol {
	return v.sym.type_symbol()
}

pub fn (e Expr) type_symbol() &TypeSymbol {
	return match e {
		Var { e.type_symbol() }
		else { e.scope().must_lookup_type(e.typ()) }
	}
}

pub fn (e Expr) scope() &Scope {
	return match e {
		AsExpr {
			e.expr.scope()
		}
		IndexExpr {
			e.left.scope()
		}
		ArrayLiteral, BoolLiteral, CallCommandExpr, CallExpr, DefaultValue, FloatLiteral,
		InfixExpr, IntLiteral, MapLiteral, ParenExpr, Pipeline, PrefixExpr, StringLiteral, Var {
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
	scope &Scope
	op    Token
pub mut:
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

pub struct Var {
pub:
	scope &Scope
	pos   Pos
pub mut:
	sym &symbols.Var
}

pub fn (v Var) name() string {
	return v.sym.name
}

[inline]
pub fn (_ Var) children() []Node {
	return []
}

fn (mut r Resolver) var_(mut v Var) {
	$if trace_resolver ? {
		r.trace_begin(@FN)
		defer {
			r.trace_end()
		}
	}

	if v.sym.typ == builtin_type(.placeholder) {
		name := v.sym.name
		if sym := v.scope.lookup_var_with_pos(name, v.pos) {
			v.sym = sym
		} else {
			r.error('undefined variable `$name`', v.pos)
		}
	}
}
