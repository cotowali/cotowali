module checker

import cotowari.ast { Expr }

fn (mut c Checker) expr(expr Expr) {
	match mut expr {
		ast.CallFn { c.call_expr(mut expr) }
		ast.InfixExpr { c.infix_expr(expr) }
		ast.ArrayLiteral {}
		ast.IntLiteral {}
		ast.StringLiteral {}
		ast.Pipeline {}
		ast.PrefixExpr {}
		ast.Var {}
	}
}

fn (mut c Checker) infix_expr(expr ast.InfixExpr) {
	c.check_types(
		want: expr.left.type_symbol()
		want_label: 'left'
		got: expr.right.type_symbol()
		got_label: 'right'
		pos: expr.pos()
		synmetric: true
	) or { return }
}

fn (mut c Checker) call_expr(mut expr ast.CallFn) {
	name := expr.func.name()
	pos := Expr(expr).pos()

	func := expr.scope.lookup_var(name) or {
		c.error('function `$name` is not defined', pos)
		return
	}
	expr.func.sym = func
	ts := func.type_symbol()
	if !func.is_function() {
		c.error('`$name` is not function (`$ts.name`)', pos)
		return
	}

	params, args := ts.fn_info().params, expr.args
	if params.len != args.len {
		c.error('expected $params.len arguments, but got $args.len', pos)
		return
	}

	mut call_args_types_ok := true
	for i, arg in args {
		arg_ts := arg.type_symbol()
		param_ts := expr.scope.must_lookup_type(params[i])
		c.check_types(want: param_ts, got: arg_ts, pos: arg.pos()) or { call_args_types_ok = false }
	}
	if !call_args_types_ok {
		return
	}
}
