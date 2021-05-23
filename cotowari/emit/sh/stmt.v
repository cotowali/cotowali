module sh

import cotowari.ast { Stmt }
import cotowari.symbols { TypeSymbol, builtin_type }

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
			discard_stdout := emit.inside_fn
				&& if stmt is ast.CallFn { emit.cur_fn.ret_typ != builtin_type(.void) } else { true }
			emit.expr(stmt, as_command: true, discard_stdout: discard_stdout, writeln: true)
		}
		ast.AssignStmt {
			emit.assign_stmt(stmt)
		}
		ast.EmptyStmt {
			emit.code.writeln('')
		}
		ast.ForInStmt {
			emit.for_in_stmt(stmt)
		}
		ast.IfStmt {
			emit.if_stmt(stmt)
		}
		ast.InlineShell {
			emit.code.writeln(stmt.text)
		}
		ast.ReturnStmt {
			emit.expr(stmt.expr, as_command: true, writeln: true)
			emit.code.writeln('return 0')
		}
	}
}

fn (mut emit Emitter) assert_stmt(stmt ast.AssertStmt) {
	emit.code.write('if falsy ')
	emit.expr(stmt.expr, as_command: false, writeln: true)

	emit.write_block('then', 'fi', fn (mut emit Emitter, stmt ast.AssertStmt) {
		emit.code.writeln("echo 'LINE $stmt.key_pos.line: assertion failed' >&2")
		emit.code.writeln('exit 1')
	}, stmt)
}

fn (mut emit Emitter) block(block ast.Block) {
	emit.stmts(block.stmts)
}

fn (mut emit Emitter) if_stmt(stmt ast.IfStmt) {
	for i, branch in stmt.branches {
		mut is_else := i == stmt.branches.len - 1 && stmt.has_else
		if is_else {
			emit.code.writeln('else')
		} else {
			emit.code.write(if i == 0 { 'if ' } else { 'elif ' })
			emit.code.write('truthy ')
			emit.expr(branch.cond, as_command: false, writeln: true)
			emit.code.writeln('then')
		}
		emit.indent()
		emit.block(branch.body)
		emit.unindent()
	}
	emit.code.writeln('fi')
}

fn (mut emit Emitter) for_in_stmt(stmt ast.ForInStmt) {
	emit.code.write('for $stmt.val.out_name() in ')
	emit.expr(stmt.expr, writeln: true)
	emit.write_block('do', 'done', fn (mut e Emitter, stmt ast.ForInStmt) {
		e.block(stmt.body)
	}, stmt)
}

type AssignValue = ast.Expr | string

fn (mut emit Emitter) assign(name string, value AssignValue, ts TypeSymbol) {
	if ts.kind() == .array {
		match value {
			ast.Expr {
				match value {
					ast.ArrayLiteral {
						emit.code.write('array_assign "$name"')
						for elem in value.elements {
							emit.code.write(' ')
							emit.expr(elem, as_command: false)
						}
						emit.code.writeln('')
					}
					ast.Var {
						emit.assign(name, value.out_name(), ts)
					}
					else {}
				}
			}
			string {
				emit.code.writeln('array_assign "$name" \$(array_elements "$value")')
			}
		}
		return
	}
	match value {
		string {
			emit.code.writeln('$name="$value"')
		}
		ast.Expr {
			emit.code.write('$name=')
			emit.expr(value, {})
			emit.code.writeln('')
		}
	}
}

fn (mut emit Emitter) assign_stmt(node ast.AssignStmt) {
	emit.assign(node.left.out_name(), node.right, node.left.type_symbol())
}
