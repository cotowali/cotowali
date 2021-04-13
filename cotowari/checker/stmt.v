module checker

import cotowari.ast

fn (c Checker) stmt(stmt ast.Stmt) {
	match stmt {
		ast.AssignStmt {}
		ast.Block {}
		ast.Expr { c.expr(stmt) }
		ast.EmptyStmt {}
		ast.FnDecl {}
		ast.ForInStmt {}
		ast.IfStmt {}
		ast.InlineShell {}
		ast.ReturnStmt {}
	}
}
