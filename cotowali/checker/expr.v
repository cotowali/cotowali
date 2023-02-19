// Copyright (c) 2021-2023 zakuro <z@kuro.red>
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
module checker

import cotowali.ast { Expr }
import cotowali.symbols { TypeSymbol, builtin_type }
import cotowali.source { Pos }

fn (mut c Checker) exprs(exprs []Expr) {
	for expr in exprs {
		c.expr(expr)
	}
}

fn (mut c Checker) expr(expr Expr) {
	$if trace_checker ? {
		c.trace_begin(@FN)
		defer {
			c.trace_end()
		}
	}

	match expr {
		ast.ArrayLiteral { c.array_literal(expr) }
		ast.AsExpr { c.as_expr(expr) }
		ast.BoolLiteral {}
		ast.CallCommandExpr { c.call_command_expr(expr) }
		ast.CallExpr { c.call_expr(expr) }
		ast.DecomposeExpr { c.decompose_expr(expr) }
		ast.DefaultValue {}
		ast.Empty {}
		ast.FloatLiteral {}
		ast.IndexExpr { c.index_expr(expr) }
		ast.InfixExpr { c.infix_expr(expr) }
		ast.IntLiteral {}
		ast.MapLiteral { c.map_literal(expr) }
		ast.ModuleItem { c.module_item(expr) }
		ast.Nameof { c.nameof(expr) }
		ast.NullLiteral {}
		ast.ParenExpr { c.paren_expr(expr) }
		ast.Pipeline { c.pipeline(expr) }
		ast.PrefixExpr { c.prefix_expr(expr) }
		ast.SelectorExpr { c.selector_expr(expr) }
		ast.StringLiteral { c.string_literal(expr) }
		ast.Typeof { c.typeof_(expr) }
		ast.Var { c.var_(expr) }
	}
}

fn (mut c Checker) array_literal(expr ast.ArrayLiteral) {
	if expr.is_init_syntax {
		c.expr(expr.len)
		c.check_types(
			want: expr.scope.must_lookup_type(builtin_type(.int))
			got: expr.len.type_symbol()
			pos: expr.len.pos()
		) or {}
		c.expr(expr.init)
		c.check_types(
			want: expr.scope.must_lookup_type(expr.elem_typ)
			got: expr.init.type_symbol()
			pos: expr.init.pos()
		) or {}
	} else {
		c.exprs(expr.elements)
	}
}

fn (mut c Checker) as_expr(expr ast.AsExpr) {
	$if trace_checker ? {
		c.trace_begin(@FN)
		defer {
			c.trace_end()
		}
	}

	c.expr(expr.expr)
}

fn (mut c Checker) decompose_expr(expr ast.DecomposeExpr) {
	$if trace_checker ? {
		c.trace_begin(@FN)
		defer {
			c.trace_end()
		}
	}

	c.expr(expr.expr)
	ts := expr.expr.type_symbol()
	if _ := ts.tuple_info() {
	} else {
		c.error('cannot decompose non-tuple type `${ts.name}`', expr.pos)
	}
}

fn (mut c Checker) index_expr(expr ast.IndexExpr) {
	$if trace_checker ? {
		c.trace_begin(@FN)
		defer {
			c.trace_end()
		}
	}

	if builtin_type(.placeholder) in [expr.left.typ(), expr.index.typ()] {
		// skip check if unresolved. error is repoted another place
		return
	}

	c.expr(expr.left)

	left_ts := expr.left.type_symbol()
	left_ts_resolved := left_ts.resolved()
	index_pos := expr.index.pos()

	if tuple_info := left_ts_resolved.tuple_info() {
		i, is_literal := match expr.index {
			ast.IntLiteral { expr.index.int(), true }
			ast.PrefixExpr { expr.index.int(), expr.index.is_literal() }
			else { int(0), false }
		}
		if is_literal {
			n := tuple_info.elements.len
			if !(0 <= i && i < n) {
				c.error('index ${i} out of bounds for `${left_ts.name}` (${n} elements tuple)',
					index_pos)
			}
		} else {
			c.error('index of tuple must be int literal.', index_pos)
		}
		return
	}

	want_typ := if left_ts_resolved.kind() in [.array, .tuple]
		|| left_ts_resolved.typ == builtin_type(.string) {
		builtin_type(.int)
	} else if info := left_ts.map_info() {
		info.key
	} else {
		builtin_type(.placeholder)
	}
	if want_typ == builtin_type(.placeholder) {
		c.error('`${left_ts.name}` does not support indexing', expr.pos)
		return
	}

	c.check_types(
		want: Expr(expr).scope().must_lookup_type(want_typ)
		got: expr.index.type_symbol()
		pos: expr.index.pos()
	) or {}
}

fn (mut c Checker) infix_expr_invalid_operation(op string, left TypeSymbol, right TypeSymbol, pos Pos) IError {
	return c.error('invalid operation: `${left.name}` ${op} `${right.name}`', pos)
}

fn (mut c Checker) infix_expr(expr ast.InfixExpr) {
	$if trace_checker ? {
		c.trace_begin(@FN)
		defer {
			c.trace_end()
		}
	}

	c.expr(expr.left)
	c.expr(expr.right)

	if _ := expr.overloaded_function() {
		return
	}

	pos := expr.pos()
	op := expr.op
	left_ts := expr.left.type_symbol()
	left_kind := left_ts.kind()
	right_ts := expr.right.type_symbol()
	right_kind := right_ts.kind()

	if op.kind == .pow {
		if !(left_ts.typ.is_number() && right_ts.typ.is_number()) {
			c.infix_expr_invalid_operation(op.text, left_ts, right_ts, pos)
		}
		return
	}

	if left_kind == .tuple && right_kind == .tuple {
		match op.kind {
			.eq, .ne {
				// don't return. continue to normal type check
			}
			.plus {
				// any of `tuple` + `tuple` is valid. end type checking.
				return
			}
			else {
				c.infix_expr_invalid_operation(op.text, left_ts, right_ts, pos)
				return
			}
		}
	}

	c.check_types(
		want: left_ts
		want_label: 'left'
		got: right_ts
		got_label: 'right'
		pos: pos
		synmetric: true
	) or { return }
}

fn (mut c Checker) map_literal(expr ast.MapLiteral) {
	$if trace_checker ? {
		c.trace_begin(@FN)
		defer {
			c.trace_end()
		}
	}

	// TODO
}

fn (mut c Checker) module_item(expr ast.ModuleItem) {
	$if trace_checker ? {
		c.trace_begin(@FN)
		defer {
			c.trace_end()
		}
	}

	if !expr.is_resolved() {
		return
	}

	c.expr(expr.item)
}

fn (mut c Checker) paren_expr(expr ast.ParenExpr) {
	$if trace_checker ? {
		c.trace_begin(@FN)
		defer {
			c.trace_end()
		}
	}

	c.exprs(expr.exprs)
}

fn (mut c Checker) pipeline(expr ast.Pipeline) {
	$if trace_checker ? {
		c.trace_begin(@FN)
		defer {
			c.trace_end()
		}
	}

	c.exprs(expr.exprs)

	for i, e in expr.exprs {
		is_last := i == expr.exprs.len - 1
		if is_last && expr.has_redirect() {
			// f() |> g() |> 'out_file'
			break
		}

		if i > 0 {
			if e is ast.CallCommandExpr {
				// allow `any_value |> @command()`
				continue
			}

			right := c.expect_function_call(e) or { continue }
			left := expr.exprs[i - 1]

			mut left_ts := left.type_symbol()
			if left_sequence_info := left_ts.sequence_info() {
				left_ts = left.scope().must_lookup_type(left_sequence_info.elem)
			}

			fn_info := right.func.type_symbol().function_info() or {
				// function is not resolved. error was repoted in resolver
				continue
			}
			mut pipe_in := right.scope.must_lookup_type(fn_info.pipe_in)
			if pipe_in_sequence_info := pipe_in.sequence_info() {
				pipe_in = right.scope.must_lookup_type(pipe_in_sequence_info.elem)
			}

			c.check_types(
				got: left_ts
				got_label: 'left'
				want: pipe_in
				want_label: 'pipe in of right'
				pos: left.pos().merge(right.pos)
				message_format: .got_want
			) or {}
		}
	}
}

fn (mut c Checker) prefix_expr(expr ast.PrefixExpr) {
	$if trace_checker ? {
		c.trace_begin(@FN)
		defer {
			c.trace_end()
		}
	}

	c.expr(expr.expr)
}

fn (mut c Checker) selector_expr(expr ast.SelectorExpr) {
	$if trace_checker ? {
		c.trace_begin(@FN)
		defer {
			c.trace_end()
		}
	}

	c.expr(expr.left)
	c.expr(expr.ident)
}

fn (mut c Checker) string_literal(s ast.StringLiteral) {
	$if trace_checker ? {
		c.trace_begin(@FN)
		defer {
			c.trace_end()
		}
	}

	for content in s.contents {
		if content is Expr {
			c.expr(content)
		}
	}
}

fn (mut c Checker) var_(v ast.Var) {
	$if trace_checker ? {
		c.trace_begin(@FN)
		defer {
			c.trace_end()
		}
	}
}
