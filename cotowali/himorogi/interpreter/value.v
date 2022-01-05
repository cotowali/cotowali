// Copyright (c) 2021 zakuro <z@kuro.red>. All rights reserved.
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
module interpreter

import cotowali.ast
import cotowali.util { li_panic }

struct Null {}

type Value = Null | []Value | bool | f64 | i64 | string

fn (v Value) str() string {
	return match v {
		Null { '' }
		string { v }
		[]Value, bool, f64, i64 { v.str() }
	}
}

[noreturn]
fn todo(func string, file string, line string) {
	li_panic(func, file, line, 'unimplemented')
}

fn (mut e Interpreter) array_literal(expr ast.ArrayLiteral) Value {
	todo(@FN, @FILE, @LINE)
}

fn (mut e Interpreter) bool_literal(expr ast.BoolLiteral) Value {
	return expr.token.bool()
}

fn (mut e Interpreter) float_literal(expr ast.FloatLiteral) Value {
	return expr.token.text.f64()
}

fn (mut e Interpreter) int_literal(expr ast.IntLiteral) Value {
	return expr.token.text.i64()
}

fn (mut e Interpreter) null_literal(expr ast.NullLiteral) Value {
	return Null{}
}

fn (mut e Interpreter) map_literal(expr ast.MapLiteral) Value {
	todo(@FN, @FILE, @LINE)
}
