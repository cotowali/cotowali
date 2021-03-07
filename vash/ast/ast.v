module ast

import vash.pos { Pos }

pub struct File {
pub:
	path string
}

type Stmt = FnDecl | Pipeline

pub struct FnDecl {
	pos Pos
	name string
}

pub struct Pipeline {
	pos Pos
	commands []Command
}

pub struct Command {
	pos Pos
	expr Expr
	redirects []Redirect
}

pub struct Redirect {
	pos Pos
}

type Expr = CallExpr | IntLiteral

pub struct CallExpr {
	pos Pos
	name string
	args []Expr
}

pub struct IntLiteral {
	pos Pos
	value int
}
