// Copyright (c) 2021 zakuro <z@kuro.red>. All rights reserved.
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
module pwsh

import cotowali.ast { CallCommandExpr, CallExpr, FnDecl }

fn (mut e Emitter) call_command_expr(expr CallCommandExpr, opt ExprOpt) {
	panic('unimplemented')
}

fn (mut e Emitter) call_expr(expr CallExpr, opt ExprOpt) {
}

fn (mut e Emitter) fn_decl(node FnDecl) {
	if !node.has_body {
		return
	}

	if node.is_test() {
		if !e.ctx.config.is_test {
			return
		}
		defer {
			panic('unimplemented')
			// e.stmt(ast.Expr(node.get_run_test_call_expr()))
		}
	}

	fn_info := node.function_info()

	e.write('function ${e.ident_for(node)}(')
	{
		for i, param in node.params {
			if i == node.params.len - 1 && fn_info.variadic {
				panic('variadic function is unimplemented')
			}
			if i > 0 {
				e.write(', ')
			}
			e.write('\$${e.ident_for(param)}')
		}
	}
	e.writeln(')')
	e.writeln('{')
	{
		e.block(node.body)
	}
	e.writeln('}')
}
