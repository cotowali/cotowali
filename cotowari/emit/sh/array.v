module sh

import cotowari.ast
import cotowari.errors

fn (mut emit Emitter) array_literal(expr ast.ArrayLiteral, opt ExprOpt) {
	name := emit.new_tmp_var()
	emit.assign(name, ast.Expr(expr), ast.Expr(expr).type_symbol())
	emit.array(name, opt)
}

type ArrayAssignValue = ast.ArrayLiteral | string

fn (mut emit Emitter) array_assign(name string, value ArrayAssignValue) {
	match value {
		ast.ArrayLiteral {
			emit.write('array_assign "$name"')
			for elem in value.elements {
				emit.write(' ')
				emit.expr(elem, as_command: false)
			}
			emit.writeln('')
		}
		string {
			emit.writeln('array_assign "$name" \$(array_elements "$value")')
		}
	}
}

fn (mut emit Emitter) array(name string, opt ExprOpt) {
	if opt.as_command {
		emit.writeln('echo \$(eval echo \$(array_elements $name) )')
		return
	}
	emit.write(name)
}
