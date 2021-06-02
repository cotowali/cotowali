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
		ast.AssignStmt { c.assign_stmt(mut stmt) }
		ast.AssertStmt {}
		ast.Block { c.block(stmt) }
		ast.Expr { c.expr(stmt) }
		ast.EmptyStmt {}
		ast.FnDecl { c.fn_decl(stmt) }
		ast.ForInStmt { c.for_in_stmt(mut stmt) }
		ast.IfStmt { c.if_stmt(stmt) }
		ast.InlineShell {}
		ast.ReturnStmt { c.return_stmt(stmt) }
	}
}

fn (mut c Checker) assign_stmt(mut stmt ast.AssignStmt) {
	c.expr(stmt.right)
	stmt.left.set_typ(stmt.right.typ())
}

fn (mut c Checker) block(block ast.Block) {
	c.stmts(block.stmts)
}

fn (mut c Checker) fn_decl(stmt ast.FnDecl) {
	old_fn := c.cur_fn
	c.cur_fn = stmt
	defer {
		c.cur_fn = old_fn
	}

	c.block(stmt.body)
}

fn (mut c Checker) for_in_stmt(mut stmt ast.ForInStmt) {
	c.expr(stmt.expr)
	ts := stmt.expr.type_symbol()
	if ts.kind() != .array {
		c.error('non-array type `$ts.name` is not iterable', stmt.expr.pos())
	}
	stmt.val.set_typ((ts.info as symbols.ArrayTypeInfo).elem)
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

fn (mut c Checker) return_stmt(stmt ast.ReturnStmt) {
	c.expr(stmt.expr)
	c.check_types(
		want: c.cur_fn.ret_type_symbol()
		got: stmt.expr.type_symbol()
		pos: stmt.expr.pos()
	) or {}
}
