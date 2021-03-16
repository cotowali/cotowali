module gen

import io
import vash.ast { Pipeline, Stmt }

pub struct Gen {
pub:
	out io.Writer
}

[inline]
pub fn new(out io.Writer) Gen {
	return Gen{
		out: out
	}
}

pub fn (mut g Gen) write(s string) {
	g.out.write(s.bytes()) or { panic(err) }
}

pub fn (mut g Gen) writeln(s string) {
	g.write(s + '\n')
}

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
		ast.FnDecl { panic('not implemented') }
		ast.Pipeline { g.pipeline(stmt) }
	}
}

fn (mut g Gen) pipeline(stmt Pipeline) {
	for i, expr in stmt.exprs {
		if i > 0 {
			g.write(' | ')
		}
		if expr is ast.CallFn {
			g.call_fn(expr)
		} else {
			g.write('echo ')
			g.expr(expr)
		}
	}
	g.writeln('')
}

fn (mut g Gen) expr(expr ast.Expr) {
	match expr {
		ast.CallFn {
			g.write('\$(')
			g.call_fn(expr)
			g.write(')')
		}
		ast.IntLiteral {
			g.write(expr.token.text)
		}
		ast.ErrorNode {
			panic('error node')
		}
	}
}

fn (mut g Gen) call_fn(expr ast.CallFn) {
	g.write(expr.name)
	for arg in expr.args {
		g.write(' ')
		g.expr(arg)
	}
}
