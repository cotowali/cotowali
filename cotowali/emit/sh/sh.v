module sh

fn (mut e Emitter) sh_test_cond_infix(left ExprOrString, op string, right ExprOrString) {
	e.expr_or_string(left, {})
	e.write(' $op ')
	e.expr_or_string(right, {})
}

fn (mut e Emitter) sh_test_cond_is_true(expr ExprOrString) {
	e.sh_test_cond_infix(expr, ' = ', "'true'")
}

fn (mut e Emitter) sh_test_command<T>(f fn (mut Emitter, T), v T) {
	e.write_inline_block({ open: '[ ', close: ' ]' }, f, v)
}

fn (mut e Emitter) sh_result_to_bool() {
	e.write(" && echo 'true' || echo 'false'")
}

fn (mut e Emitter) sh_test_command_as_bool<T>(f fn (mut Emitter, T), v T) {
	open, close := '"\$(', ')"'
	e.write(open)
	e.write_inline_block({ open: '[ ', close: ' ]' }, f, v)
	e.sh_result_to_bool()
	e.write(close)
}
