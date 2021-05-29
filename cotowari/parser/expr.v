module parser

import cotowari.token { TokenKind }
import cotowari.ast
import cotowari.symbols { new_placeholder_var }
import cotowari.errors { unreachable }

fn (mut p Parser) parse_expr_stmt() ?ast.Stmt {
	$if trace_parser ? {
		p.trace_begin(@FN)
		defer {
			p.trace_end()
		}
	}

	expr := p.parse_expr({}) ?

	// eol or close blace
	if !(p.brace_depth > 0 && p.kind(0) == .r_brace) {
		p.consume_with_check(.eol, .eof) ?
	}

	return expr
}

enum ExprKind {
	toplevel = 0
	pipeline
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
		k(.pipeline):   v(.pipe)
		k(.comparsion): v(.op_eq, .op_ne, .op_gt, .op_lt)
		k(.term):       v(.op_plus, .op_minus)
		k(.factor):     v(.op_mul, .op_div, .op_mod)
	}
}())

fn (e ExprKind) op_kinds() []TokenKind {
	return parser.expr_kind_to_op_table[e] or { panic(unreachable) }
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
			expr: p.parse_expr(.prefix.inner()) ?
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
		.comparsion, .term, .factor { return p.parse_infix_expr(kind) }
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
		typ := p.parse_type() ?
		return ast.AsExpr{
			pos: expr.pos().merge(p.token(-1).pos)
			typ: typ
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
	p.consume_if_kind_eq(.l_paren) or {
		// TODO: Move to checker
		return ast.Var{
			scope: p.scope
			pos: ident.pos
			sym: p.scope.lookup_var(name) or {
				return p.error('undefined variable $name', ident.pos)
			}
		}
	}
	mut args := []ast.Expr{}
	if p.kind(0) != .r_paren {
		for {
			args << p.parse_expr({}) ?
			if p.kind(0) == .r_paren {
				break
			}
			p.consume_with_check(.comma) ?
		}
	}
	r_paren := p.consume_with_check(.r_paren) ?
	f := ast.CallFn{
		scope: p.scope
		pos: ident.pos.merge(r_paren.pos)
		func: ast.Var{p.scope, ident.pos, new_placeholder_var(name)}
		args: args
	}
	return f
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
	if _ := p.consume_if_kind_eq(.r_paren) {
		// []Type{}
		elem_typ := p.parse_type() ?
		p.consume_with_check(.l_brace) ?
		last_tok = p.consume_with_check(.r_brace) ?
		return ast.ArrayLiteral{
			scope: p.scope
			pos: first_tok.pos.merge(last_tok.pos)
			elem_typ: elem_typ
			elements: []
		}
	}
	mut elements := []ast.Expr{}
	for {
		elements << (p.parse_expr({}) ?)
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

fn (mut p Parser) parse_paren_expr() ?ast.Expr {
	l_paren := p.consume()
	expr := p.parse_expr(.toplevel) ?
	r_paren := p.consume_with_check(.r_paren) ?
	return ast.ParenExpr{
		pos: l_paren.pos.merge(r_paren.pos)
		expr: expr
	}
}

fn (mut p Parser) parse_value() ?ast.Expr {
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
		.string_lit {
			p.consume()
			return ast.StringLiteral{
				scope: p.scope
				token: tok
			}
		}
		.l_bracket {
			return p.parse_array_literal()
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
