// Copyright (c) 2021-2023 zakuro <z@kuro.red>
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
module sh

import cotowali.ast { MapLiteral }

fn (mut e Emitter) map_literal(expr MapLiteral, opt ExprOpt) {
	ident := e.ident_for(expr)
	e.insert_at(e.stmt_head_pos(), fn (mut e Emitter, v ExprWithValue[MapLiteral, string]) {
		ident := v.value
		for entry in v.expr.entries {
			e.write('map_set ${ident} ')
			e.expr(entry.key)
			e.write(' ')
			e.expr(entry.value)
			e.writeln('')
		}
	}, expr_with_value(expr, ident))

	e.map(ident, opt)
}

fn (mut e Emitter) map(name string, opt ExprOpt) {
	if opt.mode == .command {
		panic('unimplemented')
		return
	}
	e.write(name)
}
