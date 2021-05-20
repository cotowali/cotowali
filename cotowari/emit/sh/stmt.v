module sh

import cotowari.ast { Stmt }

fn (mut emit Emitter) stmts(stmts []Stmt) {
	for stmt in stmts {
		emit.stmt(stmt)
	}
}

fn (mut emit Emitter) stmt(stmt Stmt) {
	match stmt {
		ast.AssertStmt {
			emit.assert_stmt(stmt)
		}
		ast.FnDecl {
			emit.fn_decl(stmt)
		}
		ast.Block {
			emit.block(stmt)
		}
		ast.Expr {
			// TODO: register builtin function to global scope then use it to compare.
			use_stdout := !emit.inside_fn
				|| if stmt is ast.CallFn { stmt.func.name() == 'echo' } else { false }
			emit.expr(stmt, as_command: true, discard_stdout: !use_stdout, writeln: true)
		}
		ast.AssignStmt {
			emit.assign(stmt)
		}
		ast.EmptyStmt {
			emit.writeln('')
		}
		ast.ForInStmt {
			emit.for_in_stmt(stmt)
		}
		ast.IfStmt {
			emit.if_stmt(stmt)
		}
		ast.InlineShell {
			emit.writeln(stmt.text)
		}
		ast.ReturnStmt {
			emit.expr(stmt.expr, as_command: true, writeln: true)
			emit.writeln('return 0')
		}
	}
}

fn (mut emit Emitter) assert_stmt(stmt ast.AssertStmt) {
	emit.write('if falsy ')
	emit.expr(stmt.expr, as_command: false, writeln: true)

	emit.write_block('then', 'fi', fn (mut emit Emitter, stmt ast.AssertStmt) {
		emit.writeln("echo 'LINE $stmt.key_pos.line: assertion failed' >&2")
		emit.writeln('exit 1')
	}, stmt)
}

fn (mut emit Emitter) block(block ast.Block) {
	emit.stmts(block.stmts)
}

fn (mut emit Emitter) if_stmt(stmt ast.IfStmt) {
	for i, branch in stmt.branches {
		mut is_else := i == stmt.branches.len - 1 && stmt.has_else
		if is_else {
			emit.writeln('else')
		} else {
			emit.write(if i == 0 { 'if ' } else { 'elif ' })
			emit.write('truthy ')
			emit.expr(branch.cond, as_command: false, writeln: true)
			emit.writeln('then')
		}
		emit.indent()
		emit.block(branch.body)
		emit.unindent()
	}
	emit.writeln('fi')
}

fn (mut emit Emitter) for_in_stmt(stmt ast.ForInStmt) {
	emit.write('for $stmt.val.out_name() in ')
	emit.expr(stmt.expr, writeln: true)
	emit.write_block('do', 'done', fn (mut e Emitter, stmt ast.ForInStmt) {
		e.block(stmt.body)
	}, stmt)
}

fn (mut emit Emitter) fn_decl(node ast.FnDecl) {
	if !node.has_body {
		emit.writeln('')
		// emit.writeln('# info: fn ${node.name}(${node.params.map('$it.sym.name $it.sym.typ.name').join(', ')})')
		emit.writeln('# info: fn ${node.name}(${node.params.map('$it.sym.name').join(', ')})')
		emit.writeln('')
		return
	}

	save_inside_fn := emit.inside_fn
	emit.inside_fn = true
	defer {
		emit.inside_fn = save_inside_fn
	}

	emit.write_block('${node.name}() {', '}', fn (mut emit Emitter, node ast.FnDecl) {
		for i, param in node.params {
			emit.writeln('$param.out_name()=\$${i + 1}')
		}
		emit.block(node.body)
	}, node)
}

fn (mut emit Emitter) assign(node ast.AssignStmt) {
	emit.write('$node.left.out_name()=')
	emit.expr(node.right, {})
	emit.writeln('')
}
