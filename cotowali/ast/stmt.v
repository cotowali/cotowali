// Copyright (c) 2021 zakuro <z@kuro.red>. All rights reserved.
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
module ast

import cotowali.token { Token }
import cotowali.source { Pos }
import cotowali.symbols { Scope, Type, builtin_type }
import cotowali.messages { unreachable }
import cotowali.util.checksum

pub type Stmt = AssertStmt
	| AssignStmt
	| Block
	| Break
	| Continue
	| DocComment
	| EmptyStmt
	| Expr
	| FnDecl
	| ForInStmt
	| IfStmt
	| InlineShell
	| NamespaceDecl
	| RequireStmt
	| ReturnStmt
	| WhileStmt
	| YieldStmt

pub fn (stmt Stmt) children() []Node {
	return match stmt {
		Break, Continue, DocComment, EmptyStmt, InlineShell {
			[]Node{}
		}
		AssertStmt, AssignStmt, Block, Expr, FnDecl, ForInStmt, IfStmt, NamespaceDecl, RequireStmt,
		ReturnStmt, WhileStmt, YieldStmt {
			stmt.children()
		}
	}
}

fn (mut r Resolver) stmts(stmts []Stmt) {
	for stmt in stmts {
		r.stmt(stmt)
	}
}

fn (mut r Resolver) stmt(stmt Stmt) {
	match mut stmt {
		AssertStmt { r.assert_stmt(stmt) }
		AssignStmt { r.assign_stmt(mut stmt) }
		Block { r.block(stmt) }
		Break {}
		Continue {}
		DocComment { r.doc_comment(stmt) }
		EmptyStmt { r.empty_stmt(stmt) }
		Expr { r.expr(stmt) }
		FnDecl { r.fn_decl(stmt) }
		ForInStmt { r.for_in_stmt(mut stmt) }
		IfStmt { r.if_stmt(stmt) }
		InlineShell { r.inline_shell(mut stmt) }
		NamespaceDecl { r.namespace_decl(stmt) }
		RequireStmt { r.require_stmt(stmt) }
		ReturnStmt { r.return_stmt(stmt) }
		WhileStmt { r.while_stmt(stmt) }
		YieldStmt { r.yield_stmt(stmt) }
	}
}

pub struct AssignStmt {
mut:
	scope &Scope
pub mut:
	is_decl bool
	typ     Type = builtin_type(.placeholder)
	left    Expr
	right   Expr
}

[inline]
pub fn (s &AssignStmt) children() []Node {
	return [Node(s.left), Node(s.right)]
}

fn (mut r Resolver) assign_stmt(mut stmt AssignStmt) {
	$if trace_resolver ? {
		r.trace_begin(@FN)
		defer {
			r.trace_end()
		}
	}

	if !stmt.is_decl {
		r.expr(stmt.left, is_left_of_assignment: true)
	}
	r.expr(stmt.right)

	if stmt.typ == builtin_type(.placeholder) {
		stmt.typ = stmt.right.typ()
	}

	ts := stmt.scope.must_lookup_type(stmt.typ)

	match mut stmt.left {
		Var {
			if stmt.is_decl {
				name, pos, typ := stmt.left.ident.text, stmt.left.ident.pos, stmt.typ
				if name == '_' {
					stmt.left.sym = &symbols.Var{
						name: '_'
						typ: builtin_type(.any)
					}
				} else {
					stmt.left.sym = stmt.scope.register_var(name: name, pos: pos, typ: typ) or {
						r.error(err.msg, pos)
						stmt.scope.must_lookup_var(name)
					}
				}
			}
		}
		IndexExpr {}
		ParenExpr {
			if stmt.is_decl {
				expr_types := if tuple_info := ts.tuple_info() {
					tuple_info.elements.map(it.typ)
				} else {
					[]Type{}
				}
				if stmt.left.exprs.len != expr_types.len {
					r.error('expected $expr_types.len variables, but found $stmt.left.exprs.len variables',
						Expr(stmt.left).pos())
				}
				for i, left in stmt.left.exprs {
					if mut left is Var {
						name, pos := left.ident.text, left.ident.pos
						typ := if i < expr_types.len {
							expr_types[i]
						} else {
							builtin_type(.placeholder)
						}
						if name == '_' {
							left.sym = &symbols.Var{
								name: '_'
								typ: builtin_type(.any)
							}
						} else {
							left.sym = stmt.scope.register_var(
								name: name
								pos: pos
								typ: typ
							) or {
								r.error(err.msg, pos)
								stmt.scope.must_lookup_var(name)
							}
						}
					}
				}
			}
		}
		else {
			r.error('invalid left-hand side of assignment', stmt.left.pos())
		}
	}
}

pub struct AssertStmt {
pub:
	pos Pos
pub mut:
	args []Expr
}

pub fn (s &AssertStmt) cond() Expr {
	$if !prod {
		if s.args.len == 0 {
			panic(unreachable('assert cond is not set'))
		}
	}
	return s.args[0]
}

pub fn (s &AssertStmt) message_expr() ?Expr {
	if s.args.len > 1 {
		return s.args[1]
	}
	return none
}

pub fn (s &AssertStmt) children() []Node {
	return s.args.map(Node(it))
}

fn (mut r Resolver) assert_stmt(stmt AssertStmt) {
	$if trace_resolver ? {
		r.trace_begin(@FN)
		defer {
			r.trace_end()
		}
	}

	r.exprs(stmt.args)
}

pub struct Block {
pub mut:
	scope &Scope
	stmts []Stmt
}

[inline]
pub fn (s &Block) children() []Node {
	return s.stmts.map(Node(it))
}

fn (mut r Resolver) block(stmt Block) {
	$if trace_resolver ? {
		r.trace_begin(@FN)
		defer {
			r.trace_end()
		}
	}

	r.stmts(stmt.stmts)
}

pub struct Break {
pub:
	token Token
}

pub struct Continue {
pub:
	token Token
}

pub struct DocComment {
	token Token
}

[inline]
pub fn (doc DocComment) text() string {
	return doc.token.text
}

pub fn (doc DocComment) lines() []string {
	return doc.text().split_into_lines()
}

fn (mut r Resolver) doc_comment(stmt DocComment) {
	$if trace_resolver ? {
		r.trace_begin(@FN)
		defer {
			r.trace_end()
		}
	}
}

pub struct EmptyStmt {}

fn (mut r Resolver) empty_stmt(stmt EmptyStmt) {
	$if trace_resolver ? {
		r.trace_begin(@FN)
		defer {
			r.trace_end()
		}
	}
}

pub struct ForInStmt {
pub mut:
	// for var in expr
	var_ Var
	expr Expr
	body Block
}

[inline]
pub fn (s &ForInStmt) children() []Node {
	return [Node(s.expr), Node(Expr(s.var_)), Node(Stmt(s.body))]
}

fn (mut r Resolver) for_in_stmt(mut stmt ForInStmt) {
	$if trace_resolver ? {
		r.trace_begin(@FN)
		defer {
			r.trace_end()
		}
	}

	r.expr(stmt.expr)

	var_typ := if array_info := stmt.expr.type_symbol().array_info() {
		array_info.elem
	} else if sequence_info := stmt.expr.type_symbol().sequence_info() {
		sequence_info.elem
	} else {
		builtin_type(.placeholder)
	}
	name, pos, typ := stmt.var_.ident.text, stmt.var_.ident.pos, var_typ
	stmt.var_.sym = stmt.body.scope.must_register_var(name: name, pos: pos, typ: typ)
	r.var_(mut stmt.var_)

	r.block(stmt.body)
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

pub fn (s &IfStmt) children() []Node {
	mut children := []Node{cap: s.branches.len * 2}
	for b in s.branches {
		children << b.cond
		children << Stmt(b.body)
	}
	return children
}

fn (mut r Resolver) if_stmt(stmt IfStmt) {
	$if trace_resolver ? {
		r.trace_begin(@FN)
		defer {
			r.trace_end()
		}
	}

	for b in stmt.branches {
		r.expr(b.cond)
		r.block(b.body)
	}
}

pub type InlineShellPart = Token | Var

pub struct InlineShell {
pub:
	key Token
	pos Pos
pub mut:
	parts []InlineShellPart
}

pub fn (sh &InlineShell) use_for_sh() bool {
	return sh.key.keyword_ident() in [.sh, .inline]
}

pub fn (sh &InlineShell) use_for_pwsh() bool {
	return sh.key.keyword_ident() in [.pwsh, .inline]
}

fn (mut r Resolver) inline_shell(mut stmt InlineShell) {
	$if trace_resolver ? {
		r.trace_begin(@FN)
		defer {
			r.trace_end()
		}
	}

	for mut part in stmt.parts {
		if mut part is Var {
			r.var_(mut part)
		}
	}
}

pub struct NamespaceDecl {
pub mut:
	block Block
}

[inline]
pub fn (ns &NamespaceDecl) children() []Node {
	return [Node(Stmt(ns.block))]
}

fn (mut r Resolver) namespace_decl(ns NamespaceDecl) {
	$if trace_resolver ? {
		r.trace_begin(@FN)
		defer {
			r.trace_end()
		}
	}

	r.block(ns.block)
}

pub struct RequireStmtProps {
pub:
	md5        string
	md5_pos    Pos
	sha1       string
	sha1_pos   Pos
	sha256     string
	sha256_pos Pos
}

pub struct RequireStmt {
pub:
	props RequireStmtProps
pub mut:
	file File
}

pub fn (s &RequireStmt) has_checksum(algo checksum.Algorithm) bool {
	return match algo {
		.md5 { s.props.md5 != '' }
		.sha1 { s.props.sha1 != '' }
		.sha256 { s.props.sha256 != '' }
	}
}

pub fn (s &RequireStmt) checksum(algo checksum.Algorithm) string {
	return match algo {
		.md5 { s.props.md5 }
		.sha1 { s.props.sha1 }
		.sha256 { s.props.sha256 }
	}
}

pub fn (s &RequireStmt) checksum_pos(algo checksum.Algorithm) Pos {
	return match algo {
		.md5 { s.props.md5_pos }
		.sha1 { s.props.sha1_pos }
		.sha256 { s.props.sha256_pos }
	}
}

pub fn (stmt &RequireStmt) str() string {
	mut prop_strs := []string{}
	if stmt.has_checksum(.md5) {
		prop_strs << 'md5: ...'
	}
	if stmt.has_checksum(.sha1) {
		prop_strs << 'sha1: ...'
	}
	if stmt.has_checksum(.sha256) {
		prop_strs << 'sha256: ...'
	}
	s := 'require "$stmt.file.source.path"' +
		(if prop_strs.len > 0 { ' { ${prop_strs.join(', ')} }' } else { '' })
	return 'RequireStmt{$s}'
}

[inline]
pub fn (s &RequireStmt) children() []Node {
	return [Node(s.file)]
}

fn (mut r Resolver) require_stmt(stmt RequireStmt) {
	$if trace_resolver ? {
		r.trace_begin(@FN)
		defer {
			r.trace_end()
		}
	}

	r.file(stmt.file)
}

pub struct WhileStmt {
pub:
	cond Expr
	body Block
}

[inline]
pub fn (s &WhileStmt) children() []Node {
	return [Node(s.cond), Node(Stmt(s.body))]
}

fn (mut r Resolver) while_stmt(stmt WhileStmt) {
	$if trace_resolver ? {
		r.trace_begin(@FN)
		defer {
			r.trace_end()
		}
	}

	r.expr(stmt.cond)
	r.block(stmt.body)
}
