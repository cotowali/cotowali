// Copyright (c) 2021 zakuro <z@kuro.red>. All rights reserved.
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
module checker

import cotowali.ast { Expr }
import cotowali.symbols { ArrayTypeInfo, TypeSymbol, TypeSymbol, builtin_type }
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
		ast.DefaultValue {}
		ast.FloatLiteral {}
		ast.IndexExpr { c.index_expr(expr) }
		ast.InfixExpr { c.infix_expr(expr) }
		ast.IntLiteral {}
		ast.MapLiteral { c.map_literal(expr) }
		ast.ParenExpr { c.paren_expr(expr) }
		ast.Pipeline { c.pipeline(expr) }
		ast.PrefixExpr { c.prefix_expr(expr) }
		ast.StringLiteral { c.string_literal(expr) }
		ast.Var { c.var_(expr) }
	}
}

fn (mut c Checker) array_literal(expr ast.ArrayLiteral) {
	c.exprs(expr.elements)
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

fn (mut c Checker) call_command_expr(expr ast.CallCommandExpr) {
	$if trace_checker ? {
		c.trace_begin(@FN)
		defer {
			c.trace_end()
		}
	}

	c.exprs(expr.args)
}

fn (mut c Checker) call_expr(expr ast.CallExpr) {
	if Expr(expr).typ() == builtin_type(.placeholder) {
		return
	}

	$if trace_checker ? {
		c.trace_begin(@FN)
		defer {
			c.trace_end()
		}
	}

	pos := Expr(expr).pos()
	scope := expr.scope
	function_info := expr.function_info()
	params := function_info.params
	param_syms := params.map(scope.must_lookup_type(it))
	is_varargs := expr.is_varargs()

	args := expr.args
	if is_varargs {
		min_len := params.len - 1
		if args.len < min_len {
			c.error('expected $min_len or more arguments, but got $args.len', pos)
			return
		}
	} else if args.len != params.len {
		c.error('expected $params.len arguments, but got $args.len', pos)
		return
	}

	c.exprs(args)

	mut call_args_types_ok := true
	varargs_elem_ts := if is_varargs {
		scope.must_lookup_type((param_syms.last().info as ArrayTypeInfo).elem)
	} else {
		// ?TypeSymbol(none)
		&TypeSymbol{}
	}
	for i, arg in args {
		arg_ts := arg.type_symbol()
		param_ts := if is_varargs && i >= params.len - 1 {
			varargs_elem_ts
		} else {
			scope.must_lookup_type(params[i])
		}

		if param_ts.kind() == .placeholder || arg_ts.kind() == .placeholder {
			call_args_types_ok = false
			continue
		}

		c.check_types(want: param_ts, got: arg_ts, pos: arg.pos()) or { call_args_types_ok = false }
	}
	if !call_args_types_ok {
		return
	}
}

fn (mut c Checker) index_expr(expr ast.IndexExpr) {
	$if trace_checker ? {
		c.trace_begin(@FN)
		defer {
			c.trace_end()
		}
	}

	c.expr(expr.left)
	left_ts := expr.left.type_symbol()

	want_typ := if _ := left_ts.array_info() {
		builtin_type(.int)
	} else if info := left_ts.map_info() {
		info.key
	} else {
		builtin_type(.placeholder)
	}
	if want_typ == builtin_type(.placeholder) {
		c.error('`$left_ts.name` does not support indexing', expr.pos)
		return
	}

	c.check_types(
		want: Expr(expr).scope().must_lookup_type(want_typ)
		got: expr.index.type_symbol()
		pos: expr.index.pos()
	) or {}
}

fn (mut c Checker) infix_expr_invalid_operation(op string, left TypeSymbol, right TypeSymbol, pos Pos) IError {
	return c.error('invalid operation: `$left.name` $op `$right.name`', pos)
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
		if i > 0 {
			if e is ast.CallCommandExpr {
				// allow `any_value |> @command()`
				continue
			}
			right := c.expect_function_call(e) or { continue }
			left := expr.exprs[i - 1]

			mut left_ts := left.type_symbol()
			if left_array_info := left_ts.array_info() {
				if left_array_info.variadic {
					left_ts = left.scope().must_lookup_type(left_array_info.elem)
				}
			}

			mut pipe_in := right.scope.must_lookup_type(right.function_info().pipe_in)
			if pipe_in_array_info := pipe_in.array_info() {
				if pipe_in_array_info.variadic {
					pipe_in = right.scope.must_lookup_type(pipe_in_array_info.elem)
				}
			}

			c.check_types(
				want: left_ts
				want_label: 'left'
				got: pipe_in
				got_label: 'pipe in of right'
				pos: left.pos().merge(right.pos)
				synmetric: true
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
