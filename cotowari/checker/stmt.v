module checker

import cotowari.ast
import cotowari.symbols { builtin_type }

fn (mut c Checker) stmts(stmts []ast.Stmt) {
	for stmt in stmts {
		c.stmt(stmt)
	}
}

fn (mut c Checker) stmt(stmt ast.Stmt) {
	match stmt {
		ast.AssignStmt {}
		ast.AssertStmt {}
		ast.Block {}
		ast.Expr { c.expr(stmt) }
		ast.EmptyStmt {}
		ast.FnDecl {}
		ast.ForInStmt {}
		ast.IfStmt { c.if_stmt(stmt) }
		ast.InlineShell {}
		ast.ReturnStmt {}
	}
}

fn (mut c Checker) if_stmt(stmt ast.IfStmt) {
	for i, branch in stmt.branches {
		if i == stmt.branches.len - 1 && stmt.has_else {
			break
		}
		cond_type := branch.cond.typ()
		if cond_type != builtin_type(.bool) {
			c.error('non-bool type used as if condition', branch.cond.pos())
		}
	}
}
