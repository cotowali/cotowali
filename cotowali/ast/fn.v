// Copyright (c) 2021 zakuro <z@kuro.red>. All rights reserved.
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
module ast

import cotowali.source { Pos }
import cotowali.symbols { ArrayTypeInfo, FunctionTypeInfo, Scope, Type, TypeSymbol, builtin_fn_id }
import cotowali.errors { unreachable }

pub struct FnDecl {
pub:
	parent_scope &Scope
	name_pos     Pos
	name         string
	has_body     bool
	typ          Type
pub mut:
	attrs  []Attr
	params []Var
	body   Block
}

pub fn (f FnDecl) is_varargs() bool {
	syms := f.function_info().params.map(f.parent_scope.must_lookup_type(it))
	if syms.len > 0 {
		last := syms.last()
		if last.info is ArrayTypeInfo {
			return last.info.variadic
		}
	}
	return false
}

pub fn (f FnDecl) function_info() FunctionTypeInfo {
	return f.type_symbol().function_info() or { panic(unreachable(err)) }
}

pub fn (f FnDecl) type_symbol() &TypeSymbol {
	return f.parent_scope.must_lookup_type(f.typ)
}

pub fn (f FnDecl) signature() string {
	return f.type_symbol().fn_signature() or { panic(unreachable(err)) }
}

pub fn (f FnDecl) ret_type_symbol() &TypeSymbol {
	return f.parent_scope.must_lookup_type(f.function_info().ret)
}

fn (mut r Resolver) fn_decl(decl FnDecl) {
	$if trace_resolver ? {
		r.trace_begin(@FN)
		defer {
			r.trace_end()
		}
	}

	r.block(decl.body)
}

// --

pub struct ReturnStmt {
pub:
	expr Expr
}

fn (mut r Resolver) return_stmt(stmt ReturnStmt) {
	$if trace_resolver ? {
		r.trace_begin(@FN)
		defer {
			r.trace_end()
		}
	}
	r.expr(stmt.expr)
}

pub struct YieldStmt {
pub:
	pos  Pos
	expr Expr
}

fn (mut r Resolver) yield_stmt(stmt YieldStmt) {
	$if trace_resolver ? {
		r.trace_begin(@FN)
		defer {
			r.trace_end()
		}
	}

	r.expr(stmt.expr)
}

// --

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
