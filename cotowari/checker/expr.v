module checker

import cotowari.ast { Expr }
import cotowari.symbols { TypeSymbol, builtin_type }

fn (mut c Checker) expr(expr Expr) {
	match mut expr {
		ast.ArrayLiteral { c.array_literal(expr) }
		ast.AsExpr { c.as_expr(expr) }
		ast.CallExpr { c.call_expr(mut expr) }
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

fn (mut c Checker) call_expr(mut expr ast.CallExpr) {
	if Expr(expr).typ() == builtin_type(.placeholder) {
		return
	}

	pos := Expr(expr).pos()
	fn_info := expr.fn_info()
	params := fn_info.params
	expr.args

	args := expr.args
	if fn_info.is_varargs {
		min_len := params.len - 1
		if args.len < min_len {
			c.error('expected $min_len or more arguments, but got $args.len', pos)
			return
		}
	} else if args.len != params.len {
		c.error('expected $params.len arguments, but got $args.len', pos)
		return
	}

	scope := expr.scope
	mut call_args_types_ok := true
	varargs_elem_ts := if fn_info.is_varargs {
		scope.must_lookup_type(fn_info.varargs_elem)
	} else {
		// ?TypeSymbol(none)
		TypeSymbol{}
	}
	for i, arg in args {
		c.expr(arg)
		arg_ts := arg.type_symbol()
		param_ts := if fn_info.is_varargs && i >= params.len - 1 {
			varargs_elem_ts
		} else {
			scope.must_lookup_type(params[i])
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
		c.error('`$left_ts.name` does not support indexing', expr.pos)
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
	for e in expr.exprs {
		c.expr(e)
	}
	// TODO: check stdin/stout type
}

fn (mut c Checker) prefix_expr(expr ast.PrefixExpr) {
	c.expr(expr.expr)
}

fn (mut c Checker) var_(v ast.Var) {
}
