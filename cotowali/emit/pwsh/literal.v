// Copyright (c) 2021-2023 zakuro <z@kuro.red>. All rights reserved.
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
module pwsh

import cotowali.ast

fn (mut e Emitter) array_literal(expr ast.ArrayLiteral, opt ExprOpt) {
	if expr.is_init_syntax {
		// (@(init) * (len))
		e.write('(@')
		e.expr(expr.init, paren: true)
		e.write(' * ')
		e.expr(expr.len, paren: true)
		e.write(')')
	} else {
		e.write('@(')
		for i, elem in expr.elements {
			if i > 0 {
				e.write(', ')
			}
			e.expr(elem, paren: elem is ast.CallExpr || elem is ast.CallCommandExpr)
		}
		e.write(')')
	}
}

fn (mut e Emitter) bool_literal(expr ast.BoolLiteral, opt ExprOpt) {
	e.write(if expr.token.bool() { r'$true' } else { r'$false' })
}

fn (mut e Emitter) float_literal(expr ast.FloatLiteral, opt ExprOpt) {
	e.write(expr.token.text)
}

fn (mut e Emitter) int_literal(expr ast.IntLiteral, opt ExprOpt) {
	e.write(expr.token.text)
}

fn (mut e Emitter) null_literal(expr ast.NullLiteral, opt ExprOpt) {
	e.write('\$null')
}

fn (mut e Emitter) map_literal(expr ast.MapLiteral, opt ExprOpt) {
	e.writeln('@{')
	e.indent()
	for entry in expr.entries {
		e.expr(entry.key)
		e.write(' = ')
		e.expr(entry.value)
		e.writeln(';')
	}
	e.unindent()
	e.write('}')
}
