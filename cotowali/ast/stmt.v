// Copyright (c) 2021 zakuro <z@kuro.red>. All rights reserved.
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
module ast

import cotowali.source { Pos }
import cotowali.symbols { ArrayTypeInfo, FunctionTypeInfo, Scope, Type, TypeSymbol }
import cotowali.errors { unreachable }

pub type Stmt = AssertStmt | AssignStmt | Block | EmptyStmt | Expr | FnDecl | ForInStmt |
	IfStmt | InlineShell | RequireStmt | ReturnStmt | WhileStmt | YieldStmt

fn (mut r Resolver) stmts(stmts []Stmt) {
	for stmt in stmts {
		r.stmt(stmt)
	}
}

fn (mut r Resolver) stmt(stmt Stmt) {
	match mut stmt {
		AssertStmt { r.assert_stmt(stmt) }
		AssignStmt { r.assign_stmt(mut stmt) }
		Block { r.block(stmt) }
		EmptyStmt { r.empty_stmt(stmt) }
		Expr { r.expr(stmt) }
		FnDecl { r.fn_decl(stmt) }
		ForInStmt { r.for_in_stmt(mut stmt) }
		IfStmt { r.if_stmt(stmt) }
		InlineShell { r.inline_shell(stmt) }
		RequireStmt { r.require_stmt(stmt) }
		ReturnStmt { r.return_stmt(stmt) }
		WhileStmt { r.while_stmt(stmt) }
		YieldStmt { r.yield_stmt(stmt) }
	}
}

pub struct AssignStmt {
mut:
	scope &Scope
pub mut:
	is_decl bool
	left    Expr
	right   Expr
}

fn (mut r Resolver) assign_stmt(mut stmt AssignStmt) {
	$if trace_resolver ? {
		r.trace_begin(@FN)
		defer {
			r.trace_end()
		}
	}

	if !stmt.is_decl {
		r.expr(stmt.left)
	}
	r.expr(stmt.right)

	match mut stmt.left {
		Var {
			if stmt.is_decl {
				r.set_typ(stmt.left, stmt.right.typ())

				sym := stmt.left.sym
				if registered := stmt.scope.register_var(sym) {
					stmt.left.sym = registered
				} else {
					r.duplicated_error(sym.name, sym.pos)
				}
			}
		}
		IndexExpr {}
		ParenExpr {
			// todo
		}
		else {
			r.error('invalid left-hand side of assignment', stmt.left.pos())
		}
	}
}

pub struct AssertStmt {
pub:
	key_pos Pos
pub mut:
	expr Expr
}

fn (mut r Resolver) assert_stmt(stmt AssertStmt) {
	$if trace_resolver ? {
		r.trace_begin(@FN)
		defer {
			r.trace_end()
		}
	}

	r.expr(stmt.expr)
}

pub struct Block {
pub:
	scope &Scope
pub mut:
	stmts []Stmt
}

fn (mut r Resolver) block(stmt Block) {
	$if trace_resolver ? {
		r.trace_begin(@FN)
		defer {
			r.trace_end()
		}
	}

	r.stmts(stmt.stmts)
}

pub struct EmptyStmt {}

fn (mut r Resolver) empty_stmt(stmt EmptyStmt) {
	$if trace_resolver ? {
		r.trace_begin(@FN)
		defer {
			r.trace_end()
		}
	}
}

pub struct FnDecl {
pub:
	parent_scope &Scope
	name_pos     Pos
	name         string
	has_body     bool
	typ          Type
pub mut:
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

pub struct ForInStmt {
pub mut:
	// for var in expr
	var_ Var
	expr Expr
	body Block
}

fn (mut r Resolver) for_in_stmt(mut stmt ForInStmt) {
	$if trace_resolver ? {
		r.trace_begin(@FN)
		defer {
			r.trace_end()
		}
	}

	r.expr(stmt.expr)

	expr_ts := stmt.expr.type_symbol()
	if expr_ts.info is ArrayTypeInfo {
		r.set_typ(stmt.var_, expr_ts.info.elem)
	}

	r.block(stmt.body)
}

pub struct IfBranch {
pub mut:
	cond Expr
pub:
	body Block
}

pub struct IfStmt {
pub mut:
	branches []IfBranch
pub:
	has_else bool
}

fn (mut r Resolver) if_stmt(stmt IfStmt) {
	$if trace_resolver ? {
		r.trace_begin(@FN)
		defer {
			r.trace_end()
		}
	}

	for b in stmt.branches {
		r.expr(b.cond)
		r.block(b.body)
	}
}

pub struct InlineShell {
pub:
	pos  Pos
	text string
}

fn (mut r Resolver) inline_shell(stmt InlineShell) {
	$if trace_resolver ? {
		r.trace_begin(@FN)
		defer {
			r.trace_end()
		}
	}
}

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

pub struct RequireStmt {
pub mut:
	file File
}

fn (mut r Resolver) require_stmt(stmt RequireStmt) {
	$if trace_resolver ? {
		r.trace_begin(@FN)
		defer {
			r.trace_end()
		}
	}

	r.file(stmt.file)
}

pub struct WhileStmt {
pub:
	cond Expr
	body Block
}

fn (mut r Resolver) while_stmt(stmt WhileStmt) {
	$if trace_resolver ? {
		r.trace_begin(@FN)
		defer {
			r.trace_end()
		}
	}

	r.expr(stmt.cond)
	r.block(stmt.body)
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
