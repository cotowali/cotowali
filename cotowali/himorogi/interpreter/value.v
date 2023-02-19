// Copyright (c) 2021-2023 zakuro <z@kuro.red>
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
module interpreter

import math
import cotowali.ast
import cotowali.util { li_panic }

struct Null {}

type Value = Null | []Value | bool | f64 | i64 | string

fn (v Value) bool() bool {
	if v is bool {
		return v
	}
	li_panic(@FN, @FILE, @LINE, '${v} is not a bool')
}

fn (v Value) @as[T]() {
	if v is T {
		return v
	}
	li_panic(@FN, @FILE, @LINE, '${v} is not a ${typeof(T).name}')
}

fn (lhs_orig Value) add(rhs_orig Value) Value {
	lhs, rhs := promote(lhs_orig, rhs_orig)

	if lhs is []Value && rhs is []Value {
		mut res := []Value{cap: lhs.len + rhs.len}
		res << lhs
		res << rhs
		return res
	}

	return if lhs is f64 && rhs is f64 {
		Value(lhs + rhs)
	} else if lhs is i64 && rhs is i64 {
		Value(lhs + rhs)
	} else if lhs is string && rhs is string {
		Value(lhs + rhs)
	} else {
		li_panic(@FN, @FILE, @LINE, '${lhs} + ${rhs}')
	}
}

fn (lhs_orig Value) sub(rhs_orig Value) Value {
	lhs, rhs := promote(lhs_orig, rhs_orig)
	return if lhs is f64 && rhs is f64 {
		Value(lhs - rhs)
	} else if lhs is i64 && rhs is i64 {
		Value(lhs - rhs)
	} else {
		li_panic(@FN, @FILE, @LINE, '${lhs} + ${rhs}')
	}
}

fn (lhs_orig Value) mul(rhs_orig Value) Value {
	lhs, rhs := promote(lhs_orig, rhs_orig)
	return if lhs is f64 && rhs is f64 {
		Value(lhs * rhs)
	} else if lhs is i64 && rhs is i64 {
		Value(lhs * rhs)
	} else {
		li_panic(@FN, @FILE, @LINE, 'invalid operation: ${lhs} + ${rhs}')
	}
}

fn (lhs_orig Value) div(rhs_orig Value) Value {
	lhs, rhs := promote(lhs_orig, rhs_orig)
	return if lhs is f64 && rhs is f64 {
		Value(lhs / rhs)
	} else if lhs is i64 && rhs is i64 {
		Value(lhs / rhs)
	} else {
		li_panic(@FN, @FILE, @LINE, 'invalid operation: ${lhs} / ${rhs}')
	}
}

fn (lhs_orig Value) mod(rhs_orig Value) Value {
	lhs, rhs := promote(lhs_orig, rhs_orig)
	return if lhs is f64 && rhs is f64 {
		Value(math.fmod(lhs, rhs))
	} else if lhs is i64 && rhs is i64 {
		Value(lhs % rhs)
	} else {
		li_panic(@FN, @FILE, @LINE, 'invalid operation: ${lhs} % ${rhs}')
	}
}

fn (lhs_orig Value) pow(rhs_orig Value) Value {
	lhs, rhs := promote(lhs_orig, rhs_orig)
	return if lhs is f64 && rhs is f64 {
		Value(math.pow(lhs, rhs))
	} else if lhs is i64 && rhs is i64 {
		Value(math.powi(lhs, rhs))
	} else {
		li_panic(@FN, @FILE, @LINE, 'invalid operation: ${lhs} ** ${rhs}')
	}
}

fn (lhs_orig Value) eq(rhs_orig Value) bool {
	lhs, rhs := promote(lhs_orig, rhs_orig)
	return lhs == rhs
}

fn (lhs_orig Value) ne(rhs_orig Value) bool {
	return !lhs_orig.eq(rhs_orig)
}

fn (lhs_orig Value) lt(rhs_orig Value) bool {
	lhs, rhs := promote(lhs_orig, rhs_orig)
	return if lhs is f64 && rhs is f64 {
		lhs < rhs
	} else if lhs is i64 && rhs is i64 {
		lhs < rhs
	} else {
		li_panic(@FN, @FILE, @LINE, 'invalid operation: ${lhs} / ${rhs}')
	}
}

fn (lhs Value) le(rhs Value) bool {
	return lhs.lt(rhs) || lhs.eq(rhs)
}

fn (lhs_orig Value) gt(rhs_orig Value) bool {
	lhs, rhs := promote(lhs_orig, rhs_orig)
	return if lhs is f64 && rhs is f64 {
		lhs > rhs
	} else if lhs is i64 && rhs is i64 {
		lhs > rhs
	} else {
		li_panic(@FN, @FILE, @LINE, 'invalid operation: ${lhs} / ${rhs}')
	}
}

fn (lhs Value) ge(rhs Value) bool {
	return lhs.gt(rhs) || lhs.eq(rhs)
}

fn (v Value) str() string {
	return match v {
		Null { '' }
		string { v }
		[]Value, bool, f64, i64 { v.str() }
	}
}

fn promote(lhs Value, rhs Value) (Value, Value) {
	return if lhs is i64 && rhs is f64 {
		Value(f64(lhs)), Value(rhs)
	} else if lhs is f64 && rhs is i64 {
		Value(lhs), Value(f64(rhs))
	} else {
		lhs, rhs
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
