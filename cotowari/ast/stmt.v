module ast

import cotowari.source { Pos }
import cotowari.symbols { Scope, Type }
import cotowari.token { Token }

pub type Stmt = AssertStmt | AssignStmt | Block | EmptyStmt | Expr | FnDecl | ForInStmt |
	IfStmt | InlineShell | ReturnStmt

pub struct AssignStmt {
pub mut:
	left  Var
	right Expr
}

pub struct AssertStmt {
pub:
	key_pos Pos
pub mut:
	expr Expr
}

pub struct Block {
pub:
	scope &Scope
pub mut:
	stmts []Stmt
}

pub struct EmptyStmt {}

pub struct FnDecl {
pub:
	name_pos Pos
	name     string
	has_body bool
	ret_typ  Type
pub mut:
	params []Var
	body   Block
}

pub struct ForInStmt {
pub mut:
	// for var in expr
	val  Var
	expr Expr
	body Block
}

pub struct IfBranch {
pub mut:
	cond Expr
pub:
	body Block
}

pub struct IfStmt {
pub mut:
	branches []IfBranch
pub:
	has_else bool
}

pub struct InlineShell {
pub:
	pos  Pos
	text string
}

pub struct ReturnStmt {
pub:
	token Token // key_return token
	expr  Expr
}
