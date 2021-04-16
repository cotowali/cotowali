module ast

import cotowari.source { Pos }
import cotowari.token { Token }
import cotowari.symbols { Type, int_type, string_type }

pub type Expr = CallFn | InfixExpr | Literal | Pipeline | Var

pub fn (expr Expr) pos() Pos {
	return match expr {
		CallFn, Var { expr.pos }
		InfixExpr { expr.left.pos().merge(expr.right.pos()) }
		Pipeline { expr.exprs.first().pos().merge(expr.exprs.last().pos()) }
		Literal { expr.token.pos }
	}
}

pub fn (e Expr) typ() &Type {
	return match e {
		Literal { e.typ() }
		Pipeline { e.exprs.last().typ() } // TODO
		InfixExpr { e.right.typ() } // TODO
		CallFn { Expr(e.func).typ() } // TODO
		Var { e.sym.typ }
	}
}

pub struct CallFn {
pub:
	pos Pos
pub mut:
	func Var
	args []Expr
}

pub struct InfixExpr {
pub:
	op    Token
	left  Expr
	right Expr
}

pub enum LiteralKind {
	string
	int
}

pub struct Literal {
pub:
	kind  LiteralKind
	token Token
}

pub fn (node Literal) typ() &Type {
	return match node.kind {
		.string { &string_type }
		.int { &int_type }
	}
}

// expr | expr | expr
pub struct Pipeline {
pub:
	exprs []Expr
}

pub struct Var {
pub:
	pos Pos
	sym symbols.Var
}
