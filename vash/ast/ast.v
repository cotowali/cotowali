module ast

import vash.pos { Pos }

pub struct File {
pub:
	path string
	stmts []Stmt
}

type Stmt = FnDecl | Pipeline

pub struct FnDecl {
pub:
	pos  Pos
	name string
}

pub struct Pipeline {
pub:
	pos      Pos
	commands []Command
}

pub struct Command {
pub:
	pos       Pos
	expr      Expr
	redirects []Redirect
}

pub struct Redirect {
pub:
	pos Pos
}

type Expr = CallExpr | IntLiteral

pub struct CallExpr {
pub:
	pos  Pos
	name string
	args []Expr
}

pub struct IntLiteral {
pub:
	pos   Pos
	value int
}
