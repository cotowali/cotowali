module ast

import cotowari.source { Pos }
import cotowari.symbols { Scope }
import cotowari.token { Token }

pub type Stmt = AssertStmt | AssignStmt | Block | EmptyStmt | Expr | FnDecl | ForInStmt |
	IfStmt | InlineShell | ReturnStmt

pub struct AssignStmt {
pub:
	left  Var
	right Expr
}

pub struct AssertStmt {
pub:
	key_pos Pos
	expr    Expr
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
pub mut:
	params []Var
	body   Block
}

pub struct ForInStmt {
pub:
	// for var in expr
	val  Var
	expr Expr
pub mut:
	body Block
}

pub struct IfBranch {
pub:
	cond Expr
	body Block
}

pub struct IfStmt {
pub:
	branches []IfBranch
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
