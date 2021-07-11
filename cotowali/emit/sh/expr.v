// Copyright (c) 2021 The Cotowali Authors. All rights reserved.
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
module sh

import cotowali.ast
import cotowali.token { Token }
import cotowali.symbols { builtin_type }
import cotowali.util { panic_and_value }
import cotowali.errors { unreachable }

type ExprOrString = ast.Expr | string

struct ExprOpt {
	as_command        bool
	as_condition      bool
	expand_array      bool
	writeln           bool
	discard_stdout    bool
	inside_arithmetic bool
}

struct ExprWithOpt<T> {
	expr T       [required]
	opt  ExprOpt [required]
}

fn expr_with_opt<T>(expr T, opt ExprOpt) ExprWithOpt<T> {
	return ExprWithOpt<T>{expr, opt}
}

struct ExprWithValue<T, U> {
	expr  T [required]
	value U [required]
}

fn expr_with_value<T, U>(expr T, v U) ExprWithValue<T, U> {
	return ExprWithValue<T,U>{expr, v}
}

fn (mut e Emitter) expr_or_string(expr ExprOrString, opt ExprOpt) {
	match expr {
		ast.Expr { e.expr(expr, opt) }
		string { e.write_echo_if_command_then_write(expr, opt) }
	}
}

fn (mut e Emitter) expr(expr ast.Expr, opt ExprOpt) {
	match expr {
		ast.AsExpr { e.expr(expr.expr, opt) }
		ast.BoolLiteral { e.bool_literal(expr, opt) }
		ast.CallCommandExpr { e.call_command_expr(expr, opt) }
		ast.CallExpr { e.call_expr(expr, opt) }
		ast.DefaultValue { e.default_value(expr, opt) }
		ast.FloatLiteral { e.float_literal(expr, opt) }
		ast.IntLiteral { e.int_literal(expr, opt) }
		ast.ParenExpr { e.paren_expr(expr, opt) }
		ast.Pipeline { e.pipeline(expr, opt) }
		ast.InfixExpr { e.infix_expr(expr, opt) }
		ast.IndexExpr { e.index_expr(expr, opt) }
		ast.MapLiteral { e.map_literal(expr, opt) }
		ast.PrefixExpr { e.prefix_expr(expr, opt) }
		ast.ArrayLiteral { e.array_literal(expr, opt) }
		ast.StringLiteral { e.string_literal(expr, opt) }
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

fn (mut e Emitter) bool_literal(expr ast.BoolLiteral, opt ExprOpt) {
	if opt.as_condition {
		e.write(if expr.bool() { 'true' } else { 'false' })
		return
	}
	v := if expr.bool() { true_value } else { false_value }
	e.write_echo_if_command_then_write(v, opt)
}

fn (mut e Emitter) float_literal(expr ast.FloatLiteral, opt ExprOpt) {
	e.write_echo_if_command_then_write(expr.token.text, opt)
}

fn (mut e Emitter) int_literal(expr ast.IntLiteral, opt ExprOpt) {
	e.write_echo_if_command_then_write(expr.token.text, opt)
}

fn (mut e Emitter) string_literal(expr ast.StringLiteral, opt ExprOpt) {
	e.write_echo_if_command_then_write("'$expr.token.text'", opt)
}

fn (mut e Emitter) default_value(expr ast.DefaultValue, opt ExprOpt) {
	e.write_echo_if_command(opt)

	e.write(match expr.typ {
		builtin_type(.bool) { false_value }
		builtin_type(.int), builtin_type(.float) { '0' }
		else { '' }
	})
}

fn (mut e Emitter) var_(v ast.Var, opt ExprOpt) {
	ident := e.ident_for(v)
	match v.type_symbol().kind() {
		.array {
			e.array(ident, opt)
		}
		else {
			// '$(( n == 0 ))' or 'echo "$n"'
			s := if opt.inside_arithmetic { '$ident' } else { '"\$$ident"' }
			e.write_echo_if_command_then_write(s, opt)
		}
	}
}

fn (mut e Emitter) index_expr(expr ast.IndexExpr, opt ExprOpt) {
	e.write_echo_if_command(opt)

	e.write_inline_block({ open: '\$( ', close: ' )' }, fn (mut e Emitter, v ExprWithOpt<ast.IndexExpr>) {
		name := e.ident_for(v.expr.left)

		e.write('array_get $name ')
		e.expr(v.expr.index, v.opt)
	}, expr_with_opt(expr, opt))
}

fn (mut e Emitter) infix_expr(expr ast.InfixExpr, opt ExprOpt) {
	op := expr.op
	if !op.kind.@is(.infix_op) {
		panic(unreachable('not a infix op'))
	}

	match expr.left.typ() {
		builtin_type(.int), builtin_type(.float) { e.infix_expr_for_number(expr, opt) }
		builtin_type(.string) { e.infix_expr_for_string(expr, opt) }
		builtin_type(.bool) { e.infix_expr_for_bool(expr, opt) }
		else { panic('infix_expr for `$expr.left.type_symbol().name` is unimplemented') }
	}
}

fn (mut e Emitter) infix_expr_for_bool(expr ast.InfixExpr, opt ExprOpt) {
	if expr.left.typ() != builtin_type(.bool) {
		panic(unreachable('not a bool operand'))
	}

	if opt.as_command {
		panic('unimplemented')
	}

	if expr.op.kind in [.eq, .ne] {
		e.sh_test_command_for_expr(fn (mut e Emitter, expr ast.InfixExpr) {
			op := if expr.op.kind == .eq { ' = ' } else { ' != ' }
			e.sh_test_cond_infix(expr.left, op, expr.right)
		}, expr, opt)
		return
	}

	op := match expr.op.kind {
		.logical_and { '&&' }
		.logical_or { '||' }
		else { panic_and_value(unreachable('invalid op'), '') }
	}

	e.expr(expr.left, as_condition: true)
	e.write(' $op ')
	e.expr(expr.right, as_condition: true)
}

fn (mut e Emitter) infix_expr_for_number(expr ast.InfixExpr, opt ExprOpt) {
	if expr.left.typ() !in [builtin_type(.int), builtin_type(.float)] {
		panic(unreachable('invalid operand'))
	}

	if expr.left.typ() == builtin_type(.float) || expr.right.typ() == builtin_type(.float) {
		e.infix_expr_for_float(expr, opt)
	} else {
		e.infix_expr_for_int(expr, opt)
	}
}

fn (mut e Emitter) infix_expr_for_float(expr ast.InfixExpr, opt ExprOpt) {
	if expr.left.typ() !in [builtin_type(.float), builtin_type(.int)] {
		panic(unreachable('invalid operand'))
	}
	e.write_echo_if_command(opt)

	open, close := '\$( echo " ', ' " | bc -l )' // $( echo " expr " | bc )

	if expr.op.kind.@is(.comparsion_op) {
		e.sh_test_command_for_expr(fn (mut e Emitter, expr ast.InfixExpr) {
			open, close := '\$( echo " ', ' " | bc -l )' // see above

			e.write(open)
			e.expr(expr.left, {})
			e.write(' $expr.op.text ')
			e.expr(expr.right, {})
			e.write(close)

			e.write(' -eq 1')
		}, expr, opt)
		return
	}
	e.write(open)
	e.expr(expr.left, {})
	e.write(' $expr.op.text ')
	e.expr(expr.right, {})
	e.write(close)
}

fn (mut e Emitter) infix_expr_for_int(expr ast.InfixExpr, opt ExprOpt) {
	if expr.left.typ() != builtin_type(.int) {
		panic(unreachable('invalid operand'))
	}
	e.write_echo_if_command(opt)

	if expr.op.kind.@is(.comparsion_op) {
		e.sh_test_command_for_expr(fn (mut e Emitter, expr ast.InfixExpr) {
			op := match expr.op.kind {
				.eq { '-eq' }
				.ne { '-ne' }
				.gt { '-gt' }
				.ge { '-ge' }
				.lt { '-lt' }
				.le { '-le' }
				else { panic_and_value(unreachable('invalid op'), '') }
			}
			e.sh_test_cond_infix(expr.left, op, expr.right)
		}, expr, opt)
		return
	}

	match expr.op.kind {
		.plus, .minus, .div, .mul, .mod {
			open, close := if opt.inside_arithmetic { '', '' } else { '\$(( ( ', ' ) ))' }
			e.write_inline_block({ open: open, close: close }, fn (mut e Emitter, expr ast.InfixExpr) {
				e.expr(expr.left, inside_arithmetic: true)
				e.write(' $expr.op.text ')
				e.expr(expr.right, inside_arithmetic: true)
			}, expr)
		}
		else {
			panic('unimplemented')
		}
	}
}

fn (mut e Emitter) infix_expr_for_string(expr ast.InfixExpr, opt ExprOpt) {
	if expr.left.typ() != builtin_type(.string) {
		panic(unreachable('not a string operand'))
	}

	e.write_echo_if_command(opt)

	match expr.op.kind {
		.eq, .ne {
			e.sh_test_command_for_expr(fn (mut e Emitter, expr ast.InfixExpr) {
				op := if expr.op.kind == .eq { ' = ' } else { ' != ' }
				e.sh_test_cond_infix(expr.left, op, expr.right)
			}, expr, opt)
		}
		.plus {
			e.write_inline_block({ open: '\$( ', close: ' )' }, fn (mut e Emitter, expr ast.InfixExpr) {
				e.write("printf '%s%s' ")
				e.expr(expr.left, {})
				e.write(' ')
				e.expr(expr.right, {})
			}, expr)
		}
		else {
			panic('unimplemented')
		}
	}
}

fn (mut e Emitter) paren_expr(expr ast.ParenExpr, opt ExprOpt) {
	e.write_echo_if_command(opt)
	open, close := if opt.inside_arithmetic { ' ( ', ' ) ' } else { '', '' }
	e.write_inline_block({ open: open, close: close }, fn (mut e Emitter, v ExprWithOpt<ast.ParenExpr>) {
		for i, expr in v.expr.exprs {
			if i > 0 {
				e.write(' ')
			}
			e.expr(expr, { ...v.opt, as_command: false })
		}
	}, expr_with_opt(expr, opt))
}

fn (mut e Emitter) prefix_expr(expr ast.PrefixExpr, opt ExprOpt) {
	op := expr.op
	if !op.kind.@is(.prefix_op) {
		panic(unreachable('not a prefix op'))
	}

	e.write_echo_if_command(opt)
	opt_for_expr := ExprOpt{
		...opt
		as_command: false
	}
	match op.kind {
		.plus {
			e.expr(expr.expr, opt_for_expr)
		}
		.minus {
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
					kind: .mul
					text: '*'
				}
			}, opt_for_expr)
		}
		.amp {
			e.reference(expr.expr)
		}
		.not {
			e.write('! { ')
			e.expr(expr.expr, as_condition: true)
			e.write(' ; }')
		}
		else {
			panic('unimplemented')
		}
	}
}

fn (mut e Emitter) pipeline(expr ast.Pipeline, opt ExprOpt) {
	open, close := if opt.as_command { '', '' } else { '\$(', ')' }
	e.write_inline_block({ open: open, close: close }, fn (mut e Emitter, pipeline ast.Pipeline) {
		for i, expr in pipeline.exprs {
			if i > 0 {
				e.write(' | ')
			}
			e.expr(expr, as_command: true)
		}
	}, expr)
}
