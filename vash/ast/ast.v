module ast

import vash.pos { Pos }
import vash.token { Token }
import vash.symbols { Scope, Var }
import vash.errors

pub struct File {
pub:
	path string
pub mut:
	stmts  []Stmt
	scope  &symbols.Scope
	errors []errors.Error
}

pub type Stmt = EmptyStmt | Expr | FnDecl

pub struct EmptyStmt {}

pub struct FnDecl {
pub:
	pos  Pos
	name string
pub mut:
	scope  &symbols.Scope
	params []Var
	stmts  []Stmt
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

pub type Expr = CallFn | InfixExpr | IntLiteral | Pipeline

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
