// Copyright (c) 2021-2023 zakuro <z@kuro.red>. All rights reserved.
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
module sh

import cotowali.ast
import cotowali.util { li_panic }

fn (mut e Emitter) array_literal(expr ast.ArrayLiteral, opt ExprOpt) {
	ident := e.ident_for(expr)
	e.insert_at(e.stmt_head_pos(), fn (mut e Emitter, v ExprWithValue[ast.ArrayLiteral, string]) {
		ident := v.value
		e.assign(ident, ast.Expr(v.expr), ast.Expr(v.expr).type_symbol())
	}, expr_with_value(expr, ident))

	e.array(ident, opt)
}

fn (mut e Emitter) array_to_str(value ExprOrString) {
	match value {
		string {
			e.write('"\$(array_to_str ${value})"')
		}
		ast.Expr {
			e.write('"\$(array_to_str ')
			e.expr(value)
			e.write(')"')
		}
	}
}

fn (mut e Emitter) array(name string, opt ExprOpt) {
	if opt.mode == .command {
		e.write('echo ')
		e.array_to_str(name)
		return
	}
	if opt.expand_array {
		e.array_elements(name)
	} else {
		e.write(name)
	}
}

fn (mut e Emitter) array_elements(name string) {
	e.write('\$(array_elements ${name})')
}

fn (mut e Emitter) infix_expr_for_array(expr ast.InfixExpr, opt ExprOpt) {
	if expr.left.type_symbol().resolved().kind() != .array {
		li_panic(@FN, @FILE, @LINE, 'not a array operand')
	}

	match expr.op.kind {
		.eq, .ne {
			e.sh_test_command_for_expr(fn (mut e Emitter, expr ast.InfixExpr) {
				e.array_to_str(expr.left)
				e.write(if expr.op.kind == .eq { ' = ' } else { ' != ' })
				e.array_to_str(expr.right)
			}, expr, opt)
		}
		.plus {
			ident := e.new_tmp_ident()
			e.insert_at(e.stmt_head_pos(), fn (mut e Emitter, v ExprWithValue[ast.InfixExpr, string]) {
				expr, ident := v.expr, v.value
				e.write('array_copy ${ident} ')
				e.expr(expr.left, writeln: true)
				e.write('array_push_array ${ident} ')
				e.expr(expr.right, writeln: true)
			}, expr_with_value(expr, ident))
			e.array(ident, opt)
		}
		else {
			li_panic(@FN, @FILE, @LINE, 'invalid operator')
		}
	}
}
