module sh

import cotowari.ast

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

fn (mut emit Emitter) fn_decl(node ast.FnDecl) {
	if !node.has_body {
		emit.writeln('')
		// emit.writeln('# info: fn ${node.name}(${node.params.map('$it.sym.name $it.sym.typ.name').join(', ')})')
		emit.writeln('# info: fn ${node.name}(${node.params.map('$it.sym.name').join(', ')})')
		emit.writeln('')
		return
	}

	old_inside_fn := emit.inside_fn
	emit.inside_fn = true
	old_cur_fn := emit.cur_fn
	emit.cur_fn = node
	defer {
		emit.inside_fn = old_inside_fn
		emit.cur_fn = old_cur_fn
	}

	emit.write_block('${node.name}() {', '}', fn (mut emit Emitter, node ast.FnDecl) {
		for i, param in node.params {
			emit.assign(param.out_name(), '\$${i + 1}', param.type_symbol())
		}
		emit.block(node.body)
	}, node)
}
