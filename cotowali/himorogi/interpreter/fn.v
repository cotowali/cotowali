// Copyright (c) 2021-2023 zakuro <z@kuro.red>
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
module interpreter

import cotowali.ast { CallCommandExpr, CallExpr, FnDecl }

fn (mut e Interpreter) call_command_expr(expr CallCommandExpr) Value {
	todo(@FN, @FILE, @LINE)
	/*
	e.write('$expr.command')
	for arg in expr.args {
		e.write(' ')
		if arg is ast.StringLiteral {
			if arg.is_glob() {
				e.string_literal_value(arg)
				continue
			}
		}
		e.expr(arg, paren: true)
	}
	*/
}

fn (mut e Interpreter) call_expr(expr CallExpr) Value {
	todo(@FN, @FILE, @LINE)
	/*
	if expr.is_builtin_function_call(.read) {
		e.write('read \$input')
	} else {
		e.write('${e.ident_for(expr.func)}')
	}

	if receiver := expr.receiver() {
		e.write(' ')
		e.expr(receiver, paren: true)
	}

	for arg in expr.args {
		e.write(' ')
		e.expr(arg, paren: true)
	}
	*/
}

fn (mut e Interpreter) fn_decl(node FnDecl) {
	if !node.has_body {
		return
	}

	old_fn := e.current_fn
	e.current_fn = &node
	defer {
		e.current_fn = old_fn
	}

	if node.is_test() {
		if !e.ctx.config.is_test {
			return
		}
		todo(@FN, @FILE, @LINE)
	}

	todo(@FN, @FILE, @LINE)

	/*
	fn_info := node.function_info()

	e.write('function ${e.ident_for(node)}(')
	{
		for i, param in node.params {
			if i == node.params.len - 1 && fn_info.variadic {
				break
			}
			if i > 0 {
				e.write(', ')
			}
			e.write(e.pwsh_var(param))
			if default := param.default() {
				e.write(' = ')
				e.expr(default)
			}
		}
	}
	e.writeln(')')

	e.writeln('{')
	e.indent()
	{
		if fn_info.variadic {
			e.writeln('${e.pwsh_var(node.params.last())} = \$args')
		}

		if param := node.pipe_in_param() {
			val := if ast.Expr(param).type_symbol().resolved().kind() in [.tuple, .array] {
				r'@($input)'
			} else {
				r'@($input)[0]'
			}
			e.writeln('${e.pwsh_var(param)} = $val')
		}

		e.block(node.body)
	}
	e.unindent()
	e.writeln('}')
	*/
}

fn (mut e Interpreter) return_stmt(stmt ast.ReturnStmt) {
	todo(@FN, @FILE, @LINE)
}

fn (mut e Interpreter) yield_stmt(stmt ast.YieldStmt) {
	todo(@FN, @FILE, @LINE)
}
