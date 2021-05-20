module sh

import cotowari.ast
import cotowari.errors { unreachable }

fn (mut emit Emitter) array_literal(expr ast.ArrayLiteral, opt ExprOpt) {
	name := emit.new_tmp_var()
	emit.array_assign(name, expr)
	emit.array(name, opt)
}

fn (mut emit Emitter) array_assign(name string, expr ast.Expr) {
	match expr {
		ast.ArrayLiteral {
			emit.write('array_assign "$name"')
			for elem in expr.elements {
				emit.write(' ')
				emit.expr(elem, as_command: false)
			}
			emit.writeln('')
		}
		ast.Var {
			panic('unimplemented')
		}
		else {
			panic(unreachable)
		}
	}
}

fn (mut emit Emitter) array(name string, opt ExprOpt) {
	if opt.as_command {
		emit.writeln('echo \$(eval echo \$(array_elements $name) )')
		return
	}
	panic('unimplemented')
}
