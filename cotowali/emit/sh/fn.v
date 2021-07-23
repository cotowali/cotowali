// Copyright (c) 2021 zakuro <z@kuro.red>. All rights reserved.
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
module sh

import cotowali.ast { CallCommandExpr, CallExpr, FnDecl }
import cotowali.symbols { builtin_fn_id }

fn (mut e Emitter) call_command_expr(expr CallCommandExpr, opt ExprOpt) {
	if !opt.as_command {
		e.write('\$(')
		defer {
			e.write(')')
		}
	}

	e.write('$expr.command')
	for arg in expr.args {
		e.write(' ')
		e.expr(arg, {})
	}
}

fn (mut e Emitter) call_expr(expr CallExpr, opt ExprOpt) {
	if expr.func_id == builtin_fn_id(.read) {
		e.write('read')
		for arg in expr.args {
			e.write(' ')
			e.reference(arg)
		}
		if !(opt.as_command || opt.as_condition) {
			e.sh_result_to_bool()
		}
		return
	}

	if !opt.as_command {
		e.write('\$(')
		defer {
			e.write(')')
		}
	}

	if expr.func_id == builtin_fn_id(.call) {
		e.expr(expr.args[0], {})
		for arg in expr.args[1..] {
			e.write(' ')
			e.expr(arg, {})
		}
		return
	}

	e.write(e.ident_for(expr.func))
	mut args := expr.args
	for arg in args {
		e.write(' ')
		e.expr(arg, {})
	}
}

fn (mut e Emitter) fn_decl(node FnDecl) {
	if !node.has_body {
		e.writeln('')
		params_str := node.params.map('$it.sym.name').join(', ')
		e.writeln('# info: fn ${node.name}($params_str)')
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

	e.writeln('${node.name}() {')
	{
		for i, param in node.params {
			value := if i == node.params.len - 1 && node.is_varargs() {
				name := e.new_tmp_ident()
				e.writeln('array_assign "$name" "\$@"')
				name
			} else {
				'\$1'
			}
			e.assign(e.ident_for(param), value, param.type_symbol())
			e.writeln('shift')
		}
		e.block(node.body)
	}
	e.writeln('}')
}
