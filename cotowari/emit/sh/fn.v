module sh

import cotowari.ast { CallExpr, FnDecl }
import cotowari.symbols { builtin_fn_id }

fn (mut e Emitter) call_expr(expr CallExpr, opt ExprOpt) {
	if !opt.as_command {
		e.write('\$(')
		defer {
			e.write(')')
		}
	}

	if expr.func_id == builtin_fn_id(.read) {
		e.write('read ')
		e.reference(expr.args[0])
		return
	}

	if expr.func_id == builtin_fn_id(.call) {
		e.expr(expr.args[0], {})
		for arg in expr.args[1..] {
			e.write(' ')
			e.expr(arg, {})
		}
		return
	}

	fn_info := expr.fn_info()
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

	e.write_block({ open: '${node.name}() {', close: '}' }, fn (mut e Emitter, node FnDecl) {
		fn_info := node.fn_info()
		for i, param in node.params {
			value := if i == node.params.len - 1 && node.is_varargs() {
				name := e.new_tmp_var()
				e.writeln('array_assign "$name" "\$@"')
				name
			} else {
				'\$1'
			}
			e.assign(e.ident_for(param), value, param.type_symbol())
			e.writeln('shift')
		}
		e.block(node.body)
	}, node)
}
