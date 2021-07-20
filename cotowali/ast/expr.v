// Copyright (c) 2021 zakuro <z@kuro.red>. All rights reserved.
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
module ast

import cotowali.source { Pos }
import cotowali.token { Token }
import cotowali.symbols { ArrayTypeInfo, FunctionTypeInfo, MapTypeInfo, Scope, Type, TypeSymbol, builtin_fn_id, builtin_type }
import cotowali.errors { unreachable }

pub type Expr = ArrayLiteral | AsExpr | BoolLiteral | CallCommandExpr | CallExpr | DefaultValue |
	FloatLiteral | IndexExpr | InfixExpr | IntLiteral | MapLiteral | ParenExpr | Pipeline |
	PrefixExpr | StringLiteral | Var

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
		StringLiteral, IntLiteral, FloatLiteral, BoolLiteral {
			expr.token.pos
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
	left_info := e.left.type_symbol().info
	return match left_info {
		ArrayTypeInfo { left_info.elem }
		MapTypeInfo { left_info.value }
		else { builtin_type(.unknown) }
	}
}

pub fn (mut e ParenExpr) typ() Type {
	return match e.exprs.len {
		0 { e.scope.lookup_or_register_tuple_type({}).typ }
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

fn (mut r Resolver) as_expr(expr AsExpr) {
	$if trace_resolver ? {
		r.trace_begin(@FN)
		defer {
			r.trace_end()
		}
	}

	r.expr(expr.expr)
}

pub struct CallCommandExpr {
pub:
	pos     Pos
	command string
	args    []Expr
pub mut:
	scope &Scope
}

fn (mut r Resolver) call_command_expr(expr CallCommandExpr) {
	$if trace_resolver ? {
		r.trace_begin(@FN)
		defer {
			r.trace_end()
		}
	}
	r.exprs(expr.args)
}

pub struct CallExpr {
mut:
	typ Type
pub:
	pos Pos
pub mut:
	scope   &Scope
	func_id u64
	func    Expr
	args    []Expr
}

pub fn (e CallExpr) is_varargs() bool {
	syms := e.function_info().params.map(e.scope.must_lookup_type(it))
	if syms.len > 0 {
		last := syms.last()
		if last.info is ArrayTypeInfo {
			return last.info.variadic
		}
	}
	return false
}

pub fn (e CallExpr) function_info() FunctionTypeInfo {
	return e.func.type_symbol().function_info() or { panic(unreachable(err)) }
}

fn (mut r Resolver) call_expr(mut expr CallExpr) {
	$if trace_resolver ? {
		r.trace_begin(@FN)
		defer {
			r.trace_end()
		}
	}

	r.call_expr_func(mut expr)
	r.exprs(expr.args)
}

fn (mut r Resolver) call_expr_func(mut e CallExpr) {
	if mut e.func is Var {
		name := e.func.name()
		sym := e.scope.lookup_var(name) or {
			r.error('function `$name` is not defined', e.pos)
			return
		}

		e.func.sym = sym

		ts := sym.type_symbol()
		if !sym.is_function() {
			r.error('`$sym.name` is not function (`$ts.name`)', e.pos)
			return
		}

		function_info := e.function_info()
		e.typ = function_info.ret
		e.func_id = sym.id
		if owner := e.scope.owner() {
			if sym.id == builtin_fn_id(.read) {
				owner_function_info := owner.type_symbol().function_info() or {
					panic(unreachable(err))
				}
				mut pipe_in := e.scope.must_lookup_type(owner_function_info.pipe_in)
				if pipe_in_array_info := pipe_in.array_info() {
					if pipe_in_array_info.variadic {
						pipe_in = e.scope.must_lookup_type(pipe_in_array_info.elem)
					}
				}
				new_fn_params := if pipe_in_tuple_info := pipe_in.tuple_info() {
					elements := pipe_in_tuple_info.elements
					elements.map(e.scope.lookup_or_register_reference_type(target: it).typ)
				} else {
					[e.scope.lookup_or_register_reference_type(target: pipe_in.typ).typ]
				}
				e.func.sym = if new_fn := e.scope.register_fn(sym.name, params: new_fn_params) {
					new_fn
				} else {
					// already registered
					e.scope.must_lookup_var(sym.name)
				}
			}
		}
	} else {
		r.error('cannot call `$e.func.type_symbol().name`', e.pos)
	}
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

pub struct MapLiteralEntry {
pub:
	key   Expr
	value Expr
}

pub struct MapLiteral {
pub:
	pos     Pos
	entries []MapLiteralEntry
pub mut:
	scope     &Scope
	key_typ   Type
	value_typ Type
}

fn (mut r Resolver) map_literal(mut expr MapLiteral) {
	$if trace_resolver ? {
		r.trace_begin(@FN)
		defer {
			r.trace_end()
		}
	}

	for entry in expr.entries {
		r.expr(entry.key)
		r.expr(entry.value)
	}
	if expr.entries.len > 0 {
		entry := expr.entries[0]
		if expr.key_typ == builtin_type(.placeholder) {
			expr.key_typ = entry.key.typ()
		}
		if expr.value_typ == builtin_type(.placeholder) {
			expr.value_typ = entry.value.typ()
		}
	}
}

pub struct ParenExpr {
pub:
	pos   Pos
	exprs []Expr
pub mut:
	scope &Scope
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

pub struct PrimitiveLiteral {
pub:
	scope &Scope
	token Token
}

pub type BoolLiteral = PrimitiveLiteral
pub type StringLiteral = PrimitiveLiteral
pub type IntLiteral = PrimitiveLiteral
pub type FloatLiteral = PrimitiveLiteral

pub fn (e BoolLiteral) bool() bool {
	return e.token.text != 'false'
}

fn (mut r Resolver) bool_literal(expr BoolLiteral) {
	$if trace_resolver ? {
		r.trace_begin(@FN)
		defer {
			r.trace_end()
		}
	}
}

fn (mut r Resolver) string_literal(expr StringLiteral) {
	$if trace_resolver ? {
		r.trace_begin(@FN)
		defer {
			r.trace_end()
		}
	}
}

fn (mut r Resolver) int_literal(expr IntLiteral) {
	$if trace_resolver ? {
		r.trace_begin(@FN)
		defer {
			r.trace_end()
		}
	}
}

fn (mut r Resolver) float_literal(expr FloatLiteral) {
	$if trace_resolver ? {
		r.trace_begin(@FN)
		defer {
			r.trace_end()
		}
	}
}

pub struct ArrayLiteral {
pub:
	pos Pos
pub mut:
	elem_typ Type
	scope    &Scope
	elements []Expr
}

fn (mut r Resolver) array_literal(mut expr ArrayLiteral) {
	$if trace_resolver ? {
		r.trace_begin(@FN)
		defer {
			r.trace_end()
		}
	}

	r.exprs(expr.elements)
	if expr.elements.len > 0 && expr.elem_typ == builtin_type(.placeholder) {
		expr.elem_typ = expr.elements[0].typ()
	}
}

// expr |> expr |> expr
pub struct Pipeline {
pub:
	scope &Scope
pub mut:
	exprs []Expr
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
