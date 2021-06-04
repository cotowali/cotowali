module sh

import cotowari.ast

fn (mut e Emitter) array_literal(expr ast.ArrayLiteral, opt ExprOpt) {
	name := e.new_tmp_var()

	old_kind := e.cur_kind
	e.cur_kind = .literal
	e.assign(name, ast.Expr(expr), ast.Expr(expr).type_symbol())
	e.cur_kind = old_kind

	e.array(name, opt)
}

fn (mut e Emitter) array(name string, opt ExprOpt) {
	if opt.as_command {
		e.writeln('echo \$(eval echo \$(array_elements $name) )')
		return
	}
	if opt.expand_array {
		e.write('\$(eval echo \$(array_elements $name) )')
	} else {
		e.write(name)
	}
}
