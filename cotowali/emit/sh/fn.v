// Copyright (c) 2021 zakuro <z@kuro.red>. All rights reserved.
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
module sh

import cotowali.ast { CallCommandExpr, CallExpr, FnDecl }
import cotowali.messages { unreachable }

fn (mut e Emitter) call_command_expr(expr CallCommandExpr, opt ExprOpt) {
	if opt.mode != .command {
		if opt.mode != .inside_arithmetic && opt.quote {
			e.write('"\$(')
			defer {
				e.write(')"')
			}
		} else {
			e.write('\$(')
			defer {
				e.write(')')
			}
		}
	}

	e.write('$expr.command')
	for arg in expr.args {
		e.write(' ')
		if arg is ast.StringLiteral {
			if arg.is_glob() {
				e.string_literal_value(arg)
				continue
			}
		}
		e.expr(arg)
	}
}

fn (mut e Emitter) call_expr(expr CallExpr, opt ExprOpt) {
	if expr.is_builtin_function_call(.read) {
		e.write('read')
		for arg in expr.args {
			e.write(' ')
			e.reference(arg)
		}
		if opt.mode !in [.command, .condition] {
			e.sh_result_to_bool()
		}
		return
	}

	if opt.mode != .command {
		if opt.mode != .inside_arithmetic && opt.quote {
			e.write('"\$(')
			defer {
				e.write(')"')
			}
		} else {
			e.write('\$(')
			defer {
				e.write(')')
			}
		}
	}

	fn_info := expr.function_info()

	e.write(e.ident_for(expr.func))
	if receiver := expr.receiver() {
		e.write(' ')
		e.expr(receiver)
	}
	mut args := expr.args
	for i, arg in args {
		e.write(' ')

		if arg is ast.StringLiteral {
			if arg.is_glob() && fn_info.variadic && i >= fn_info.params.len - 1 {
				e.string_literal_value(arg as ast.StringLiteral)
				continue
			}
		}
		e.expr(arg)
	}
}

fn (mut e Emitter) fn_decl(node FnDecl) {
	if !node.has_body {
		e.writeln('')
		params_str := node.params.map('$it.ident.text').join(', ')
		e.writeln('# info: fn ${e.ident_for(node)}($params_str)')
		e.writeln('')
		return
	}

	old_inside_fn := e.inside_fn
	e.inside_fn = true
	old_cur_fn := e.cur_fn
	e.cur_fn = node
	defer {
		e.inside_fn = old_inside_fn
		e.cur_fn = old_cur_fn
	}

	fn_ident := e.ident_for(node)

	if node.is_test() {
		if !e.ctx.config.is_test {
			return
		}
		defer {
			e.stmt(ast.Expr(node.get_run_test_call_expr()))
		}
	}

	e.sh_define_function(fn_ident, fn (mut e Emitter, node FnDecl) {
		for i, param in node.params {
			value := if i == node.params.len - 1 && node.function_info().variadic {
				name := e.new_tmp_ident()
				e.writeln('array_assign "$name" "\$@"')
				name
			} else {
				'\$1'
			}
			e.assign(e.ident_for(param), value, ast.Expr(param).type_symbol())
			if i < node.params.len - 1 {
				e.writeln('shift')
			}
		}

		if pipe_in_param := node.pipe_in_param() {
			pipe_in_param_ts := ast.Expr(pipe_in_param).type_symbol()
			tmp_to_read := e.new_tmp_ident()
			pipe_in_param_ident := e.ident_for(pipe_in_param)
			if _ := pipe_in_param_ts.sequence_info() {
				panic(unreachable('pipe in param cannot be sequence'))
			}
			e.writeln('read $tmp_to_read')
			e.assign(pipe_in_param_ident, '\$$tmp_to_read', pipe_in_param_ts)
		}
		e.block(node.body)
	}, node)
}

fn (mut e Emitter) nameof(expr ast.Nameof, opt ExprOpt) {
	e.write_echo_if_command_then_write("'$expr.value()'", opt)
}

fn (mut e Emitter) typeof_(expr ast.Typeof, opt ExprOpt) {
	e.write_echo_if_command_then_write("'$expr.value()'", opt)
}
