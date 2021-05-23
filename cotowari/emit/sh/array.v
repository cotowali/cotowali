module sh

import cotowari.ast

fn (mut e Emitter) array_literal(expr ast.ArrayLiteral, opt ExprOpt) {
	name := e.new_tmp_var()
	e.assign(name, ast.Expr(expr), ast.Expr(expr).type_symbol())
	e.array(name, opt)
}

type ArrayAssignValue = ast.ArrayLiteral | string

fn (mut e Emitter) array_assign(name string, value ArrayAssignValue) {
	match value {
		ast.ArrayLiteral {
			e.code.write('array_assign "$name"')
			for elem in value.elements {
				e.code.write(' ')
				e.expr(elem, as_command: false)
			}
			e.code.writeln('')
		}
		string {
			e.code.writeln('array_assign "$name" \$(array_elements "$value")')
		}
	}
}

fn (mut e Emitter) array(name string, opt ExprOpt) {
	if opt.as_command {
		e.code.writeln('echo \$(eval echo \$(array_elements $name) )')
		return
	}
	e.code.write(name)
}
