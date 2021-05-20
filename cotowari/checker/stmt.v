module checker

import cotowari.ast
import cotowari.symbols { builtin_type }

fn (mut c Checker) stmts(stmts []ast.Stmt) {
	for stmt in stmts {
		c.stmt(stmt)
	}
}

fn (mut c Checker) stmt(stmt ast.Stmt) {
	match mut stmt {
		ast.AssignStmt {}
		ast.AssertStmt {}
		ast.Block { c.block(stmt) }
		ast.Expr { c.expr(stmt) }
		ast.EmptyStmt {}
		ast.FnDecl { c.fn_decl(stmt) }
		ast.ForInStmt {}
		ast.IfStmt { c.if_stmt(stmt) }
		ast.InlineShell {}
		ast.ReturnStmt {}
	}
}

fn (mut c Checker) block(block ast.Block) {
	c.stmts(block.stmts)
}

fn (mut c Checker) fn_decl(stmt ast.FnDecl) {
	c.block(stmt.body)
}

fn (mut c Checker) if_stmt(stmt ast.IfStmt) {
	for i, branch in stmt.branches {
		if i == stmt.branches.len - 1 && stmt.has_else {
			c.block(branch.body)
			break
		}
		cond_type := branch.cond.typ()
		if cond_type != builtin_type(.bool) {
			c.error('non-bool type used as if condition', branch.cond.pos())
		}
		c.block(branch.body)
	}
}
