// Copyright (c) 2021 zakuro <z@kuro.red>. All rights reserved.
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
module parser

import cotowali.token { TokenKind }
import cotowali.ast
import cotowali.symbols { builtin_type }
import cotowali.messages { duplicated_key, invalid_key, unreachable }
import cotowali.util { struct_name }

fn (mut p Parser) parse_expr_stmt(expr ast.Expr) ?ast.Stmt {
	$if trace_parser ? {
		p.trace_begin(@FN)
		defer {
			p.trace_end()
		}
	}

	// eol or close blace
	if !(p.brace_depth > 0 && p.kind(0) == .r_brace) {
		p.consume_with_check(.eol, .eof) ?
	}

	return expr
}

enum ExprKind {
	toplevel = 0
	pipeline
	logical_or
	logical_and
	comparsion
	term
	factor
	pow
	as_cast
	prefix
	value
}

const expr_kind_to_op_table = (fn () map[ExprKind][]TokenKind {
	k := fn (e ExprKind) ExprKind {
		return e
	}
	v := fn (ops ...TokenKind) []TokenKind {
		return ops
	}
	return {
		k(.pipeline):    v(.pipe, .pipe_append)
		k(.logical_or):  v(.logical_or)
		k(.logical_and): v(.logical_and)
		k(.comparsion):  v(.eq, .ne, .gt, .ge, .lt, .le)
		k(.term):        v(.plus, .minus)
		k(.factor):      v(.mul, .div, .mod)
		k(.pow):         v(.pow)
	}
}())

fn (e ExprKind) op_kinds() []TokenKind {
	return parser.expr_kind_to_op_table[e] or { panic(unreachable('')) }
}

fn (k ExprKind) outer() ExprKind {
	return if k == .toplevel { k } else { ExprKind(int(k) - 1) }
}

fn (k ExprKind) inner() ExprKind {
	return if k == .value { k } else { ExprKind(int(k) + 1) }
}

fn (mut p Parser) parse_infix_expr(kind ExprKind) ?ast.Expr {
	$if trace_parser ? {
		p.trace_begin(@FN, '$kind')
		defer {
			p.trace_end()
		}
	}

	operand := kind.inner()
	op_kinds := kind.op_kinds()

	mut expr := p.parse_expr(operand) ?
	for {
		p.skip_eol()

		op := p.token(0)
		if op.kind !in op_kinds {
			break
		}
		p.consume_with_assert(...op_kinds)

		p.skip_eol()

		right := p.parse_expr(operand) ?
		expr = ast.InfixExpr{
			scope: p.scope
			op: op
			left: expr
			right: right
		}
	}
	return expr
}

fn (mut p Parser) parse_prefix_expr() ?ast.Expr {
	$if trace_parser ? {
		p.trace_begin(@FN)
		defer {
			p.trace_end()
		}
	}

	if op := p.consume_if_kind_is(.prefix_op) {
		return ast.PrefixExpr{
			scope: p.scope
			op: op
			expr: p.parse_expr(.prefix) ?
		}
	}
	return p.parse_expr(.prefix.inner())
}

fn (mut p Parser) parse_expr(kind ExprKind) ?ast.Expr {
	$if trace_parser ? {
		p.trace_begin(@FN, '$kind')
		defer {
			p.trace_end()
		}
	}

	p.skip_eol()

	match kind {
		.toplevel { return p.parse_expr(kind.inner()) }
		.pipeline { return p.parse_pipeline() }
		.logical_or, .logical_and, .comparsion, .term, .factor, .pow { return p.parse_infix_expr(kind) }
		.as_cast { return p.parse_as_expr() }
		.prefix { return p.parse_prefix_expr() }
		.value { return p.parse_value() }
	}
}

fn (mut p Parser) parse_as_expr() ?ast.Expr {
	$if trace_parser ? {
		p.trace_begin(@FN)
		defer {
			p.trace_end()
		}
	}

	expr := p.parse_expr(ExprKind.as_cast.inner()) ?
	if _ := p.consume_if_kind_eq(.key_as) {
		ts := p.parse_type() ?
		return ast.AsExpr{
			pos: expr.pos().merge(p.token(-1).pos)
			typ: ts.typ
			expr: expr
		}
	} else {
		return expr
	}
}

fn (mut p Parser) parse_pipeline() ?ast.Expr {
	$if trace_parser ? {
		p.trace_begin(@FN)
		defer {
			p.trace_end()
		}
	}

	inner := ExprKind.pipeline.inner()
	expr := p.parse_expr(inner) ?
	if p.kind(0) !in [.pipe, .pipe_append] {
		return expr
	}
	mut exprs := [expr]
	for p.kind(0) == .pipe {
		p.consume_with_assert(.pipe)
		exprs << p.parse_expr(inner) ?
	}
	is_append := if _ := p.consume_if_kind_eq(.pipe_append) {
		exprs << p.parse_expr(inner) ?
		true
	} else {
		false
	}
	return ast.Pipeline{
		scope: p.scope
		exprs: exprs
		is_append: is_append
	}
}

fn (mut p Parser) parse_ident() ?ast.Expr {
	$if trace_parser ? {
		p.trace_begin(@FN)
		defer {
			p.trace_end()
		}
	}

	mut modules := []ast.Ident{}
	for p.kind(1) == .coloncolon {
		tok := p.consume_with_check(.ident) ?
		modules << ast.Ident{
			scope: p.scope
			pos: tok.pos
			text: tok.text
		}
		p.consume_with_assert(.coloncolon)
	}

	tok := p.consume_with_check(.ident) ?
	v := ast.Var{
		ident: ast.Ident{
			scope: p.scope
			pos: tok.pos
			text: tok.text
		}
	}

	if modules.len == 0 {
		return v
	}

	return ast.ModuleItem{
		scope: p.scope
		modules: modules
		item: v
	}
}

fn (mut p Parser) parse_array_literal() ?ast.Expr {
	$if trace_parser ? {
		p.trace_begin(@FN)
		defer {
			p.trace_end()
		}
	}

	first_tok := p.consume_with_check(.l_bracket) ?
	mut last_tok := first_tok
	if _ := p.consume_if_kind_eq(.r_bracket) {
		// []Type{}
		elem_ts := p.parse_type() ?
		p.consume_with_check(.l_brace) ?

		mut len := ast.Expr(ast.DefaultValue{
			scope: p.scope
			typ: builtin_type(.int)
		})
		mut init := ast.Expr(ast.DefaultValue{
			scope: p.scope
			typ: elem_ts.typ
		})
		for p.kind(0) == .ident {
			key := p.consume_with_assert(.ident)
			p.consume_with_check(.colon) ?
			value := p.parse_expr(.toplevel) ?
			match key.text {
				'len' {
					if len is ast.DefaultValue {
						len = value
					} else {
						p.error(duplicated_key(key.text), key.pos)
					}
				}
				'init' {
					if init is ast.DefaultValue {
						init = value
					} else {
						p.error(duplicated_key(key.text), key.pos)
					}
				}
				else {
					p.error(invalid_key(key.text, expects: ['len', 'init']), key.pos)
				}
			}
			if _ := p.consume_if_kind_eq(.comma) {
			} else {
				break
			}
		}

		last_tok = p.consume_with_check(.r_brace) ?
		return ast.ArrayLiteral{
			scope: p.scope
			pos: first_tok.pos.merge(last_tok.pos)
			elem_typ: elem_ts.typ
			init: init
			len: len
			is_init_syntax: true
		}
	}

	mut elements := []ast.Expr{}
	for {
		p.skip_eol()
		elements << (p.parse_expr(.toplevel) ?)

		p.skip_eol()
		if tok := p.consume_if_kind_eq(.r_bracket) {
			// ends without trailing comma
			last_tok = tok
			break
		}

		last_tok = p.consume_with_check(.comma) ?

		p.skip_eol()
		if tok := p.consume_if_kind_eq(.r_bracket) {
			// ends with trailing comma
			last_tok = tok
			break
		}
	}

	$if !prod {
		assert elements.len > 0
	}
	return ast.ArrayLiteral{
		scope: p.scope
		pos: first_tok.pos.merge(last_tok.pos)
		elements: elements
	}
}

fn (mut p Parser) parse_map_literal() ?ast.Expr {
	$if trace_parser ? {
		p.trace_begin(@FN)
		defer {
			p.trace_end()
		}
	}

	mut pos := p.token(0).pos
	mut key_typ := builtin_type(.placeholder)
	mut value_typ := builtin_type(.placeholder)

	// map[key]value{} or // map{ key: value }
	if _ := p.consume_if_kind_eq(.key_map) {
		// map[key]value{}
		if _ := p.consume_if_kind_eq(.l_bracket) {
			key_typ = (p.parse_type() ?).typ
			p.consume_with_check(.r_bracket) ?
			value_typ = (p.parse_type() ?).typ
		}
	}

	mut entries := []ast.MapLiteralEntry{}
	p.consume_with_check(.l_brace) ?
	p.skip_eol()

	// no entry is allowed for map[key]value{} syntax (when using this syntax, key_typ is not placholder)
	if !(key_typ != builtin_type(.placeholder) && p.kind(0) == .r_brace) {
		for {
			key := p.parse_expr(.toplevel) ?
			p.consume_with_check(.colon) ?
			value := p.parse_expr(.toplevel) ?

			entries << ast.MapLiteralEntry{
				key: key
				value: value
			}

			if p.kind(0) == .r_brace {
				break
			}
			p.consume_with_check(.comma) ?
			p.skip_eol()
			if p.kind(0) == .r_brace {
				break
			}
		}
	}

	r_brace := p.consume_with_assert(.r_brace)
	pos = pos.merge(r_brace.pos)

	return ast.MapLiteral{
		scope: p.scope
		pos: pos
		entries: entries
		key_typ: key_typ
		value_typ: value_typ
	}
}

fn (mut p Parser) parse_paren_expr() ?ast.Expr {
	l_paren := p.consume_with_assert(.l_paren)
	p.skip_eol()

	mut pos := l_paren.pos
	mut exprs := []ast.Expr{}

	if r_paren := p.consume_if_kind_eq(.r_paren) {
		// `()`
		pos = pos.merge(r_paren.pos)
	} else {
		// `(int)` or `(int, int)`
		for {
			p.skip_eol()
			if dotdotdot := p.consume_if_kind_eq(.dotdotdot) {
				expr := p.parse_expr(.toplevel) ?
				exprs << ast.DecomposeExpr{
					pos: dotdotdot.pos.merge(expr.pos())
					expr: expr
				}
			} else {
				exprs << p.parse_expr(.toplevel) ?
			}

			p.skip_eol()
			if r_paren := p.consume_if_kind_eq(.r_paren) {
				pos = pos.merge(r_paren.pos)
				break
			}
			p.consume_with_check(.comma) ?

			p.skip_eol()
			if r_paren := p.consume_if_kind_eq(.r_paren) {
				pos = pos.merge(r_paren.pos)
				break
			}
		}
	}

	return ast.ParenExpr{
		pos: pos
		exprs: exprs
		scope: p.scope
	}
}

fn (mut p Parser) parse_index_expr_with_left(left ast.Expr) ?ast.Expr {
	$if trace_parser ? {
		p.trace_begin(@FN, '${struct_name(left)}{...}')
		defer {
			p.trace_end()
		}
	}

	p.consume_with_assert(.l_bracket)
	p.skip_eol()
	index := p.parse_expr(.toplevel) ?
	p.skip_eol()
	r_bracket := p.consume_with_check(.r_bracket) ?
	return ast.IndexExpr{
		left: left
		index: index
		pos: left.pos().merge(r_bracket.pos)
	}
}

fn (mut p Parser) parse_selector_expr_with_left(left ast.Expr) ?ast.Expr {
	$if trace_parser ? {
		p.trace_begin(@FN, '${struct_name(left)}{...}')
		defer {
			p.trace_end()
		}
	}

	p.consume_with_assert(.dot)
	ident := p.parse_ident() ?
	if ident is ast.Var {
		return ast.SelectorExpr{
			left: left
			ident: ident
		}
	} else {
		return p.syntax_error('invalid selector', ident.pos())
	}
}

fn (mut p Parser) parse_value_left() ?ast.Expr {
	$if trace_parser ? {
		p.trace_begin(@FN)
		defer {
			p.trace_end()
		}
	}

	tok := p.token(0)
	match tok.kind {
		.ident {
			return p.parse_ident()
		}
		.key_null {
			p.consume()
			return ast.NullLiteral{
				scope: p.scope
				token: tok
			}
		}
		.int_literal {
			p.consume()
			return ast.IntLiteral{
				scope: p.scope
				token: tok
			}
		}
		.float_literal {
			p.consume()
			return ast.FloatLiteral{
				scope: p.scope
				token: tok
			}
		}
		.single_quote, .double_quote, .single_quote_with_r_prefix, .double_quote_with_r_prefix,
		.single_quote_with_at_prefix, .double_quote_with_at_prefix {
			return ast.Expr(p.parse_string_literal() ?)
		}
		.bool_literal {
			p.consume()
			return ast.BoolLiteral{
				scope: p.scope
				token: tok
			}
		}
		.l_bracket {
			return p.parse_array_literal()
		}
		.l_brace, .key_map {
			return p.parse_map_literal()
		}
		.l_paren {
			return p.parse_paren_expr()
		}
		else {
			found := p.consume()
			return p.unexpected_token_error(found)
		}
	}
}

fn (mut p Parser) parse_value() ?ast.Expr {
	$if trace_parser ? {
		p.trace_begin(@FN)
		defer {
			p.trace_end()
		}
	}

	t := p.token(0)
	if t.kind == .ident && t.text.len > 0 && t.text[0] == `@` {
		ident := p.consume()
		command := ident.text[1..] // '@command' -> 'command'
		p.consume_with_check(.l_paren) ?
		args := p.parse_call_args() ?
		r_paren := p.consume_with_assert(.r_paren)
		return ast.CallCommandExpr{
			scope: p.scope
			pos: ident.pos.merge(r_paren.pos)
			command: command
			args: args
		}
	}

	mut expr := p.parse_value_left() ?
	for {
		match p.kind(0) {
			.l_paren { expr = p.parse_call_expr_with_left(expr) ? }
			.l_bracket { expr = p.parse_index_expr_with_left(expr) ? }
			.dot { expr = p.parse_selector_expr_with_left(expr) ? }
			else { break }
		}
	}
	return expr
}
