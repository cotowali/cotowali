// Copyright (c) 2021 zakuro <z@kuro.red>. All rights reserved.
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
module pwsh

import cotowali.ast { Expr }

fn (mut e Emitter) pwsh_compare_object(left Expr, right Expr) {
	e.write('Compare-Object (')
	e.expr(left)
	e.write(') (')
	e.expr(right)
	e.write(')')
}

fn (mut e Emitter) pwsh_array_eq(left Expr, right Expr) {
	e.write('(-not (')
	e.pwsh_compare_object(left, right)
	e.write('))')
}

fn (mut e Emitter) pwsh_array_ne(left Expr, right Expr) {
	e.write('[bool](')
	e.pwsh_compare_object(left, right)
	e.write(')')
}

fn (mut e Emitter) pwsh_array_concat(left Expr, right Expr) {
	e.expr(left)
	e.write(' + ')
	e.expr(right)
}

fn (mut e Emitter) pwsh_var(v ValueOfIdentFor) string {
	return '\$${e.ident_for(v)}'
}
