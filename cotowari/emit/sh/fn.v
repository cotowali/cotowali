module sh

import cotowari.ast

fn (mut e Emitter) call_fn(expr ast.CallFn, opt ExprOpt) {
	if !opt.as_command {
		e.code.write('\$(')
	}

	e.code.write(expr.func.out_name())
	for arg in expr.args {
		e.code.write(' ')
		e.expr(arg, {})
	}

	if !opt.as_command {
		e.code.write(')')
	}
}

fn (mut e Emitter) fn_decl(node ast.FnDecl) {
	if !node.has_body {
		e.code.writeln('')
		// e.code.writeln('# info: fn ${node.name}(${node.params.map('$it.sym.name $it.sym.typ.name').join(', ')})')
		e.code.writeln('# info: fn ${node.name}(${node.params.map('$it.sym.name').join(', ')})')
		e.code.writeln('')
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

	e.write_block('${node.name}() {', '}', fn (mut e Emitter, node ast.FnDecl) {
		for i, param in node.params {
			e.assign(param.out_name(), '\$${i + 1}', param.type_symbol())
		}
		e.block(node.body)
	}, node)
}
