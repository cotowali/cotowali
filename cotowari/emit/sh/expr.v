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
			emit.write_echo_if_command(opt)
			emit.code.write(expr.token.text)
		}
		ast.ArrayLiteral {
			emit.array_literal(expr, opt)
		}
		ast.StringLiteral {
			emit.write_echo_if_command(opt)
			emit.code.write("'$expr.token.text'")
		}
		ast.Var {
			emit.var_(expr, opt)
		}
	}
	if opt.as_command && opt.discard_stdout {
		emit.code.write(' > /dev/null')
	}
	if opt.writeln {
		emit.code.writeln('')
	}
}

fn (mut emit Emitter) write_echo_if_command(opt ExprOpt) {
	if opt.as_command {
		emit.code.write('echo ')
	}
}

fn (mut emit Emitter) var_(v ast.Var, opt ExprOpt) {
	match v.type_symbol().kind() {
		.array {
			emit.array(v.out_name(), opt)
		}
		else {
			emit.write_echo_if_command(opt)
			// '$(( n == 0 ))' or 'echo "$n"'
			emit.code.write(if opt.inside_arithmetic { '$v.out_name()' } else { '"\$$v.out_name()"' })
		}
	}
}

fn (mut emit Emitter) infix_expr(expr ast.InfixExpr, opt ExprOpt) {
	op := expr.op
	if !op.kind.@is(.binary_op) {
		panic(unreachable)
	}
	emit.write_echo_if_command(opt)
	match op.kind {
		.op_plus, .op_minus, .op_div, .op_mul, .op_mod, .op_eq, .op_ne, .op_gt, .op_lt {
			if !opt.inside_arithmetic {
				emit.code.write('\$(( ( ')
			}
			emit.expr(expr.left, inside_arithmetic: true)
			emit.code.write(' $op.text ')
			emit.expr(expr.right, inside_arithmetic: true)
			if !opt.inside_arithmetic {
				emit.code.write(' ) ))')
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

	emit.write_echo_if_command(opt)
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
		emit.code.write('\$(')
	}

	for i, expr in stmt.exprs {
		if i > 0 {
			emit.code.write(' | ')
		}
		emit.expr(expr, as_command: true)
	}
	emit.code.writeln('')

	if !opt.as_command {
		emit.code.write(')')
	}
}
