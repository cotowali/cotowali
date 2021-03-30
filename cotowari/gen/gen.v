module gen

import cotowari.ast { Pipeline, Stmt }
import cotowari.symbols

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
		ast.Block {
			g.block(stmt)
		}
		ast.Expr {
			g.expr(stmt, as_command: true, writeln: true)
		}
		ast.AssignStmt {
			g.assign(stmt)
		}
		ast.EmptyStmt {
			g.writeln('')
		}
	}
}

fn (mut g Gen) block(block ast.Block) {
	g.stmts(block.stmts)
}

struct ExprOpt {
	as_command bool
	writeln bool
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
		symbols.Var {
			if opt.as_command {
				g.write('echo ')
			}
			g.write('"\$$expr.full_name()"')
		}
	}
	if opt.writeln {
		g.writeln('')
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

	g.write(expr.func.full_name())
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
		g.writeln('$param.full_name()=\$${i + 1}')
	}
	g.block(node.body)
	g.indent--
	g.writeln('}')
}

fn (mut g Gen) assign(node ast.AssignStmt) {
	g.write('$node.left.full_name()=')
	g.expr(node.right, {})
	g.writeln('')
}
