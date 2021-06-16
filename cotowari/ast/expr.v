module ast

import cotowari.source { Pos }
import cotowari.token { Token }
import cotowari.symbols { ArrayTypeInfo, FunctionTypeInfo, Scope, Type, TypeSymbol, builtin_fn_id, builtin_type }

pub type Expr = ArrayLiteral | AsExpr | CallExpr | IndexExpr | InfixExpr | IntLiteral |
	ParenExpr | Pipeline | PrefixExpr | StringLiteral | Var

fn (mut r Resolver) exprs(exprs []Expr) {
	for expr in exprs {
		r.expr(expr)
	}
}

fn (mut r Resolver) expr(expr Expr) {
	match expr {
		ArrayLiteral { r.array_literal(expr) }
		AsExpr { r.as_expr(expr) }
		CallExpr { r.call_expr(expr) }
		IndexExpr { r.index_expr(expr) }
		InfixExpr { r.infix_expr(expr) }
		IntLiteral { r.int_literal(expr) }
		ParenExpr { r.paren_expr(expr) }
		Pipeline { r.pipeline(expr) }
		PrefixExpr { r.prefix_expr(expr) }
		StringLiteral { r.string_literal(expr) }
		Var { r.var_(expr) }
	}
}

pub fn (e InfixExpr) pos() Pos {
	return e.left.pos().merge(e.right.pos())
}

pub fn (expr Expr) pos() Pos {
	return match expr {
		ArrayLiteral, AsExpr, CallExpr, Var, ParenExpr, IndexExpr { expr.pos }
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
		CallExpr { e.typ }
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
		ArrayLiteral, CallExpr, InfixExpr, IntLiteral, Pipeline, PrefixExpr, StringLiteral, Var { e.scope }
	}
}

pub struct AsExpr {
pub:
	pos  Pos
	expr Expr
	typ  Type
}

fn (mut r Resolver) as_expr(expr AsExpr) {
	$if trace_resolver ? {
		r.trace_begin(@FN)
		defer {
			r.trace_end()
		}
	}

	r.expr(expr.expr)
}

pub struct CallExpr {
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

pub fn (mut e CallExpr) resolve_func() ?&symbols.Var {
	if mut e.func is Var {
		name := e.func.name()
		sym := e.scope.lookup_var(name) or { return error('function `$name` is not defined') }
		e.func.sym = sym

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
	} else {
		return error('cannot call `$e.func.type_symbol().name`')
	}
}

pub fn (e CallExpr) fn_info() FunctionTypeInfo {
	return e.func.type_symbol().fn_info()
}

fn (mut r Resolver) call_expr(expr CallExpr) {
	$if trace_resolver ? {
		r.trace_begin(@FN)
		defer {
			r.trace_end()
		}
	}

	r.exprs(expr.args)
}

pub struct InfixExpr {
pub:
	scope &Scope
	op    Token
pub mut:
	left  Expr
	right Expr
}

fn (mut r Resolver) infix_expr(expr InfixExpr) {
	$if trace_resolver ? {
		r.trace_begin(@FN)
		defer {
			r.trace_end()
		}
	}

	r.expr(expr.left)
	r.expr(expr.right)
}

pub struct IndexExpr {
pub:
	pos   Pos
	left  Expr
	index Expr
}

fn (mut r Resolver) index_expr(expr IndexExpr) {
	$if trace_resolver ? {
		r.trace_begin(@FN)
		defer {
			r.trace_end()
		}
	}

	r.expr(expr.left)
	r.expr(expr.index)
}

pub struct ParenExpr {
pub:
	pos Pos
pub mut:
	expr Expr
}

fn (mut r Resolver) paren_expr(expr ParenExpr) {
	$if trace_resolver ? {
		r.trace_begin(@FN)
		defer {
			r.trace_end()
		}
	}

	r.expr(expr.expr)
}

pub struct StringLiteral {
pub:
	scope &Scope
	token Token
}

fn (mut r Resolver) string_literal(expr StringLiteral) {
	$if trace_resolver ? {
		r.trace_begin(@FN)
		defer {
			r.trace_end()
		}
	}
}

pub struct IntLiteral {
pub:
	scope &Scope
	token Token
}

fn (mut r Resolver) int_literal(expr IntLiteral) {
	$if trace_resolver ? {
		r.trace_begin(@FN)
		defer {
			r.trace_end()
		}
	}
}

pub struct ArrayLiteral {
pub:
	pos      Pos
	scope    &Scope
	elem_typ Type
pub mut:
	elements []Expr
}

fn (mut r Resolver) array_literal(expr ArrayLiteral) {
	$if trace_resolver ? {
		r.trace_begin(@FN)
		defer {
			r.trace_end()
		}
	}

	r.exprs(expr.elements)
}

// expr | expr | expr
pub struct Pipeline {
pub:
	scope &Scope
pub mut:
	exprs []Expr
}

fn (mut r Resolver) pipeline(expr Pipeline) {
	$if trace_resolver ? {
		r.trace_begin(@FN)
		defer {
			r.trace_end()
		}
	}

	r.exprs(expr.exprs)
}

pub struct PrefixExpr {
pub:
	scope &Scope
	op    Token
pub mut:
	expr Expr
}

fn (mut r Resolver) prefix_expr(expr PrefixExpr) {
	$if trace_resolver ? {
		r.trace_begin(@FN)
		defer {
			r.trace_end()
		}
	}

	r.expr(expr.expr)
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

fn (mut r Resolver) var_(expr Var) {
	$if trace_resolver ? {
		r.trace_begin(@FN)
		defer {
			r.trace_end()
		}
	}
}
