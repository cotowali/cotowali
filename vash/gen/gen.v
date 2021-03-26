module gen

import vash.ast { Pipeline, Stmt }

pub fn (mut g Gen) gen(f ast.File) {
	g.file(f)
}

fn (mut g Gen) file(f ast.File) {
	g.writeln('# file: $f.path')
	g.stmts(f.stmts)
}

fn (mut g Gen) stmts(stmts []Stmt) {
	for stmt in stmts {
		g.stmt(stmt)
	}
}

fn (mut g Gen) stmt(stmt Stmt) {
	match stmt {
		ast.FnDecl {
			g.fn_decl(stmt)
		}
		ast.Expr {
			g.expr(stmt, as_command: true)
			g.writeln('')
		}
		ast.EmptyStmt {
			g.writeln('')
		}
	}
}

struct ExprOpt {
	as_command bool
}

fn (mut g Gen) expr(expr ast.Expr, opt ExprOpt) {
	match expr {
		ast.CallFn {
			g.call_fn(expr, opt)
		}
		ast.Pipeline {
			g.pipeline(expr, opt)
		}
		ast.InfixExpr {
			g.infix_expr(expr, opt)
		}
		ast.IntLiteral {
			if opt.as_command {
				g.write('echo ')
			}
			g.write(expr.token.text)
		}
	}
}

fn (mut g Gen) infix_expr(expr ast.InfixExpr, opt ExprOpt) {
	op := expr.op
	match op.kind {
		.op_plus, .op_minus, .op_div, .op_mul {
			if opt.as_command {
				g.write('echo ')
			}
			g.write('\$(( (')
			g.expr(expr.left, {})
			g.write(' $op.text ')
			g.expr(expr.right, {})
			g.write(') ))')
		}
		else {
			panic('unimplemented')
		}
	}
}

fn (mut g Gen) pipeline(stmt Pipeline, opt ExprOpt) {
	if !opt.as_command {
		g.write('\$(')
	}

	for i, expr in stmt.exprs {
		if i > 0 {
			g.write(' | ')
		}
		g.expr(expr, as_command: true)
	}
	g.writeln('')

	if !opt.as_command {
		g.write(')')
	}
}

fn (mut g Gen) call_fn(expr ast.CallFn, opt ExprOpt) {
	if !opt.as_command {
		g.write('\$(')
	}

	g.write(expr.name)
	for arg in expr.args {
		g.write(' ')
		g.expr(arg, {})
	}

	if !opt.as_command {
		g.write(')')
	}
}

fn (mut g Gen) fn_decl(node ast.FnDecl) {
	g.writeln('${node.name}() {')
	g.indent++
	for i, param in node.params {
		g.writeln('${param.full_name()}=\$${i + 1}')
	}
	g.stmts(node.stmts)
	g.indent--
	g.writeln('}')
}
