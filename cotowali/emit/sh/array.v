// Copyright (c) 2021 zakuro <z@kuro.red>. All rights reserved.
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
module sh

import cotowali.ast

fn (mut e Emitter) array_literal(expr ast.ArrayLiteral, opt ExprOpt) {
	ident := e.ident_for(expr)
	e.insert_at(e.stmt_head_pos(), fn (mut e Emitter, v ExprWithValue<ast.ArrayLiteral, string>) {
		ident := v.value
		e.assign(ident, ast.Expr(v.expr), ast.Expr(v.expr).type_symbol())
	}, expr_with_value(expr, ident))

	e.array(ident, opt)
}

fn (mut e Emitter) array(name string, opt ExprOpt) {
	if opt.as_command {
		e.writeln('echo \$(eval echo \$(array_elements $name) )')
		return
	}
	if opt.expand_array {
		e.write('\$(eval echo \$(array_elements $name) )')
	} else {
		e.write(name)
	}
}
