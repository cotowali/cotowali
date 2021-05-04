module checker

import cotowari.ast { Expr }

fn (mut c Checker) expr(expr Expr) {
	match expr {
		ast.CallFn {}
		ast.InfixExpr { c.infix_expr(expr) }
		ast.Literal {}
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
