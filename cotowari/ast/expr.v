module ast

import cotowari.source { Pos }
import cotowari.token { Token }
import cotowari.symbols { Scope, Type, TypeSymbol, builtin_type }
import cotowari.errors { unreachable }

pub type Expr = CallFn | InfixExpr | Literal | Pipeline | PrefixExpr | Var

pub fn (expr Expr) pos() Pos {
	return match expr {
		CallFn, Var { expr.pos }
		InfixExpr { expr.left.pos().merge(expr.right.pos()) }
		Pipeline { expr.exprs.first().pos().merge(expr.exprs.last().pos()) }
		PrefixExpr { expr.op.pos.merge(expr.expr.pos()) }
		Literal { expr.token.pos }
	}
}

fn (node Literal) typ() Type {
	return match node.kind {
		.string { builtin_type(.string) }
		.int { builtin_type(.int) }
	}
}

fn (e InfixExpr) typ() Type {
	return if e.op.kind.@is(.comparsion_op) { builtin_type(.bool) } else { e.right.typ() }
}

pub fn (e Expr) typ() Type {
	return match e {
		Literal { e.typ() }
		Pipeline { e.exprs.last().typ() }
		PrefixExpr { e.expr.typ() }
		InfixExpr { e.typ() }
		CallFn { Expr(e.func).typ() }
		Var { e.sym.typ }
	}
}

pub fn (e Expr) type_symbol() TypeSymbol {
	return e.scope().lookup_type(e.typ()) or { panic(unreachable) }
}

pub fn (e Expr) scope() &Scope {
	return e.scope
}

pub struct CallFn {
pub:
	scope &Scope
	pos   Pos
pub mut:
	func Var
	args []Expr
}

pub struct InfixExpr {
pub:
	scope &Scope
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
	scope &Scope
	kind  LiteralKind
	token Token
}

// expr | expr | expr
pub struct Pipeline {
pub:
	scope &Scope
	exprs []Expr
}

pub struct PrefixExpr {
pub:
	scope &Scope
	op    Token
	expr  Expr
}

pub struct Var {
pub:
	scope &Scope
	pos   Pos
	sym   symbols.Var
}

pub fn (v Var) name() string {
	return v.sym.name
}

pub fn (v Var) out_name() string {
	return v.sym.full_name()
}
