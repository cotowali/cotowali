module ast

import cotowari.pos { Pos }
import cotowari.token { Token }
import cotowari.symbols { Scope, Var }
import cotowari.errors

pub struct File {
pub:
	path string
pub mut:
	stmts  []Stmt
	scope  &Scope
	errors []errors.Error
}

pub type Stmt = AssignStmt | EmptyStmt | Expr | FnDecl

pub struct EmptyStmt {}

pub struct FnDecl {
pub:
	pos  Pos
	name string
pub mut:
	scope  &Scope
	params []Var
	stmts  []Stmt
}

pub struct AssignStmt {
pub:
	pos   Pos
	left  Var
	right Expr
}

pub struct InfixExpr {
pub:
	pos   Pos
	op    Token
	left  Expr
	right Expr
}

// expr | expr | expr
pub struct Pipeline {
pub:
	pos   Pos
	exprs []Expr
}

pub type Expr = CallFn | InfixExpr | IntLiteral | Pipeline | Var

pub struct CallFn {
pub:
	pos Pos
pub mut:
	func Var
	args []Expr
}

pub struct IntLiteral {
pub:
	pos   Pos
	token Token
}
