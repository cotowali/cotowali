module checker

import cotowali.ast { Expr }
import cotowali.symbols { ArrayTypeInfo, TypeSymbol, builtin_type }

fn (mut c Checker) expr(expr Expr) {
	match mut expr {
		ast.ArrayLiteral { c.array_literal(expr) }
		ast.AsExpr { c.as_expr(expr) }
		ast.BoolLiteral {}
		ast.CallCommandExpr { c.call_command_expr(expr) }
		ast.CallExpr { c.call_expr(mut expr) }
		ast.DefaultValue {}
		ast.FloatLiteral {}
		ast.IndexExpr { c.index_expr(expr) }
		ast.InfixExpr { c.infix_expr(expr) }
		ast.IntLiteral {}
		ast.ParenExpr { c.paren_expr(expr) }
		ast.Pipeline { c.pipeline(expr) }
		ast.PrefixExpr { c.prefix_expr(expr) }
		ast.StringLiteral {}
		ast.Var { c.var_(expr) }
	}
}

fn (mut c Checker) array_literal(expr ast.ArrayLiteral) {
	for e in expr.elements {
		c.expr(e)
	}
}

fn (mut c Checker) as_expr(expr ast.AsExpr) {
	c.expr(expr.expr)
}

fn (mut c Checker) call_command_expr(expr ast.CallCommandExpr) {
	for arg in expr.args {
		c.expr(arg)
	}
}

fn (mut c Checker) call_expr(mut expr ast.CallExpr) {
	if Expr(expr).typ() == builtin_type(.placeholder) {
		return
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
			c.error('expected $min_len or more arguments, but got $args.len', pos) or { return }
		}
	} else if args.len != params.len {
		c.error('expected $params.len arguments, but got $args.len', pos) or { return }
	}

	mut call_args_types_ok := true
	varargs_elem_ts := if is_varargs {
		scope.must_lookup_type((param_syms.last().info as ArrayTypeInfo).elem)
	} else {
		// ?TypeSymbol(none)
		TypeSymbol{}
	}
	for i, arg in args {
		c.expr(arg)

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
	c.expr(expr.left)
	left_ts := expr.left.type_symbol()
	if left_ts.kind() != .array {
		c.error('`$left_ts.name` does not support indexing', expr.pos) or {}
	}
	c.expr(expr.index)
	c.check_types(
		want: Expr(expr).scope().must_lookup_type(builtin_type(.int))
		got: expr.index.type_symbol()
		pos: expr.index.pos()
	) or {}
}

fn (mut c Checker) infix_expr(expr ast.InfixExpr) {
	c.expr(expr.left)
	c.expr(expr.right)
	c.check_types(
		want: expr.left.type_symbol()
		want_label: 'left'
		got: expr.right.type_symbol()
		got_label: 'right'
		pos: expr.pos()
		synmetric: true
	) or { return }
}

fn (mut c Checker) paren_expr(expr ast.ParenExpr) {
	c.expr(expr.expr)
}

fn (mut c Checker) pipeline(expr ast.Pipeline) {
	for i, e in expr.exprs {
		c.expr(e)
		if i > 0 {
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
	c.expr(expr.expr)
}

fn (mut c Checker) var_(v ast.Var) {
}
