module checker

import cotowari.ast { Expr }

fn (mut c Checker) expr(expr Expr) {
	match mut expr {
		ast.CallFn { c.call_expr(mut expr) }
		ast.InfixExpr { c.infix_expr(expr) }
		ast.IntLiteral {}
		ast.StringLiteral {}
		ast.Pipeline {}
		ast.PrefixExpr {}
		ast.Var {}
	}
}

fn (mut c Checker) infix_expr(expr ast.InfixExpr) {
	left_ts := expr.left.type_symbol()
	right_ts := expr.right.type_symbol()
	if left_ts.typ != right_ts.typ {
		c.error('mismatch type: `$left_ts.name` (left), `$right_ts.name` (right)', Expr(expr).pos())
	}
}

fn (mut c Checker) call_expr(mut expr ast.CallFn) {
	name := expr.func.name()
	func := expr.scope.lookup_var(name) or {
		c.error('function `$name` is not defined', Expr(expr).pos())
		return
	}
	ts := func.type_symbol()
	fn_info := ts.fn_info() or {
		c.error('`$name` is not function (`$ts.name`)', Expr(expr).pos())
		return
	}
	params, args := fn_info.params, expr.args
	if params.len != args.len {
		c.error('expected $params.len arguments, but got $args.len', Expr(expr).pos())
		return
	}
}
