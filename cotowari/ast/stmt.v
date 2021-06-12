module ast

import cotowari.source { Pos }
import cotowari.symbols { FunctionTypeInfo, Scope, Type, TypeSymbol }
import cotowari.token { Token }

pub type Stmt = AssertStmt | AssignStmt | Block | EmptyStmt | Expr | FnDecl | ForInStmt |
	IfStmt | InlineShell | RequireStmt | ReturnStmt

fn (mut r Resolver) stmts(stmts []Stmt) {
	for stmt in stmts {
		r.stmt(stmt)
	}
}

fn (mut r Resolver) stmt(stmt Stmt) {
	match stmt {
		AssertStmt { r.assert_stmt(stmt) }
		AssignStmt { r.assign_stmt(stmt) }
		Block { r.block(stmt) }
		EmptyStmt { r.empty_stmt(stmt) }
		Expr { r.expr(stmt) }
		FnDecl { r.fn_decl(stmt) }
		ForInStmt { r.for_in_stmt(stmt) }
		IfStmt { r.if_stmt(stmt) }
		InlineShell { r.inline_shell(stmt) }
		RequireStmt { r.require_stmt(stmt) }
		ReturnStmt { r.return_stmt(stmt) }
	}
}

pub struct AssignStmt {
pub mut:
	is_decl bool
	left    Expr
	right   Expr
}

fn (mut r Resolver) assign_stmt(stmt AssignStmt) {
	$if trace_resolver ? {
		r.trace_begin(@FN)
		defer {
			r.trace_end()
		}
	}

	r.expr(stmt.left)
	r.expr(stmt.right)
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

pub fn (f FnDecl) fn_info() FunctionTypeInfo {
	return f.type_symbol().fn_info()
}

pub fn (f FnDecl) type_symbol() TypeSymbol {
	return f.parent_scope.must_lookup_type(f.typ)
}

pub fn (f FnDecl) ret_type_symbol() TypeSymbol {
	ret := f.parent_scope.must_lookup_type(f.typ).fn_info().ret
	return f.parent_scope.must_lookup_type(ret)
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
	val  Var
	expr Expr
	body Block
}

fn (mut r Resolver) for_in_stmt(stmt ForInStmt) {
	$if trace_resolver ? {
		r.trace_begin(@FN)
		defer {
			r.trace_end()
		}
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
	token Token // key_return token
	expr  Expr
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

pub fn (stmt ReturnStmt) pos() Pos {
	return stmt.token.pos.merge(stmt.expr.pos())
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
