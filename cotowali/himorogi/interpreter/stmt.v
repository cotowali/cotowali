// Copyright (c) 2021-2023 zakuro <z@kuro.red>. All rights reserved.
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
module interpreter

import cotowali.ast { Stmt }
import cotowali.symbols { builtin_type }
// import cotowali.token
import cotowali.util { li_panic }

fn (mut e Interpreter) stmts(stmts []Stmt) {
	for stmt in stmts {
		e.stmt(stmt)
	}
}

fn (mut e Interpreter) stmt(stmt Stmt) {
	match stmt {
		ast.AssertStmt { e.assert_stmt(stmt) }
		ast.FnDecl { e.fn_decl(stmt) }
		ast.Block { e.block(stmt) }
		ast.Break { e.break_(stmt) }
		ast.Continue { e.continue_(stmt) }
		ast.Expr { e.expr_stmt(stmt) }
		ast.AssignStmt { e.assign_stmt(stmt) }
		ast.DocComment { e.doc_comment(stmt) }
		ast.Empty {}
		ast.ForInStmt { e.for_in_stmt(stmt) }
		ast.IfStmt { e.if_stmt(stmt) }
		ast.InlineShell { e.inline_shell(stmt) }
		ast.ModuleDecl { e.module_decl(stmt) }
		ast.ReturnStmt { e.return_stmt(stmt) }
		ast.RequireStmt { e.require_stmt(stmt) }
		ast.WhileStmt { e.while_stmt(stmt) }
		ast.YieldStmt { e.yield_stmt(stmt) }
	}
}

fn (mut e Interpreter) assert_stmt(stmt ast.AssertStmt) {
	if e.expr(stmt.cond()).bool() {
		return
	}

	eprint('LINE ${stmt.pos.line}: Assertion Failed')
	if msg_expr := stmt.message_expr() {
		eprint(': ${msg_expr}')
	}
	eprintln('')

	is_test := if f := e.current_fn() { f.is_test() } else { false }
	if is_test {
		todo(@FN, @FILE, @LINE)
	}

	exit(1)
}

fn (mut e Interpreter) block(block ast.Block) {
	for stmt in block.stmts {
		e.stmt(stmt)
	}
}

fn (mut e Interpreter) break_(stmt ast.Break) {
	todo(@FN, @FILE, @LINE)
}

fn (mut e Interpreter) continue_(stmt ast.Continue) {
	todo(@FN, @FILE, @LINE)
}

fn (mut e Interpreter) doc_comment(comment ast.DocComment) {
	// Nothing to do
}

fn (mut e Interpreter) expr_stmt(expr ast.Expr) {
	if expr is ast.Empty {
		return
	}
	value := e.expr(expr)
	redirect_to_null := (if current_fn := e.current_fn() {
		match expr {
			ast.CallExpr { current_fn.function_info().ret != builtin_type(.void) }
			ast.Pipeline { !expr.has_redirect() }
			else { true }
		}
	} else {
		false
	}) && expr.typ() != builtin_type(.void)

	if !redirect_to_null {
		e.println(value)
	}
}

fn (mut e Interpreter) for_in_stmt(stmt ast.ForInStmt) {
	todo(@FN, @FILE, @LINE)
}

fn (mut e Interpreter) if_stmt(stmt ast.IfStmt) {
}

fn (mut e Interpreter) inline_shell(stmt ast.InlineShell) {
	li_panic(@FN, @FILE, @LINE, 'inline shell is not supported in himorogi')
}

fn (mut e Interpreter) module_decl(ns ast.ModuleDecl) {
	e.block(ns.block)
}

fn (mut e Interpreter) require_stmt(stmt ast.RequireStmt) {
	e.file(stmt.file)
}

fn (mut e Interpreter) while_stmt(stmt ast.WhileStmt) {
	todo(@FN, @FILE, @LINE)
}
