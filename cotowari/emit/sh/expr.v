module sh

import cotowari.ast { Pipeline }
import cotowari.token { Token }
import cotowari.errors { unreachable }

struct ExprOpt {
	as_command        bool
	writeln           bool
	discard_stdout    bool
	inside_arithmetic bool
}

fn (mut emit Emitter) expr(expr ast.Expr, opt ExprOpt) {
	match expr {
		ast.IntLiteral, ast.StringLiteral, ast.InfixExpr, ast.PrefixExpr, ast.Var {
			if opt.as_command {
				emit.write('echo ')
			}
		}
		else {}
	}
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
		ast.IntLiteral {
			emit.write(expr.token.text)
		}
		ast.ArrayLiteral {
			panic('array literal is unimplemented')
		}
		ast.StringLiteral {
			emit.write("'$expr.token.text'")
		}
		ast.Var {
			// '$(( n == 0 ))' or 'echo "$n"'
			emit.write(if opt.inside_arithmetic {
				'$expr.out_name()'
			} else {
				'"\$$expr.out_name()"'
			})
		}
	}
	if opt.as_command && opt.discard_stdout {
		emit.write(' > /dev/null')
	}
	if opt.writeln {
		emit.writeln('')
	}
}

fn (mut emit Emitter) infix_expr(expr ast.InfixExpr, opt ExprOpt) {
	op := expr.op
	if !op.kind.@is(.binary_op) {
		panic(unreachable)
	}
	match op.kind {
		.op_plus, .op_minus, .op_div, .op_mul, .op_mod, .op_eq, .op_ne, .op_gt, .op_lt {
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
	if !op.kind.@is(.prefix_op) {
		panic(unreachable)
	}

	opt_for_expr := ExprOpt{
		...opt
		as_command: false
	}
	match op.kind {
		.op_plus {
			emit.expr(expr.expr, opt_for_expr)
		}
		.op_minus {
			emit.expr(ast.InfixExpr{
				scope: expr.scope
				left: ast.IntLiteral{
					scope: expr.scope
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
			}, opt_for_expr)
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
