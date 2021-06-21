module sh

fn (mut e Emitter) sh_test_cond_infix(left ExprOrString, op string, right ExprOrString) {
	e.expr_or_string(left, {})
	e.write(' $op ')
	e.expr_or_string(right, {})
}
