// Copyright (c) 2021 zakuro <z@kuro.red>. All rights reserved.
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
module parser

import cotowali.ast
import cotowali.messages { checksum_mismatch, duplicated_key, invalid_key }
import cotowali.token { Token, TokenKind }
import cotowali.source { none_pos }
import cotowali.symbols { builtin_type }
import cotowali.util { is_relative_path, li_panic }
import net.urllib

fn (mut p Parser) parse_attr() ?ast.Attr {
	$if trace_parser ? {
		p.trace_begin(@FN)
		defer {
			p.trace_end()
		}
	}

	start := (p.consume_with_check(.hash)?).pos
	p.consume_with_check(.l_bracket)?
	tok := p.consume()
	end := (p.consume_with_check(.r_bracket)?).pos
	return ast.Attr{
		pos: start.merge(end)
		name: tok.text
	}
}

fn (mut p Parser) parse_attrs() []ast.Attr {
	$if trace_parser ? {
		p.trace_begin(@FN)
		defer {
			p.trace_end()
		}
	}

	mut attrs := []ast.Attr{}
	for p.kind(0) == .hash {
		if attr := p.parse_attr() {
			attrs << attr
		} else {
			p.skip_until_eol()
		}
		p.skip_eol()
	}
	return attrs
}

fn (mut p Parser) parse_stmt() ast.Stmt {
	$if trace_parser ? {
		p.trace_begin(@FN)
		defer {
			p.trace_end()
		}
	}

	p.process_compiler_directives()
	if p.kind(0) == .eof {
		return ast.Empty{}
	}

	attrs := p.parse_attrs()
	mut stmt := p.try_parse_stmt() or {
		p.skip_until_eol_or_semicolon()
		ast.Empty{}
	}
	p.skip_eol_and_semicolon()

	if attrs.len > 0 {
		if mut stmt is ast.FnDecl {
			stmt.attrs = attrs
		} else {
			p.error('cannot use attributes here', attrs.last().pos)
		}
	}

	p.process_compiler_directives()

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
		.key_fn {
			return ast.Stmt(p.parse_fn_decl()?)
		}
		.key_var, .key_const {
			return ast.Stmt(p.parse_decl_assign_stmt()?)
		}
		.key_if {
			return ast.Stmt(p.parse_if_stmt()?)
		}
		.key_break {
			return ast.Break{
				token: p.consume()
			}
		}
		.key_continue {
			return ast.Continue{
				token: p.consume()
			}
		}
		.key_for {
			return ast.Stmt(p.parse_for_in_stmt()?)
		}
		.key_module {
			return ast.Stmt(p.parse_module()?)
		}
		.key_return {
			return ast.Stmt(p.parse_return_stmt()?)
		}
		.key_require {
			return ast.Stmt(p.parse_require_stmt()?)
		}
		.key_type {
			return p.parse_type_decl()
		}
		.key_while {
			return ast.Stmt(p.parse_while_stmt()?)
		}
		.doc_comment {
			return ast.DocComment{
				token: p.consume()
			}
		}
		.key_yield {
			return ast.Stmt(p.parse_yield_stmt()?)
		}
		else {}
	}

	match p.token(0).keyword_ident() {
		.sh, .pwsh, .inline {
			if p.kind(1) == .l_brace {
				return ast.Stmt(p.parse_inline_shell()?)
			}
		}
		.assert_ {
			if p.kind(1) == .l_paren {
				return ast.Stmt(p.parse_assert_stmt()?)
			}
		}
		.not_a_keyword_ident {}
	}
	expr := p.parse_expr(.toplevel)?
	if p.kind(0).@is(.assign_op) {
		return ast.Stmt(p.parse_assign_stmt_with_left(expr)?)
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
		p.scope.register_var(name: local) or { li_panic(@FN, @FILE, @LINE, err) }
	}
	defer {
		p.close_scope()
	}
	block := p.parse_block_without_new_scope()?
	return block
}

fn (mut p Parser) parse_block_without_new_scope() ?ast.Block {
	p.consume_with_check(.l_brace)?
	p.skip_eol() // ignore eol after brace.

	mut node := ast.Block{
		scope: p.scope
	}
	for {
		p.process_compiler_directives()
		if _ := p.consume_if_kind_eq(.r_brace) {
			return node
		}
		if p.kind(0) == .eof {
			return p.unexpected_token_error(p.token(0), .r_brace)
		}
		node.stmts << p.parse_stmt()
	}
	li_panic(@FN, @FILE, @LINE, '')
}

fn (mut p Parser) parse_decl_assign_stmt() ?ast.AssignStmt {
	$if trace_parser ? {
		p.trace_begin(@FN)
		defer {
			p.trace_end()
		}
	}

	key := p.consume_with_assert(.key_var, .key_const)
	is_const := key.kind == .key_const

	left := p.parse_expr(.toplevel)?

	mut typ := builtin_type(.placeholder)
	p.check(.assign, .colon)?

	if _ := p.consume_if_kind_eq(.colon) {
		typ = (p.parse_type()?).typ
	}
	right := if _ := p.consume_if_kind_eq(.assign) {
		expr := p.parse_expr(.toplevel)?
		expr
	} else {
		ast.Expr(ast.DefaultValue{
			scope: p.scope
			typ: typ
		})
	}

	return ast.AssignStmt{
		is_decl: true
		is_const: is_const
		scope: p.scope
		typ: typ
		left: left
		right: right
	}
}

fn (mut p Parser) parse_assert_stmt() ?ast.AssertStmt {
	tok := p.consume()
	p.consume_with_check(.l_paren)?
	args := p.parse_call_args()?
	r_paren := p.consume_with_check(.r_paren)?
	return ast.AssertStmt{
		pos: tok.pos.merge(r_paren.pos)
		args: args
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

	mut right := p.parse_expr(.toplevel)?
	if op.kind == .assign {
		return ast.AssignStmt{
			scope: p.scope
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
		else { li_panic(@FN, @FILE, @LINE, '') }
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
			li_panic(@FN, @FILE, @LINE, '')
		}
	}
	return ast.AssignStmt{
		scope: p.scope
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

	cond := p.parse_expr(.toplevel)?
	block := p.parse_block(name, [])?
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

	cond := p.parse_expr(.toplevel)?
	mut branches := [
		ast.IfBranch{
			cond: cond
			body: p.parse_block('if_$p.count', [])?
		},
	]
	mut has_else := false
	mut elif_count := 0
	for {
		p.consume_if_kind_eq(.key_else) or { break }

		if _ := p.consume_if_kind_eq(.key_if) {
			elif_cond := p.parse_expr(.toplevel)?
			branches << ast.IfBranch{
				cond: elif_cond
				body: p.parse_block('elif_${p.count}_$elif_count', [])?
			}
			elif_count++
		} else {
			has_else = true
			branches << ast.IfBranch{
				body: p.parse_block('else_$p.count', [])?
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
	ident := p.consume_with_check(.ident)?
	p.consume_with_check(.key_in)?
	expr := p.parse_expr(.toplevel)?
	body := p.parse_block('for_$p.count', [])?
	p.count++
	return ast.ForInStmt{
		var_: ast.Var{
			ident: ast.Ident{
				scope: body.scope
				pos: ident.pos
				text: ident.text
			}
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
	p.skip_eol()

	mut expr := ast.Expr(ast.Empty{
		scope: p.scope
		pos: p.pos(-1)
	})
	if p.kind(0) !in [.r_brace, .r_paren, .r_bracket, .semicolon] {
		expr = p.parse_expr(.toplevel)?
	}
	return ast.ReturnStmt{
		expr: expr
	}
}

fn (mut p Parser) parse_require_stmt() ?ast.RequireStmt {
	key_tok := p.consume_with_assert(.key_require)
	mut pos := key_tok.pos

	path_node := p.parse_string_literal()?
	path_pos := path_node.pos()
	path := path_node.const_text() or {
		return p.error('cannot require non-constant path', path_pos)
	}

	props := p.parse_require_stmt_props()?

	pos = pos.merge(p.pos(-1))

	stmt := if url := urllib.parse(path) {
		f := parse_remote_file(url, p.ctx) or {
			return if err is none { none } else { p.error(err.msg, pos) }
		}
		ast.RequireStmt{
			props: props
			file: f
		}
	} else if is_relative_path(path) {
		f := parse_file_relative(p.source(), path, p.ctx) or {
			return if err is none { none } else { p.error(err.msg, pos) }
		}
		ast.RequireStmt{
			props: props
			file: f
		}
	} else {
		f := parse_file_in_cotowali_path(path, p.ctx) or {
			return if err is none { none } else { p.error(err.msg, pos) }
		}
		ast.RequireStmt{
			props: props
			file: f
		}
	}

	p.require_stmt_verify_checksum(stmt)?
	return stmt
}

fn (mut p Parser) parse_require_stmt_props() ?ast.RequireStmtProps {
	mut props_map := {
		'md5':    ''
		'sha1':   ''
		'sha256': ''
	}
	mut props_pos_map := {
		'md5':    none_pos()
		'sha1':   none_pos()
		'sha256': none_pos()
	}

	if p.kind(0) != .l_brace {
		// stmt don't have `{}` props
		return ast.RequireStmtProps{}
	}

	p.consume_with_assert(.l_brace)
	p.skip_eol()

	if p.kind(0) == .r_brace {
		// stmt have `{}` but it is empty
		return ast.RequireStmtProps{}
	}

	for {
		p.skip_eol()

		key_tok := p.consume_with_check(.ident)?
		key := key_tok.text

		p.skip_eol()
		p.consume_with_check(.colon)?

		if key in props_map {
			p.skip_eol()

			value_node := p.parse_string_literal()?
			value_pos := value_node.pos()
			value := value_node.const_text() or {
				// report error then continue to parse
				p.error('cannot use non-constant value here', value_pos)
				''
			}

			if props_map[key] != '' {
				p.error(duplicated_key(key), key_tok.pos)
			}
			props_map[key] = value
			props_pos_map[key] = key_tok.pos.merge(value_pos)
		} else {
			// report error then continue to parse
			p.error(invalid_key(key, expects: props_map.keys()), key_tok.pos)
			p.consume_for(fn (t Token) bool {
				// skip until end of value
				return t.kind !in [.comma, .r_brace, .eol]
			})
		}

		p.skip_eol()
		if _ := p.consume_if_kind_eq(.r_brace) {
			break
		}

		p.skip_eol()
		p.consume_with_check(.comma)?

		p.skip_eol()
		if _ := p.consume_if_kind_eq(.r_brace) {
			break
		}
	}

	return ast.RequireStmtProps{
		md5: props_map['md5']
		sha1: props_map['sha1']
		sha256: props_map['sha256']
		md5_pos: props_pos_map['md5']
		sha1_pos: props_pos_map['sha1']
		sha256_pos: props_pos_map['sha256']
	}
}

fn (mut p Parser) require_stmt_verify_checksum(stmt ast.RequireStmt) ? {
	mut ok := true
	if stmt.has_checksum(.md5) {
		expected, actual := stmt.checksum(.md5), stmt.file.checksum(.md5)
		if expected != actual {
			p.error(checksum_mismatch(.md5, expected: expected, actual: actual), stmt.checksum_pos(.md5))
			ok = false
		}
	}
	if stmt.has_checksum(.sha1) {
		expected, actual := stmt.checksum(.sha1), stmt.file.checksum(.sha1)
		if expected != actual {
			p.error(checksum_mismatch(.sha1, expected: expected, actual: actual), stmt.checksum_pos(.sha1))
			ok = false
		}
	}
	if stmt.has_checksum(.sha256) {
		expected, actual := stmt.checksum(.sha256), stmt.file.checksum(.sha256)
		if expected != actual {
			p.error(checksum_mismatch(.sha256, expected: expected, actual: actual), stmt.checksum_pos(.sha256))
			ok = false
		}
	}
	if !ok {
		return error('checksum mismatch')
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
	cond := p.parse_expr(.toplevel)?
	body := p.parse_block('while_$p.count', [])?
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
	expr := p.parse_expr(.toplevel)?
	return ast.YieldStmt{
		pos: key.pos.merge(expr.pos())
		expr: expr
	}
}
