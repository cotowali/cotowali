module checker

import cotowari.ast

fn (mut c Checker) expr(expr ast.Expr) {
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
	left_type := expr.left.typ()
	right_type := expr.right.typ()
	if left_type.id != right_type.id {
		c.error('mismatch type: `$left_type.name` (left), `$right_type.name` (right)',
			ast.Expr(expr).pos())
	}
}
