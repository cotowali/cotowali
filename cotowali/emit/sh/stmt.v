// Copyright (c) 2021 zakuro <z@kuro.red>. All rights reserved.
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
module sh

import cotowali.ast { Stmt }
import cotowali.symbols { builtin_type }

fn (mut e Emitter) stmts(stmts []Stmt) {
	for stmt in stmts {
		e.stmt(stmt)
	}
}

fn (mut e Emitter) begin_stmt() {
	e.stmt_head_pos[e.cur_kind] = e.code().pos()
}

fn (mut e Emitter) stmt(stmt Stmt) {
	e.begin_stmt()
	match stmt {
		ast.AssertStmt { e.assert_stmt(stmt) }
		ast.FnDecl { e.fn_decl(stmt) }
		ast.Block { e.block(stmt) }
		ast.Expr { e.expr_stmt(stmt) }
		ast.AssignStmt { e.assign_stmt(stmt) }
		ast.EmptyStmt { e.writeln('') }
		ast.ForInStmt { e.for_in_stmt(stmt) }
		ast.IfStmt { e.if_stmt(stmt) }
		ast.InlineShell { e.writeln(stmt.text) }
		ast.ReturnStmt { e.return_stmt(stmt) }
		ast.RequireStmt { e.require_stmt(stmt) }
		ast.WhileStmt { e.while_stmt(stmt) }
		ast.YieldStmt { e.yield_stmt(stmt) }
	}
}

fn (mut e Emitter) expr_stmt(stmt ast.Expr) {
	discard_stdout := e.inside_fn
		&& if stmt is ast.CallExpr { e.cur_fn.function_info().ret != builtin_type(.void) } else { true }
	e.expr(stmt, mode: .command, discard_stdout: discard_stdout, writeln: true)
}

fn (mut e Emitter) assert_stmt(stmt ast.AssertStmt) {
	e.write('if ')
	e.expr(stmt.expr, mode: .condition, writeln: true)
	e.writeln('then')
	{
		e.writeln(':')
	}
	e.writeln('else')
	{
		e.writeln("echo 'LINE $stmt.key_pos.line: assertion failed' >&2")
		e.writeln('exit 1')
	}
	e.writeln('fi')
}

fn (mut e Emitter) block(block ast.Block) {
	if block.stmts.len > 0 {
		e.stmts(block.stmts)
	} else {
		e.writeln(':')
	}
}

fn (mut e Emitter) if_stmt(stmt ast.IfStmt) {
	for i, branch in stmt.branches {
		mut is_else := i == stmt.branches.len - 1 && stmt.has_else
		if is_else {
			e.writeln('else')
		} else {
			e.write(if i == 0 { 'if ' } else { 'elif ' })
			e.expr(branch.cond, mode: .condition, writeln: true)
			e.writeln('then')
		}
		e.indent()
		e.block(branch.body)
		e.unindent()
	}
	e.writeln('fi')
}

fn (mut e Emitter) for_in_stmt(stmt ast.ForInStmt) {
	tmp := e.new_tmp_ident()
	e.write('for $tmp in ')
	e.expr(stmt.expr, expand_array: true, writeln: true)
	e.writeln('do')
	{
		e.assign(e.ident_for(stmt.var_), '\$(eval echo \$$tmp)')
		e.block(stmt.body)
	}
	e.writeln('done')
}

fn (mut e Emitter) return_stmt(stmt ast.ReturnStmt) {
	e.expr(stmt.expr, mode: .command, writeln: true)
	e.writeln('return 0')
}

fn (mut e Emitter) require_stmt(stmt ast.RequireStmt) {
	e.file(stmt.file)
}

fn (mut e Emitter) while_stmt(stmt ast.WhileStmt) {
	e.write('while ')
	e.expr(stmt.cond, mode: .condition, writeln: true)
	e.writeln('do')
	{
		e.block(stmt.body)
	}
	e.writeln('done')
}

fn (mut e Emitter) yield_stmt(stmt ast.YieldStmt) {
	e.expr(stmt.expr, mode: .command, writeln: true)
}
