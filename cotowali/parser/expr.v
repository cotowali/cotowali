module parser

import cotowali.token { TokenKind }
import cotowali.ast
import cotowali.symbols { builtin_type, new_placeholder_var }
import cotowali.errors { unreachable }
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
	return map{
		k(.pipeline):    v(.pipe)
		k(.logical_or):  v(.logical_or)
		k(.logical_and): v(.logical_and)
		k(.comparsion):  v(.eq, .ne, .gt, .ge, .lt, .le)
		k(.term):        v(.plus, .minus)
		k(.factor):      v(.mul, .div, .mod)
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
		op := p.token(0)
		if op.kind !in op_kinds {
			break
		}
		p.consume_with_assert(...op_kinds)
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

	match kind {
		.toplevel { return p.parse_expr(kind.inner()) }
		.pipeline { return p.parse_pipeline() }
		.logical_or, .logical_and, .comparsion, .term, .factor { return p.parse_infix_expr(kind) }
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
	if p.kind(0) != .pipe {
		return expr
	}
	mut exprs := [expr]
	for p.kind(0) == .pipe {
		p.consume_with_assert(.pipe)
		exprs << p.parse_expr(inner) ?
	}
	return ast.Pipeline{
		scope: p.scope
		exprs: exprs
	}
}

fn (mut p Parser) parse_ident() ?ast.Expr {
	$if trace_parser ? {
		p.trace_begin(@FN)
		defer {
			p.trace_end()
		}
	}

	ident := p.consume()
	name := ident.text
	return ast.Var{
		scope: p.scope
		pos: ident.pos
		sym: new_placeholder_var(name)
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
		last_tok = p.consume_with_check(.r_brace) ?
		return ast.ArrayLiteral{
			scope: p.scope
			pos: first_tok.pos.merge(last_tok.pos)
			elem_typ: elem_ts.typ
			elements: []
		}
	}
	mut elements := []ast.Expr{}
	for {
		elements << (p.parse_expr(.toplevel) ?)
		last_tok = p.consume_with_check(.r_bracket, .comma) ?
		if last_tok.kind == .r_bracket {
			break
		}
	}
	$if !prod {
		assert elements.len > 0
	}
	return ast.ArrayLiteral{
		scope: p.scope
		pos: first_tok.pos.merge(last_tok.pos)
		elem_typ: elements[0].typ()
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

	// map[key]value{}
	if _ := p.consume_if_kind_eq(.key_map) {
		p.consume_with_check(.l_bracket) ?
		key_typ = (p.parse_type() ?).typ
		p.consume_with_check(.r_bracket) ?
		value_typ = (p.parse_type() ?).typ
	}

	mut entries := []ast.MapLiteralEntry{}
	p.consume_with_check(.l_brace) ?

	// no entry is allowed for map[key]value{} syntax (when using this syntax, key_typ is not placholder)
	if !(key_typ == builtin_type(.placeholder) && p.kind(0) == .r_brace) {
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
			p.consume_with_check(.eol, .comma) ?
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

	mut pos := l_paren.pos
	mut exprs := []ast.Expr{}

	if r_paren := p.consume_if_kind_eq(.r_paren) {
		// `()`
		pos = pos.merge(r_paren.pos)
	} else {
		// `(int)` or `(int, int)`
		for {
			exprs << p.parse_expr(.toplevel) ?
			tail := p.consume_with_check(.comma, .r_paren) ?
			if tail.kind == .r_paren {
				pos = pos.merge(tail.pos)
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

fn (mut p Parser) parse_call_args() ?[]ast.Expr {
	mut args := []ast.Expr{}
	if p.kind(0) != .r_paren {
		for {
			args << p.parse_expr(.toplevel) ?
			if p.kind(0) == .r_paren {
				break
			}
			p.consume_with_check(.comma) ?
		}
	}
	return args
}

fn (mut p Parser) parse_call_expr_with_left(left ast.Expr) ?ast.Expr {
	$if trace_parser ? {
		p.trace_begin(@FN, '${struct_name(left)}{...}')
		defer {
			p.trace_end()
		}
	}

	p.consume_with_assert(.l_paren)

	mut args := p.parse_call_args() ?
	r_paren := p.consume_with_check(.r_paren) ?
	return ast.CallExpr{
		scope: p.scope
		pos: left.pos().merge(r_paren.pos)
		func: left
		args: args
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
	index := p.parse_expr(.toplevel) ?
	r_bracket := p.consume_with_check(.r_bracket) ?
	return ast.IndexExpr{
		left: left
		index: index
		pos: left.pos().merge(r_bracket.pos)
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
		.int_lit {
			p.consume()
			return ast.IntLiteral{
				scope: p.scope
				token: tok
			}
		}
		.float_lit {
			p.consume()
			return ast.FloatLiteral{
				scope: p.scope
				token: tok
			}
		}
		.string_lit {
			p.consume()
			return ast.StringLiteral{
				scope: p.scope
				token: tok
			}
		}
		.bool_lit {
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
			else { break }
		}
	}
	return expr
}
