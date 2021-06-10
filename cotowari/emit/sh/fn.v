module sh

import cotowari.ast { CallFn, FnDecl }

fn (mut e Emitter) call_fn(expr CallFn, opt ExprOpt) {
	if !opt.as_command {
		e.write('\$(')
	}

	fn_info := expr.fn_info()
	e.write(e.ident_for(expr.func))
	mut args := expr.args
	if fn_info.is_varargs {
		args = expr.args[..fn_info.params.len - 1]
	}
	for arg in args {
		e.write(' ')
		e.expr(arg, {})
	}
	if fn_info.is_varargs {
		e.write(' ')
		e.array_literal({
			scope: expr.scope
			elem_typ: fn_info.varargs_elem
			elements: expr.args[fn_info.params.len - 1..]
		}, {})
	}

	if !opt.as_command {
		e.write(')')
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

	e.write_block({ open: '${node.name}() {', close: '}' }, fn (mut e Emitter, node FnDecl) {
		for i, param in node.params {
			e.assign(e.ident_for(param), '\$${i + 1}', param.type_symbol())
		}
		e.block(node.body)
	}, node)
}
