// Copyright (c) 2021-2023 zakuro <z@kuro.red>. All rights reserved.
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
module sh

import cotowali.ast { Stmt }
import cotowali.symbols { TypeSymbol, builtin_type }
import cotowali.token { Token }
import cotowali.util { li_panic }

fn (mut e Emitter) stmts(stmts []Stmt) {
	for stmt in stmts {
		e.stmt(stmt)
	}
}

fn (mut e Emitter) begin_stmt() {
	e.stmt_head_pos[e.cur_kind] << e.code().pos()
}

fn (mut e Emitter) end_stmt() {
	e.stmt_head_pos[e.cur_kind].pop()
}

fn (mut e Emitter) stmt(stmt Stmt) {
	e.begin_stmt()
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
	e.end_stmt()
}

fn (mut e Emitter) expr_stmt(stmt ast.Expr) {
	discard_stdout := if cur_fn := e.cur_fn() {
		match stmt {
			ast.CallExpr { cur_fn.function_info().ret != builtin_type(.void) }
			ast.Pipeline { !stmt.has_redirect() }
			else { true }
		}
	} else {
		false
	}
	e.expr(stmt, mode: .command, discard_stdout: discard_stdout, writeln: true)
}

fn (mut e Emitter) assert_stmt(stmt ast.AssertStmt) {
	e.write('if ')
	e.expr(stmt.cond(),
		mode: .condition
		writeln: true
	)

	e.writeln('then')
	e.indent()
	{
		e.writeln(':')
	}
	e.unindent()

	e.writeln('else')

	e.indent()
	{
		mut msg := "'LINE ${stmt.pos.line}: Assertion Failed'"
		if msg_expr := stmt.message_expr() {
			tmp := e.new_tmp_ident()
			e.assign(tmp, msg_expr, msg_expr.type_symbol())
			msg += '": \$${tmp}"'
		}
		e.writeln('echo ${msg} >&2')
		is_test := if f := e.cur_fn() { f.is_test() } else { false }
		e.writeln(if is_test { 'return 1' } else { 'exit 1' })
	}
	e.unindent()
	e.writeln('fi')
}

[params]
struct BlockOpt {
	allow_blank bool
}

fn (mut e Emitter) block(block ast.Block, opt BlockOpt) {
	mut blank := true

	for stmt in block.stmts {
		e.stmt(stmt)
		match stmt {
			ast.Empty, ast.DocComment {}
			else { blank = false }
		}
	}

	if blank && !opt.allow_blank {
		e.writeln(':')
	}
}

fn (mut e Emitter) break_(stmt ast.Break) {
	e.writeln('break')
}

fn (mut e Emitter) continue_(stmt ast.Continue) {
	e.writeln('continue')
}

fn (mut e Emitter) doc_comment(comment ast.DocComment) {
	for line in comment.lines() {
		e.writeln('#${line}')
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
	e.write('for ${tmp} in ')
	e.expr(stmt.expr, expand_array: true, writeln: true, quote: false)
	e.writeln('do')
	e.indent()
	{
		e.assign(e.ident_for(stmt.var_), '\$(eval echo \$${tmp})', TypeSymbol{})
		e.block(stmt.body)
	}
	e.unindent()
	e.writeln('done')
}

fn (mut e Emitter) inline_shell(stmt ast.InlineShell) {
	if !stmt.use_for_sh() {
		return
	}
	for part in stmt.parts {
		match part {
			Token {
				$if !prod {
					if part.kind != .inline_shell_content_text {
						li_panic(@FN, @FILE, @LINE, 'want inline_shell_content_text. got ${part.kind}')
					}
				}
				e.write(part.text)
			}
			ast.Var {
				// TODO: explicit `as` cast is workaround for avoid V's bug
				e.write(e.ident_for(part as ast.Var))
			}
		}
	}
	e.writeln('')
}

fn (mut e Emitter) module_decl(mod ast.ModuleDecl) {
	e.block(mod.block, allow_blank: true)
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
	e.indent()
	{
		e.block(stmt.body)
	}
	e.unindent()
	e.writeln('done')
}

fn (mut e Emitter) yield_stmt(stmt ast.YieldStmt) {
	e.expr(stmt.expr, mode: .command, writeln: true)
}
