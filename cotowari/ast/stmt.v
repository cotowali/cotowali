module ast

import cotowari.source { Pos }
import cotowari.symbols { FunctionTypeInfo, Scope, Type, TypeSymbol }
import cotowari.token { Token }

pub type Stmt = AssertStmt | AssignStmt | Block | EmptyStmt | Expr | FnDecl | ForInStmt |
	IfStmt | InlineShell | RequireStmt | ReturnStmt

pub struct AssignStmt {
pub mut:
	is_decl bool
	left    Expr
	right   Expr
}

pub struct AssertStmt {
pub:
	key_pos Pos
pub mut:
	expr Expr
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
	parent_scope &Scope
	name_pos     Pos
	name         string
	has_body     bool
	typ          Type
pub mut:
	params []Var
	body   Block
}

pub fn (f FnDecl) fn_info() FunctionTypeInfo {
	return f.type_symbol().fn_info()
}

pub fn (f FnDecl) type_symbol() TypeSymbol {
	return f.parent_scope.must_lookup_type(f.typ)
}

pub fn (f FnDecl) ret_type_symbol() TypeSymbol {
	ret := f.parent_scope.must_lookup_type(f.typ).fn_info().ret
	return f.parent_scope.must_lookup_type(ret)
}

pub struct ForInStmt {
pub mut:
	// for var in expr
	val  Var
	expr Expr
	body Block
}

pub struct IfBranch {
pub mut:
	cond Expr
pub:
	body Block
}

pub struct IfStmt {
pub mut:
	branches []IfBranch
pub:
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

pub fn (stmt ReturnStmt) pos() Pos {
	return stmt.token.pos.merge(stmt.expr.pos())
}

pub struct RequireStmt {
pub mut:
	file File
}
