module ast

import cotowari.source { Pos }
import cotowari.token { Token }
import cotowari.symbols { ArrayTypeInfo, FunctionTypeInfo, Scope, Type, TypeSymbol, builtin_fn_id, builtin_type }

pub type Expr = ArrayLiteral | AsExpr | CallFn | IndexExpr | InfixExpr | IntLiteral |
	ParenExpr | Pipeline | PrefixExpr | StringLiteral | Var

fn (mut r Resolver) expr(expr Expr) {}

pub fn (e InfixExpr) pos() Pos {
	return e.left.pos().merge(e.right.pos())
}

pub fn (expr Expr) pos() Pos {
	return match expr {
		ArrayLiteral, AsExpr, CallFn, Var, ParenExpr, IndexExpr { expr.pos }
		InfixExpr { expr.pos() }
		Pipeline { expr.exprs.first().pos().merge(expr.exprs.last().pos()) }
		PrefixExpr { expr.op.pos.merge(expr.expr.pos()) }
		StringLiteral, IntLiteral { expr.token.pos }
	}
}

pub fn (e InfixExpr) typ() Type {
	return if e.op.kind.@is(.comparsion_op) { builtin_type(.bool) } else { e.right.typ() }
}

pub fn (e IndexExpr) typ() Type {
	left_info := e.left.type_symbol().info
	return match left_info {
		ArrayTypeInfo { left_info.elem }
		else { builtin_type(.unknown) }
	}
}

pub fn (e Expr) typ() Type {
	return match e {
		ArrayLiteral { e.scope.must_lookup_array_type(elem: e.elem_typ).typ }
		AsExpr { e.typ }
		CallFn { e.typ }
		StringLiteral { builtin_type(.string) }
		IntLiteral { builtin_type(.int) }
		ParenExpr { e.expr.typ() }
		Pipeline { e.exprs.last().typ() }
		PrefixExpr { e.expr.typ() }
		InfixExpr { e.typ() }
		IndexExpr { e.typ() }
		Var { e.sym.typ }
	}
}

[inline]
pub fn (v Var) type_symbol() TypeSymbol {
	return v.sym.type_symbol()
}

pub fn (e Expr) type_symbol() TypeSymbol {
	return match e {
		Var { e.type_symbol() }
		else { e.scope().must_lookup_type(e.typ()) }
	}
}

pub fn (e Expr) scope() &Scope {
	return match e {
		AsExpr, ParenExpr { e.expr.scope() }
		IndexExpr { e.left.scope() }
		ArrayLiteral, CallFn, InfixExpr, IntLiteral, Pipeline, PrefixExpr, StringLiteral, Var { e.scope }
	}
}

pub struct AsExpr {
pub:
	pos  Pos
	expr Expr
	typ  Type
}

pub struct CallFn {
mut:
	typ Type
pub:
	scope &Scope
	pos   Pos
pub mut:
	func_id u64
	func    Expr
	args    []Expr
}

pub fn (mut e CallFn) resolve_func() ?&symbols.Var {
	match e.func {
		Var {
			mut func := &(e.func as Var)
			name := func.name()
			sym := e.scope.lookup_var(name) or { return error('function `$name` is not defined') }
			func.sym = sym

			ts := sym.type_symbol()
			if !sym.is_function() {
				return error('`$sym.name` is not function (`$ts.name`)')
			}

			fn_info := ts.fn_info()
			e.typ = fn_info.ret
			e.func_id = sym.id
			if owner := e.scope.owner() {
				if sym.id == builtin_fn_id(.read) {
					e.typ = owner.type_symbol().fn_info().pipe_in
				}
			}
			return sym
		}
		else {
			return error('cannot call `$e.func.type_symbol().name`')
		}
	}
}

pub fn (e CallFn) fn_info() FunctionTypeInfo {
	return e.func.type_symbol().fn_info()
}

pub struct InfixExpr {
pub:
	scope &Scope
	op    Token
pub mut:
	left  Expr
	right Expr
}

pub struct IndexExpr {
pub:
	pos   Pos
	left  Expr
	index Expr
}

pub struct ParenExpr {
pub:
	pos Pos
pub mut:
	expr Expr
}

pub struct StringLiteral {
pub:
	scope &Scope
	token Token
}

pub struct IntLiteral {
pub:
	scope &Scope
	token Token
}

pub struct ArrayLiteral {
pub:
	pos      Pos
	scope    &Scope
	elem_typ Type
pub mut:
	elements []Expr
}

// expr | expr | expr
pub struct Pipeline {
pub:
	scope &Scope
pub mut:
	exprs []Expr
}

pub struct PrefixExpr {
pub:
	scope &Scope
	op    Token
pub mut:
	expr Expr
}

pub struct Var {
pub:
	scope &Scope
	pos   Pos
pub mut:
	sym &symbols.Var
}

pub fn (mut v Var) set_typ(typ Type) {
	v.sym.typ = typ
}

pub fn (v Var) name() string {
	return v.sym.name
}
