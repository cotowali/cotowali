module sh

import cotowari.ast { Stmt }
import cotowari.symbols { builtin_type }

fn (mut e Emitter) stmts(stmts []Stmt) {
	for stmt in stmts {
		e.stmt(stmt)
	}
}

fn (mut e Emitter) stmt(stmt Stmt) {
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
	}
}

fn (mut e Emitter) expr_stmt(stmt ast.Expr) {
	discard_stdout := e.inside_fn
		&& if stmt is ast.CallFn { e.cur_fn.type_symbol().fn_info().ret != builtin_type(.void) } else { true }
	e.expr(stmt, as_command: true, discard_stdout: discard_stdout, writeln: true)
}

fn (mut e Emitter) assert_stmt(stmt ast.AssertStmt) {
	e.write('if falsy ')
	e.expr(stmt.expr, as_command: false, writeln: true)

	e.write_block({ open: 'then', close: 'fi' }, fn (mut e Emitter, stmt ast.AssertStmt) {
		e.writeln("echo 'LINE $stmt.key_pos.line: assertion failed' >&2")
		e.writeln('exit 1')
	}, stmt)
}

fn (mut e Emitter) block(block ast.Block) {
	e.stmts(block.stmts)
}

fn (mut e Emitter) if_stmt(stmt ast.IfStmt) {
	for i, branch in stmt.branches {
		mut is_else := i == stmt.branches.len - 1 && stmt.has_else
		if is_else {
			e.writeln('else')
		} else {
			e.write(if i == 0 { 'if ' } else { 'elif ' })
			e.write('truthy ')
			e.expr(branch.cond, as_command: false, writeln: true)
			e.writeln('then')
		}
		e.indent()
		e.block(branch.body)
		e.unindent()
	}
	e.writeln('fi')
}

fn (mut e Emitter) for_in_stmt(stmt ast.ForInStmt) {
	e.write('for ${e.ident_for(stmt.val)} in ')
	e.expr(stmt.expr, expand_array: true, writeln: true)
	e.write_block({ open: 'do', close: 'done' }, fn (mut e Emitter, stmt ast.ForInStmt) {
		e.block(stmt.body)
	}, stmt)
}

fn (mut e Emitter) return_stmt(stmt ast.ReturnStmt) {
	e.expr(stmt.expr, as_command: true, writeln: true)
	e.writeln('return 0')
}

fn (mut e Emitter) require_stmt(stmt ast.RequireStmt) {
	e.file(stmt.file)
}
