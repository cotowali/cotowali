// Copyright (c) 2021 zakuro <z@kuro.red>. All rights reserved.
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
module parser

import cotowali.ast
import cotowali.errors { unreachable }
import cotowali.token { Token, TokenKind }
import cotowali.util { panic_and_value }
import os

fn (mut p Parser) parse_stmt() ast.Stmt {
	$if trace_parser ? {
		p.trace_begin(@FN)
		defer {
			p.trace_end()
		}
	}

	stmt := p.try_parse_stmt() or {
		p.skip_until_eol()
		ast.EmptyStmt{}
	}
	p.skip_eol()
	return stmt
}

fn (mut p Parser) try_parse_stmt() ?ast.Stmt {
	$if trace_parser ? {
		p.trace_begin(@FN)
		defer {
			p.trace_end()
		}
	}

	match p.kind(0) {
		.key_assert {
			tok := p.consume()
			return ast.AssertStmt{tok.pos, p.parse_expr(.toplevel) ?}
		}
		.key_fn {
			return ast.Stmt(p.parse_fn_decl() ?)
		}
		.key_var {
			return ast.Stmt(p.parse_var_stmt() ?)
		}
		.key_if {
			return ast.Stmt(p.parse_if_stmt() ?)
		}
		.key_for {
			return ast.Stmt(p.parse_for_in_stmt() ?)
		}
		.key_return {
			return ast.Stmt(p.parse_return_stmt() ?)
		}
		.key_require {
			return ast.Stmt(p.parse_require_stmt() ?)
		}
		.key_while {
			return ast.Stmt(p.parse_while_stmt() ?)
		}
		.inline_shell {
			tok := p.consume()
			return ast.InlineShell{
				pos: tok.pos
				text: tok.text
			}
		}
		.key_yield {
			return ast.Stmt(p.parse_yield_stmt() ?)
		}
		else {}
	}
	expr := p.parse_expr(.toplevel) ?
	if p.kind(0).@is(.assign_op) {
		return ast.Stmt(p.parse_assign_stmt_with_left(expr) ?)
	}
	return expr
}

fn (mut p Parser) parse_block(name string, locals []string) ?ast.Block {
	$if trace_parser ? {
		p.trace_begin(@FN, name, '$locals')
		defer {
			p.trace_end()
		}
	}

	p.open_scope(name)
	for local in locals {
		p.scope.register_var(name: local) or { panic(err) }
	}
	defer {
		p.close_scope()
	}
	block := p.parse_block_without_new_scope() ?
	return block
}

fn (mut p Parser) parse_block_without_new_scope() ?ast.Block {
	p.consume_with_check(.l_brace) ?
	p.skip_eol() // ignore eol after brace.
	mut node := ast.Block{
		scope: p.scope
	}
	for {
		if _ := p.consume_if_kind_eq(.r_brace) {
			return node
		}
		node.stmts << p.parse_stmt()
	}
	panic(unreachable(''))
}

fn (mut p Parser) parse_var_stmt() ?ast.AssignStmt {
	$if trace_parser ? {
		p.trace_begin(@FN)
		defer {
			p.trace_end()
		}
	}

	p.consume_with_assert(.key_var)
	ident := p.consume_with_check(.ident) ?
	name := ident.text

	left := ast.Var{
		scope: p.scope
		pos: ident.pos
		sym: p.scope.register_var(name: name, pos: ident.pos) or {
			return p.duplicated_error(name, ident.pos)
		}
	}
	right := if _ := p.consume_if_kind_eq(.assign) {
		expr := p.parse_expr(.toplevel) ?
		expr
	} else {
		ast.Expr(ast.DefaultValue{
			scope: p.scope
			typ: (p.parse_type() ?).typ
		})
	}
	return ast.AssignStmt{
		is_decl: true
		left: left
		right: right
	}
}

fn (mut p Parser) parse_assign_stmt_with_left(left ast.Expr) ?ast.AssignStmt {
	$if trace_parser ? {
		p.trace_begin(@FN)
		defer {
			p.trace_end()
		}
	}

	op := p.consume_with_assert(...[
		.assign,
		.plus_assign,
		.minus_assign,
		.mul_assign,
		.div_assign,
		.mod_assign,
	])

	mut right := p.parse_expr(.toplevel) ?
	if op.kind == .assign {
		return ast.AssignStmt{
			left: left
			right: right
		}
	}

	infix_op_kind := match op.kind {
		.plus_assign { TokenKind.plus }
		.minus_assign { TokenKind.minus }
		.mul_assign { TokenKind.mul }
		.div_assign { TokenKind.div }
		.mod_assign { TokenKind.mod }
		else { panic_and_value(unreachable(''), TokenKind.unknown) }
	}
	match infix_op_kind {
		.plus, .minus, .mul, .div, .mod {
			right = ast.InfixExpr{
				scope: right.scope()
				op: Token{
					...op
					kind: infix_op_kind
				}
				left: left
				right: right
			}
		}
		else {
			panic(unreachable(''))
		}
	}
	return ast.AssignStmt{
		left: left
		right: right
	}
}

fn (mut p Parser) parse_if_branch(name string) ?ast.IfBranch {
	$if trace_parser ? {
		p.trace_begin(@FN)
		defer {
			p.trace_end()
		}
	}

	cond := p.parse_expr(.toplevel) ?
	block := p.parse_block(name, []) ?
	return ast.IfBranch{
		cond: cond
		body: block
	}
}

fn (mut p Parser) parse_if_stmt() ?ast.IfStmt {
	$if trace_parser ? {
		p.trace_begin(@FN)
		defer {
			p.trace_end()
		}
	}

	p.consume_with_assert(.key_if)

	cond := p.parse_expr(.toplevel) ?
	mut branches := [ast.IfBranch{
		cond: cond
		body: p.parse_block('if_$p.count', []) ?
	}]
	mut has_else := false
	mut elif_count := 0
	for {
		p.consume_if_kind_eq(.key_else) or { break }

		if _ := p.consume_if_kind_eq(.key_if) {
			elif_cond := p.parse_expr(.toplevel) ?
			branches << ast.IfBranch{
				cond: elif_cond
				body: p.parse_block('elif_${p.count}_$elif_count', []) ?
			}
			elif_count++
		} else {
			has_else = true
			branches << ast.IfBranch{
				body: p.parse_block('else_$p.count', []) ?
			}
			break
		}
	}
	p.count++
	return ast.IfStmt{
		branches: branches
		has_else: has_else
	}
}

fn (mut p Parser) parse_for_in_stmt() ?ast.ForInStmt {
	$if trace_parser ? {
		p.trace_begin(@FN)
		defer {
			p.trace_end()
		}
	}

	p.consume_with_assert(.key_for)
	ident := p.consume_with_check(.ident) ?
	p.consume_with_check(.key_in) ?
	expr := p.parse_expr(.toplevel) ?
	body := p.parse_block('for_$p.count', [ident.text]) ?
	p.count++
	return ast.ForInStmt{
		val: ast.Var{
			scope: body.scope
			pos: ident.pos
			sym: body.scope.lookup_var(ident.text) or { panic(unreachable(err)) }
		}
		expr: expr
		body: body
	}
}

fn (mut p Parser) parse_return_stmt() ?ast.ReturnStmt {
	$if trace_parser ? {
		p.trace_begin(@FN)
		defer {
			p.trace_end()
		}
	}

	p.consume_with_assert(.key_return)
	return ast.ReturnStmt{
		expr: p.parse_expr(.toplevel) ?
	}
}

fn (mut p Parser) parse_require_stmt() ?ast.RequireStmt {
	key_tok := p.consume_with_assert(.key_require)
	path_node := p.parse_string_literal() ?
	path_pos := ast.Expr(path_node).pos()
	if !path_node.is_const() {
		return p.error('cannot require non-constant path', path_pos)
	}
	pos := key_tok.pos.merge(path_pos)
	path := os.real_path(os.join_path(os.dir(p.source().path), path_node.contents.map((it as Token).text).join('')))

	if path in p.ctx.sources {
		return none
	}

	f := parse_file(path, p.ctx) or { return p.error(err.msg, pos) }
	return ast.RequireStmt{
		file: f
	}
}

fn (mut p Parser) parse_while_stmt() ?ast.WhileStmt {
	$if trace_parser ? {
		p.trace_begin(@FN)
		defer {
			p.trace_end()
		}
	}

	p.consume_with_assert(.key_while)
	cond := p.parse_expr(.toplevel) ?
	body := p.parse_block('while_$p.count', []) ?
	p.count++

	return ast.WhileStmt{
		cond: cond
		body: body
	}
}

fn (mut p Parser) parse_yield_stmt() ?ast.YieldStmt {
	$if trace_parser ? {
		p.trace_begin(@FN)
		defer {
			p.trace_end()
		}
	}

	key := p.consume_with_assert(.key_yield)
	expr := p.parse_expr(.toplevel) ?
	return ast.YieldStmt{
		pos: key.pos.merge(expr.pos())
		expr: expr
	}
}
