module emit

import cotowari.ast { Stmt }
import cotowari.token

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
			emit.expr(stmt, as_command: true, writeln: true)
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
	emit.writeln('then')
	emit.indent++
	emit.writeln("echo 'LINE $stmt.key_pos.line: assertion failed' >&2")
	emit.writeln('exit 1')
	emit.indent--
	emit.writeln('fi')
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
		emit.indent++
		emit.block(branch.body)
		emit.indent--
	}
	emit.writeln('fi')
}

fn (mut emit Emitter) for_in_stmt(stmt ast.ForInStmt) {
	emit.write('for $stmt.val.sym.full_name() in ')
	emit.expr(stmt.expr, writeln: true)
	emit.writeln('do')
	emit.indent++
	emit.block(stmt.body)
	emit.indent--
	emit.writeln('done')
}

fn (mut emit Emitter) fn_decl(node ast.FnDecl) {
	emit.writeln('${node.name}() {')
	emit.indent++
	for i, param in node.params {
		emit.writeln('$param.sym.full_name()=\$${i + 1}')
	}
	emit.block(node.body)
	emit.indent--
	emit.writeln('}')
}

fn (mut emit Emitter) assign(node ast.AssignStmt) {
	emit.write('$node.left.sym.full_name()=')
	emit.expr(node.right, {})
	emit.writeln('')
}
