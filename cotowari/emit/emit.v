module emit

import cotowari.ast { Pipeline, Stmt }
import cotowari.symbols

pub fn (mut emit Emitter) gen(f ast.File) {
	emit.file(f)
}

fn (mut emit Emitter) file(f ast.File) {
	emit.builtin()
	emit.writeln('# file: $f.path')
	emit.stmts(f.stmts)
}

fn (mut emit Emitter) builtin() {
	f := $embed_file('../../builtin/builtin.sh')
	emit.writeln(f.to_string())
}

fn (mut emit Emitter) stmts(stmts []Stmt) {
	for stmt in stmts {
		emit.stmt(stmt)
	}
}

fn (mut emit Emitter) stmt(stmt Stmt) {
	match stmt {
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
		ast.ReturnStmt {
			emit.expr(stmt.expr, as_command: true, writeln: true)
			emit.writeln('return 0')
		}
	}
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
	emit.write('for $stmt.val.full_name() in ')
	emit.expr(stmt.expr, writeln: true)
	emit.writeln('do')
	emit.indent++
	emit.block(stmt.body)
	emit.indent--
	emit.writeln('done')
}

struct ExprOpt {
	as_command        bool
	writeln           bool
	inside_arithmetic bool
}

fn (mut emit Emitter) expr(expr ast.Expr, opt ExprOpt) {
	match expr {
		ast.CallFn {
			emit.call_fn(expr, opt)
		}
		ast.Pipeline {
			emit.pipeline(expr, opt)
		}
		ast.InfixExpr {
			emit.infix_expr(expr, opt)
		}
		ast.IntLiteral {
			if opt.as_command {
				emit.write('echo ')
			}
			emit.write(expr.token.text)
		}
		ast.StringLiteral {
			if opt.as_command {
				emit.write('echo ')
			}
			emit.write("'$expr.token.text'")
		}
		symbols.Var {
			if opt.as_command {
				emit.write('echo ')
			}
			// '$(( n == 0 ))' or 'echo "$n"'
			emit.write(if opt.inside_arithmetic {
				'$expr.full_name()'
			} else {
				'"\$$expr.full_name()"'
			})
		}
	}
	if opt.writeln {
		emit.writeln('')
	}
}

fn (mut emit Emitter) infix_expr(expr ast.InfixExpr, opt ExprOpt) {
	op := expr.op
	match op.kind {
		.op_plus, .op_minus, .op_div, .op_mul, .op_mod, .op_eq, .op_gt, .op_lt {
			if opt.as_command {
				emit.write('echo ')
			}
			if !opt.inside_arithmetic {
				emit.write('\$(( ( ')
			}
			emit.expr(expr.left, inside_arithmetic: true)
			emit.write(' $op.text ')
			emit.expr(expr.right, inside_arithmetic: true)
			if !opt.inside_arithmetic {
				emit.write(' ) ))')
			}
		}
		else {
			panic('unimplemented')
		}
	}
}

fn (mut emit Emitter) pipeline(stmt Pipeline, opt ExprOpt) {
	if !opt.as_command {
		emit.write('\$(')
	}

	for i, expr in stmt.exprs {
		if i > 0 {
			emit.write(' | ')
		}
		emit.expr(expr, as_command: true)
	}
	emit.writeln('')

	if !opt.as_command {
		emit.write(')')
	}
}

fn (mut emit Emitter) call_fn(expr ast.CallFn, opt ExprOpt) {
	if !opt.as_command {
		emit.write('\$(')
	}

	emit.write(expr.func.full_name())
	for arg in expr.args {
		emit.write(' ')
		emit.expr(arg, {})
	}

	if !opt.as_command {
		emit.write(')')
	}
}

fn (mut emit Emitter) fn_decl(node ast.FnDecl) {
	emit.writeln('${node.name}() {')
	emit.indent++
	for i, param in node.params {
		emit.writeln('$param.full_name()=\$${i + 1}')
	}
	emit.block(node.body)
	emit.indent--
	emit.writeln('}')
}

fn (mut emit Emitter) assign(node ast.AssignStmt) {
	emit.write('$node.left.full_name()=')
	emit.expr(node.right, {})
	emit.writeln('')
}
