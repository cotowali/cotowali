module ast

import vash.pos { Pos }
import vash.token { Token }

pub struct File {
pub:
	path string
pub mut:
	stmts  []Stmt
	errors []ErrorNode
}

pub type Stmt = FnDecl | Expr

pub struct FnDecl {
pub:
	pos  Pos
	name string
pub mut:
	stmts []Stmt
}

// expr | expr | expr
pub struct Pipeline {
pub:
	pos   Pos
	exprs []Expr
}

pub type Expr = Pipeline | CallFn | IntLiteral

pub struct CallFn {
pub:
	pos  Pos
	name string
	args []Expr
}

pub struct IntLiteral {
pub:
	pos   Pos
	token Token
}

pub struct ErrorNode {
pub:
	pos Pos
	// Implements IError
	msg  string
	code int
}
