module parser

import cotowari.token { TokenKind }
import cotowari.ast
import cotowari.symbols

fn (mut p Parser) parse_expr_stmt() ?ast.Stmt {
	expr := p.parse_expr({}) ?

	// eol or close blace
	if !(p.brace_depth > 0 && p.@is(.r_brace)) {
		p.consume_with_check(.eol, .eof) ?
	}

	return expr
}

enum ExprKind {
	toplevel = 0
	pipeline
	add_or_sub
	value
}

fn (k ExprKind) outer() ExprKind {
	return if k == .toplevel { k } else { ExprKind(int(k) - 1) }
}

fn (k ExprKind) inner() ExprKind {
	return if k == .value { k } else { ExprKind(int(k) + 1) }
}

struct InfixExprOpt {
	operand ExprKind
}

fn (mut p Parser) parse_infix_expr(op_kinds []TokenKind, opt InfixExprOpt) ?ast.Expr {
	left := p.parse_expr(opt.operand) ?
	op := p.token(0)
	if op.kind !in op_kinds {
		return left
	}
	p.consume_with_assert(...op_kinds)
	right := p.parse_infix_expr(op_kinds, opt) ?
	return ast.InfixExpr{
		op: op
		left: left
		right: right
	}
}

fn (mut p Parser) parse_expr(kind ExprKind) ?ast.Expr {
	match kind {
		.toplevel {
			return p.parse_expr(kind.inner())
		}
		.pipeline {
			return p.parse_pipeline()
		}
		.add_or_sub {
			return p.parse_infix_expr([.op_plus, .op_minus], operand: kind.inner())
		}
		.value {
			return p.parse_value()
		}
	}
}

fn (mut p Parser) parse_pipeline() ?ast.Expr {
	inner := ExprKind.pipeline.inner()
	expr := p.parse_expr(inner) ?
	if !p.@is(.pipe) {
		return expr
	}
	mut exprs := [expr]
	for p.kind(0) == .pipe {
		p.consume_with_assert(.pipe)
		exprs << p.parse_expr(inner) ?
	}
	return ast.Pipeline{
		exprs: exprs
	}
}

fn (mut p Parser) parse_ident() ?ast.Expr {
	name := p.consume().text
	p.consume_if_kind_is(.l_paren) or { return *symbols.new_scope_var(name, p.scope) }
	mut args := []ast.Expr{}
	if !p.@is(.r_paren) {
		args << p.parse_expr({}) ?
	}
	p.consume_with_check(.r_paren) ?
	f := ast.CallFn{
		func: symbols.new_fn(name)
		args: args
	}
	return f
}

fn (mut p Parser) parse_value() ?ast.Expr {
	tok := p.token(0)
	match tok.kind {
		.ident {
			return p.parse_ident()
		}
		.int_lit {
			p.consume()
			return ast.IntLiteral{
				token: tok
			}
		}
		else {
			p.consume()
			return IError(p.error('unexpected token $tok'))
		}
	}
}
