module gen

import io
import vash.ast { Stmt, FnDecl, Pipeline }

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

fn (mut g Gen) stmts(stmts []ast.Stmt){
	for stmt in stmts {
		g.stmt(stmt)
	}
}

fn (mut g Gen) stmt(stmt ast.Stmt) {
	match stmt {
		FnDecl { panic('not implemented') }
		Pipeline { g.pipeline(stmt) }
	}
}

fn (mut g Gen) pipeline(stmt ast.Pipeline) {
	for i, command in stmt.commands {
		if i > 0 {
			g.write(' | ')
		}
		g.command(command)
	}
	g.writeln('')
}

fn (mut g Gen) command(cmd ast.Command) {
	g.expr(cmd.expr)
}

fn (mut g Gen) expr(expr ast.Expr) {
	match expr {
		ast.CallExpr { g.call_expr(expr) }
		ast.IntLiteral { g.write(expr.token.text) }
		ast.ErrorNode { panic('error node') }
	}
}

fn (mut g Gen) call_expr(expr ast.CallExpr) {
	g.write(expr.name)
	for arg in expr.args {
		g.write(' ')
		g.expr(arg)
	}
}
