// Copyright (c) 2021 zakuro <z@kuro.red>. All rights reserved.
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
module checker

import cotowali.ast { Expr }
import cotowali.symbols { Type, TypeSymbol, builtin_type }
import cotowali.source { Pos }
import cotowali.util { li_panic }

enum TypeMismatchMessageFormat {
	want_got
	got_want
}

struct TypeCheckingConfig {
	want           TypeSymbol                [required]
	want_label     string = 'expected'
	got            TypeSymbol                [required]
	got_label      string = 'found'
	pos            Pos                       [required]
	synmetric      bool
	message_format TypeMismatchMessageFormat = .want_got
}

fn can_promote(want TypeSymbol, got TypeSymbol) bool {
	if _unlikely_(want.typ == got.typ) {
		return true
	}

	if want.kind() == .alias || got.kind() == .alias {
		return can_promote(want.resolved(), got.resolved())
	}

	if want.typ == builtin_type(.any) {
		return true
	}

	if want.kind() == .tuple && got.kind() == .tuple {
		return can_promote_tuple(want, got)
	}

	if want.typ.is_number() && got.typ.is_number() {
		return can_promote_number(want.typ, got.typ)
	}

	if want_tuple_info := want.tuple_info() {
		elements := want_tuple_info.elements
		if elements.len == 1 && elements[0].typ == got.typ {
			return true
		}
	}

	scope_of_want := want.scope() or { li_panic(@FILE, @LINE, err) }

	if want_sequence_info := want.sequence_info() {
		if want_elem := scope_of_want.lookup_type(want_sequence_info.elem) {
			if can_promote(want_elem, got) {
				return true
			}
		}
	}

	return false
}

fn can_promote_tuple(want TypeSymbol, got TypeSymbol) bool {
	want_tuple := want.tuple_info() or { li_panic(@FILE, @LINE, 'not a tuple') }
	got_tuple := got.tuple_info() or { li_panic(@FILE, @LINE, 'not a tuple') }
	if want_tuple.elements.len != got_tuple.elements.len {
		return false
	}
	for i, want_elem in want_tuple.elements {
		want_elem_ts := (want.scope() or { return false }).lookup_type(want_elem.typ) or {
			return false
		}
		got_elem_ts := (got.scope() or { return false }).lookup_type(got_tuple.elements[i].typ) or {
			return false
		}
		if !can_promote(want_elem_ts, got_elem_ts) {
			return false
		}
	}

	return true
}

fn can_promote_number(want Type, got Type) bool {
	if _unlikely_(want == got) {
		return true
	}

	if want == builtin_type(.float) && got == builtin_type(.int) {
		return true
	}
	return false
}

fn (mut c Checker) check_types(v TypeCheckingConfig) ? {
	$if trace_checker ? {
		args := [
			'$v.want_label: $v.want.name',
			'$v.got_label: $v.got.name',
			'synmetric: $v.synmetric',
		]
		c.trace_begin(@FN, ...args)
		defer {
			c.trace_end()
		}
	}

	if v.want.typ == v.got.typ {
		return
	}
	if v.synmetric {
		// don't promte to any ( `int + any` should be invalid )
		if v.want.typ != builtin_type(.any) && v.got.typ != builtin_type(.any) {
			if can_promote(v.want, v.got) || can_promote(v.got, v.want) {
				return
			}
		}
	} else {
		if can_promote(v.want, v.got) {
			return
		}
	}

	m_want, m_got := '`$v.want.name` ($v.want_label)', '`$v.got.name` ($v.got_label)'
	m1, m2 := match v.message_format {
		.want_got { m_want, m_got }
		.got_want { m_got, m_want }
	}
	return c.error('mismatched types: $m1 and $m2', v.pos)
}

fn (mut c Checker) expect_bool_expr(expr Expr, context_name string) ? {
	$if trace_checker ? {
		c.trace_begin(@FN, context_name)
		defer {
			c.trace_end()
		}
	}

	if expr.typ() != builtin_type(.bool) {
		return c.error('non-bool type used as $context_name', expr.pos())
	}
}

fn (mut c Checker) expect_function_call(expr Expr) ?ast.CallExpr {
	$if trace_checker ? {
		c.trace_begin(@FN)
		defer {
			c.trace_end()
		}
	}

	if expr is ast.CallExpr {
		return expr
	}
	ts := expr.type_symbol()
	return c.error('expected function call, but found $ts.name', expr.pos())
}
