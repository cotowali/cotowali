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
	if !func.is_function() {
		c.error('`$name` is not function (`$func.type_symbol().name`)', Expr(expr).pos())
		return
	}
}
