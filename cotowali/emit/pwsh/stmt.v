// Copyright (c) 2021 zakuro <z@kuro.red>. All rights reserved.
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
module pwsh

import cotowali.ast { Stmt }
import cotowali.symbols { builtin_type }
import cotowali.token { Token }
import cotowali.util { li_panic }

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

fn (mut e Emitter) assign_stmt(stmt ast.AssignStmt) {
	match stmt.left {
		ast.IndexExpr {
			e.index_expr(stmt.left)
			e.write(' = ')
			e.expr(stmt.right)
		}
		ast.ParenExpr {
			// pwsh supports assiginig multiple variables : ($a, $b) = (0, 1)
			e.paren_expr(stmt.left)
			e.write(' = ')
			e.expr(stmt.right)
		}
		else {
			e.write('${e.pwsh_var(stmt.left)} = ')
			e.expr(stmt.right)
		}
	}
	e.writeln('')
}

fn (mut e Emitter) assert_stmt(stmt ast.AssertStmt) {
	e.write('if ( -not (')
	e.expr(stmt.args[0])
	e.writeln(') )')

	e.writeln('{')
	{
		e.indent()

		is_test := if f := e.current_fn() { f.is_test() } else { false }
		e.write(if is_test { 'echo (' } else { '[Console]::Error.WriteLine(' })
		{
			e.write("'LINE $stmt.pos.line: Assertion Failed'")
			if msg_expr := stmt.message_expr() {
				e.write(" + ': ' + ")
				e.expr(msg_expr)
			}
		}
		e.writeln(')')

		if is_test {
			// use in test runner. see std/testing.li
			e.writeln(r'$script:assert_failed = $true')
			e.writeln('return')
		} else {
			e.writeln('exit 1')
		}

		e.unindent()
	}
	e.writeln('}')
}

fn (mut e Emitter) block(block ast.Block) {
	for stmt in block.stmts {
		e.stmt(stmt)
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
		e.writeln('#$line')
	}
}

fn (mut e Emitter) expr_stmt(stmt ast.Expr) {
	e.expr(stmt)
	redirect_to_null := (if current_fn := e.current_fn() {
		match stmt {
			ast.CallExpr { current_fn.function_info().ret != builtin_type(.void) }
			ast.Pipeline { !stmt.has_redirect() }
			else { true }
		}
	} else {
		false
	}) && stmt.typ() != builtin_type(.void)

	e.writeln(if redirect_to_null { r'> $null' } else { '' })
}

fn (mut e Emitter) for_in_stmt(stmt ast.ForInStmt) {
	e.write('foreach(${e.pwsh_var(stmt.var_)} in ')
	e.expr(stmt.expr)
	e.writeln(')')

	e.writeln('{')
	e.indent()
	e.block(stmt.body)
	e.unindent()
	e.writeln('}')
}

fn (mut e Emitter) if_stmt(stmt ast.IfStmt) {
	for i, branch in stmt.branches {
		if i == stmt.branches.len - 1 && stmt.has_else {
			e.write('else')
		} else {
			e.write(if i == 0 { 'if' } else { 'elseif' })
			e.write(' (')
			e.expr(branch.cond)
			e.write(')')
		}
		e.writeln('')

		e.writeln('{')
		e.indent()
		e.block(branch.body)
		e.unindent()
		e.writeln('}')
	}
}

fn (mut e Emitter) inline_shell(stmt ast.InlineShell) {
	if !stmt.use_for_pwsh() {
		return
	}
	for i, part in stmt.parts {
		match part {
			Token {
				if part.kind != .inline_shell_content_text {
					li_panic(@FILE, @LINE, 'want inline_shell_content_text. got $part.kind')
				}

				mut text := part.text
				// treat $%n as %n (%n will be $n in pwsh)
				if text.len > 0 && text[text.len - 1] == `$` && i + 1 < stmt.parts.len {
					if stmt.parts[i + 1] is ast.Var {
						text = text[..text.len - 1]
					}
				}
				e.write(text)
			}
			ast.Var {
				// TODO: explicit `as` cast is workaround for avoid V's bug
				e.write(e.pwsh_var(part as ast.Var))
			}
		}
	}
	e.writeln('')
}

fn (mut e Emitter) module_decl(ns ast.ModuleDecl) {
	e.block(ns.block)
}

fn (mut e Emitter) return_stmt(stmt ast.ReturnStmt) {
	e.write('return ')
	e.expr(stmt.expr)
	e.writeln('')
}

fn (mut e Emitter) require_stmt(stmt ast.RequireStmt) {
	e.file(stmt.file)
}

fn (mut e Emitter) while_stmt(stmt ast.WhileStmt) {
	e.write('while (')
	e.expr(stmt.cond)
	e.writeln(')')

	e.writeln('{')
	e.indent()
	{
		e.block(stmt.body)
	}
	e.unindent()
	e.writeln('}')
}

fn (mut e Emitter) yield_stmt(stmt ast.YieldStmt) {
	e.expr(stmt.expr)
	e.writeln('')
}
