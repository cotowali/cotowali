module sh

import cotowari.ast

fn (mut e Emitter) array_literal(expr ast.ArrayLiteral, opt ExprOpt) {
	name := e.new_tmp_var()
	e.assign(name, ast.Expr(expr), ast.Expr(expr).type_symbol())
	e.array(name, opt)
}

fn (mut e Emitter) array(name string, opt ExprOpt) {
	if opt.as_command {
		e.code.writeln('echo \$(eval echo \$(array_elements $name) )')
		return
	}
	e.code.write(name)
}
