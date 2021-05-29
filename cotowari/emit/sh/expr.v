module sh

import cotowari.ast
import cotowari.token { Token }
import cotowari.symbols { builtin_type }
import cotowari.errors { unreachable }

struct ExprOpt {
	as_command        bool
	writeln           bool
	discard_stdout    bool
	inside_arithmetic bool
}

fn (mut e Emitter) expr(expr ast.Expr, opt ExprOpt) {
	match expr {
		ast.AsExpr { e.expr(expr.expr, opt) }
		ast.CallFn { e.call_fn(expr, opt) }
		ast.ParenExpr { e.paren_expr(expr, opt) }
		ast.Pipeline { e.pipeline(expr, opt) }
		ast.InfixExpr { e.infix_expr(expr, opt) }
		ast.PrefixExpr { e.prefix_expr(expr, opt) }
		ast.IntLiteral { e.write_echo_if_command_then_write(expr.token.text, opt) }
		ast.ArrayLiteral { e.array_literal(expr, opt) }
		ast.StringLiteral { e.write_echo_if_command_then_write("'$expr.token.text'", opt) }
		ast.Var { e.var_(expr, opt) }
	}
	if opt.as_command && opt.discard_stdout {
		e.write(' > /dev/null')
	}
	if opt.writeln {
		e.writeln('')
	}
}

fn (mut e Emitter) write_echo_if_command(opt ExprOpt) {
	if opt.as_command {
		e.write('echo ')
	}
}

fn (mut e Emitter) write_echo_if_command_then_write(s string, opt ExprOpt) {
	e.write_echo_if_command(opt)
	e.write(s)
}

fn (mut e Emitter) var_(v ast.Var, opt ExprOpt) {
	match v.type_symbol().kind() {
		.array {
			e.array(v.out_name(), opt)
		}
		else {
			// '$(( n == 0 ))' or 'echo "$n"'
			s := if opt.inside_arithmetic { '$v.out_name()' } else { '"\$$v.out_name()"' }
			e.write_echo_if_command_then_write(s, opt)
		}
	}
}

fn (mut e Emitter) infix_expr(expr ast.InfixExpr, opt ExprOpt) {
	op := expr.op
	if !op.kind.@is(.binary_op) {
		panic(unreachable)
	}

	if expr.left.typ() == builtin_type(.int) {
		e.infix_expr_for_int(expr, opt)
	} else {
		panic('infix_expr for `$expr.left.type_symbol().name` is unimplemented')
	}
}

fn (mut e Emitter) infix_expr_for_int(expr ast.InfixExpr, opt ExprOpt) {
	if expr.left.typ() != builtin_type(.int) {
		panic(unreachable)
	}
	e.write_echo_if_command(opt)
	match expr.op.kind {
		.op_plus, .op_minus, .op_div, .op_mul, .op_mod, .op_eq, .op_ne, .op_gt, .op_lt {
			if !opt.inside_arithmetic {
				e.write('\$(( ( ')
			}
			e.expr(expr.left, inside_arithmetic: true)
			e.write(' $expr.op.text ')
			e.expr(expr.right, inside_arithmetic: true)
			if !opt.inside_arithmetic {
				e.write(' ) ))')
			}
		}
		else {
			panic('unimplemented')
		}
	}
}

fn (mut e Emitter) paren_expr(expr ast.ParenExpr, opt ExprOpt) {
	e.write_echo_if_command(opt)
	if opt.inside_arithmetic {
		e.write('(')
	}
	e.expr(expr.expr, { ...opt, as_command: false })
	if opt.inside_arithmetic {
		e.write(' ) ')
	}
}

fn (mut e Emitter) prefix_expr(expr ast.PrefixExpr, opt ExprOpt) {
	op := expr.op
	if !op.kind.@is(.prefix_op) {
		panic(unreachable)
	}

	e.write_echo_if_command(opt)
	opt_for_expr := ExprOpt{
		...opt
		as_command: false
	}
	match op.kind {
		.op_plus {
			e.expr(expr.expr, opt_for_expr)
		}
		.op_minus {
			e.expr(ast.InfixExpr{
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

fn (mut e Emitter) pipeline(stmt ast.Pipeline, opt ExprOpt) {
	if !opt.as_command {
		e.write('\$(')
	}

	for i, expr in stmt.exprs {
		if i > 0 {
			e.write(' | ')
		}
		e.expr(expr, as_command: true)
	}
	e.writeln('')

	if !opt.as_command {
		e.write(')')
	}
}
