module emit

import cotowari.ast { Pipeline }
import cotowari.token { Token }

struct ExprOpt {
	as_command        bool
	writeln           bool
	inside_arithmetic bool
}

fn (mut emit Emitter) expr(expr ast.Expr, opt ExprOpt) {
	match expr {
		ast.CallFn {
			emit.call_fn(expr, opt)
		}
		ast.Pipeline {
			emit.pipeline(expr, opt)
		}
		ast.InfixExpr {
			emit.infix_expr(expr, opt)
		}
		ast.PrefixExpr {
			emit.prefix_expr(expr, opt)
		}
		ast.Literal {
			if opt.as_command {
				emit.write('echo ')
			}
			match expr.kind {
				.int { emit.write(expr.token.text) }
				.string { emit.write("'$expr.token.text'") }
			}
		}
		ast.Var {
			if opt.as_command {
				emit.write('echo ')
			}
			// '$(( n == 0 ))' or 'echo "$n"'
			emit.write(if opt.inside_arithmetic {
				'$expr.out_name()'
			} else {
				'"\$$expr.out_name()"'
			})
		}
	}
	if opt.writeln {
		emit.writeln('')
	}
}

fn (mut emit Emitter) infix_expr(expr ast.InfixExpr, opt ExprOpt) {
	op := expr.op
	match op.kind {
		.op_plus, .op_minus, .op_div, .op_mul, .op_mod, .op_eq, .op_ne, .op_gt, .op_lt {
			if opt.as_command {
				emit.write('echo ')
			}
			if !opt.inside_arithmetic {
				emit.write('\$(( ( ')
			}
			emit.expr(expr.left, inside_arithmetic: true)
			emit.write(' $op.text ')
			emit.expr(expr.right, inside_arithmetic: true)
			if !opt.inside_arithmetic {
				emit.write(' ) ))')
			}
		}
		else {
			panic('unimplemented')
		}
	}
}

fn (mut emit Emitter) prefix_expr(expr ast.PrefixExpr, opt ExprOpt) {
	op := expr.op
	match op.kind {
		.op_plus {
			emit.expr(expr.expr, opt)
		}
		.op_minus {
			emit.expr(ast.InfixExpr{
				left: ast.Literal{
					kind: .int
					token: Token{
						kind: .int_lit
						text: '-1'
					}
				}
				right: expr.expr
				op: Token{
					kind: .op_mul
					text: '*'
				}
			}, opt)
		}
		else {
			panic('unimplemented')
		}
	}
}

fn (mut emit Emitter) pipeline(stmt Pipeline, opt ExprOpt) {
	if !opt.as_command {
		emit.write('\$(')
	}

	for i, expr in stmt.exprs {
		if i > 0 {
			emit.write(' | ')
		}
		emit.expr(expr, as_command: true)
	}
	emit.writeln('')

	if !opt.as_command {
		emit.write(')')
	}
}

fn (mut emit Emitter) call_fn(expr ast.CallFn, opt ExprOpt) {
	if !opt.as_command {
		emit.write('\$(')
	}

	emit.write(expr.func.out_name())
	for arg in expr.args {
		emit.write(' ')
		emit.expr(arg, {})
	}

	if !opt.as_command {
		emit.write(')')
	}
}
