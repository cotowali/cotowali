// Copyright (c) 2021 zakuro <z@kuro.red>. All rights reserved.
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
module pwsh

import cotowali.ast { Stmt }

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
		ast.DocComment { e.doc_comment(stmt) }
		ast.EmptyStmt { e.writeln('') }
		ast.ForInStmt { e.for_in_stmt(stmt) }
		ast.IfStmt { e.if_stmt(stmt) }
		ast.InlineShell { e.inline_shell(stmt) }
		ast.NamespaceDecl { e.namespace_decl(stmt) }
		ast.ReturnStmt { e.return_stmt(stmt) }
		ast.RequireStmt { e.require_stmt(stmt) }
		ast.WhileStmt { e.while_stmt(stmt) }
		ast.YieldStmt { e.yield_stmt(stmt) }
	}
}

fn (mut e Emitter) assign_stmt(stmt ast.AssignStmt) {
	match stmt.left {
		ast.IndexExpr {
			panic('index assignment is unimplemented')
		}
		ast.ParenExpr {
			panic('destrucuture assignment is unimplemented')
		}
		else {
			e.write('\$${e.ident_for(stmt.left)} = ')
			e.expr(stmt.right)
			e.writeln('')
		}
	}
}

fn (mut e Emitter) assert_stmt(stmt ast.AssertStmt) {
	e.write('if ( -not (')
	e.expr(stmt.args[0])
	e.writeln(') )')

	e.writeln('{')
	{
		e.indent()

		e.write('[Console]::Error.WriteLine(')
		{
			e.write("'LINE $stmt.pos.line: Assertion Failed'")
			if msg_expr := stmt.message_expr() {
				// ...WriteLine(...Assertion Failed' + ' (' + msg_expr + ')')
				//                                  ^^^^^^^^^^        ^^^^^^
				e.write(" + ' (' + ") //            |                 |
				//       ^^^^^^---------------------+                 |
				e.expr(msg_expr) //                                   |
				//                                                    |
				e.write(" + ')'") //                                  |
				//       ^^^^^^---------------------------------------+
			}
		}
		e.writeln(')')

		e.writeln('exit 1')

		e.unindent()
	}
	e.writeln('}')
}

fn (mut e Emitter) block(block ast.Block) {
	panic('unimplemented')
}

fn (mut e Emitter) doc_comment(comment ast.DocComment) {
	for line in comment.lines() {
		e.writeln('#$line')
	}
}

fn (mut e Emitter) expr_stmt(stmt ast.Expr) {
	e.expr(stmt)
}

fn (mut e Emitter) for_in_stmt(stmt ast.ForInStmt) {
	panic('unimplemented')
}

fn (mut e Emitter) if_stmt(stmt ast.IfStmt) {
	panic('unimplemented')
}

fn (mut e Emitter) inline_shell(stmt ast.InlineShell) {
	panic('unimplemented')
}

fn (mut e Emitter) namespace_decl(ns ast.NamespaceDecl) {
	panic('unimplemented')
}

fn (mut e Emitter) return_stmt(stmt ast.ReturnStmt) {
	panic('unimplemented')
}

fn (mut e Emitter) require_stmt(stmt ast.RequireStmt) {
	e.file(stmt.file)
}

fn (mut e Emitter) while_stmt(stmt ast.WhileStmt) {
	panic('unimplemented')
}

fn (mut e Emitter) yield_stmt(stmt ast.YieldStmt) {
	panic('unimplemented')
}
