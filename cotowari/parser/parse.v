module parser

import cotowari.source
import cotowari.lexer
import cotowari.token { TokenKind }
import cotowari.ast
import cotowari.symbols

pub fn (mut p Parser) parse() ast.File {
	p.file = ast.File{
		path: p.source().path
		scope: p.scope
	}
	for !p.@is(.eof) {
		p.file.stmts << p.parse_stmt()
	}
	return p.file
}

pub fn parse_file(path string) ?ast.File {
	s := source.read_file(path) ?
	mut p := new(lexer.new(s))
	return p.parse()
}

fn (mut p Parser) parse_stmt() ast.Stmt {
	stmt := match p.kind(0) {
		.key_fn {
			p.parse_fn_decl_stmt()
		}
		else {
			expr := p.parse_expr_stmt() or {
				p.skip_until_eol()
				ast.Stmt(ast.EmptyStmt{})
			}
			// Hack to avoid V compiler bug
			expr
		}
	}
	p.skip_eol()
	return stmt
}

fn (mut p Parser) parse_expr_stmt() ?ast.Stmt {
	expr := p.parse_expr({}) ?

	// eol or close blace
	if !(p.brace_depth > 0 && p.@is(.r_brace)) {
		p.consume_with_check(.eol, .eof) ?
	}

	return expr
}

fn (mut p Parser) parse_fn_decl_stmt() ast.Stmt {
	if decl := p.parse_fn_decl() {
		return decl
	}
	p.skip_until_eol()
	return ast.EmptyStmt{}
}

fn (mut p Parser) parse_fn_decl() ?ast.FnDecl {
	p.consume_with_assert(.key_fn)
	name := p.consume().text


	p.scope.register(symbols.new_fn(name)) ?

	p.open_scope(name)
	defer {
		p.close_scope()
	}

	mut node := ast.FnDecl{
		name: name
		scope: p.scope
		stmts: []
		params: []
	}

	p.consume_with_check(.l_paren) ?
	if p.@is(.ident) {
		for {
			ident := p.consume_with_check(.ident) ?
			node.params << (p.scope.register_var(symbols.new_var(ident.text)) ?)
			if p.@is(.r_paren) {
				break
			} else {
				p.consume_with_check(.comma) ?
			}
		}
	}
	p.consume_with_check(.r_paren) ?

	p.consume_with_check(.l_brace) ?
	p.skip_eol()

	for {
		node.stmts << p.parse_stmt()
		if _ := p.consume_if_kind_is(.r_brace) {
			return node
		}
	}
	panic('unreachable code')
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
	p.consume_if_kind_is(.l_paren) or {
		return *symbols.new_var(name)
	}
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
			return IError(p.error('unexpected token $tok'))
		}
	}
}
