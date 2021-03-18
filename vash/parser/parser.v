module parser

import vash.source { Source }
import vash.lexer { Lexer }
import vash.token { Token, TokenKind }
import vash.ast
import vash.util { @assert }

pub struct Parser {
mut:
	lexer     Lexer
	buf       []token.Token
	token_idx int
	file      ast.File
}

pub fn (p &Parser) token(i int) Token {
	if i >= p.buf.len {
		panic('cannot take token($i) (p.buf.len = $p.buf.len)')
	}
	if i < 0 {
		panic('cannot take negative token($i)')
	}
	return p.buf[(p.token_idx + i) % p.buf.len]
}

[inline]
pub fn (p &Parser) kind(i int) TokenKind {
	return p.token(0).kind
}

[inline]
fn (p &Parser) @is(kind TokenKind) bool {
	return p.kind(0) == kind
}

pub fn (mut p Parser) consume() Token {
	t := p.token(0)
	p.buf[p.token_idx % p.buf.len] = p.lexer.read()
	p.token_idx++
	return t
}

type TokenCond = fn(Token) bool

fn (mut p Parser) consume_for(cond TokenCond) {
	for cond(p.token(0)) {
		p.consume()
	}
}

fn (mut p Parser) consume_if(cond TokenCond) bool {
	if cond(p.token(0)) {
		p.consume()
		return true
	}
	return false
}

fn (mut p Parser) consume_if_kind_is(kind TokenKind) bool {
	if p.@is(kind) {
		p.consume()
		return true
	}
	return false
}

fn (mut p Parser) skip_until_eol() {
	p.consume_for(fn (t Token) bool { return t.kind !in [.eol, .eof] })
	if p.@is(.eol) {
		p.consume_with_assert(.eol)
	}
}

fn (mut p Parser) skip_eol() {
	p.consume_for(fn (t Token) bool { return t.kind == .eol })
}

fn (mut p Parser) consume_with_check(kinds ...TokenKind) ? {
	if p.kind(0) !in kinds {
		found := p.token(0).text
		if kinds.len == 0 {
			return IError(p.error('unexpected token `$found`'))
		}
		mut expect := 'expect '
		if kinds.len == 1 {
			expect = '`${kinds[0]}`'
		} else {
			expect = '${kinds[..kinds.len - 1].map(it.str()).join(', ')}, or `$kinds.last()`'
		}
		return IError(p.error(expect + ', but found $found'))
	}
	p.consume()
}

fn (mut p Parser) consume_with_assert(kinds ...TokenKind) {
	@assert(p.kind(0) in kinds, 'p.kind(0) = ${p.kind(0)}; kinds = $kinds',
		file: @FILE
		name: @FN
		line: @LINE
	)
	p.consume()
}

[inline]
pub fn new(lexer Lexer) Parser {
	mut p := Parser{
		lexer: lexer
		buf: []Token{len: 3} // LL(3)
	}
	for _ in 0 .. p.buf.len {
		p.consume()
	}
	p.token_idx = 0
	return p
}

pub fn (p &Parser) source() Source {
	return p.lexer.source
}

pub fn (mut p Parser) parse() ast.File {
	p.file = ast.File{
		path: p.source().path
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
	return match p.kind(0) {
		.key_fn {
			ast.Stmt(p.parse_fn_decl())
		}
		else {
			stmt := p.parse_expr_stmt() or {
				p.skip_until_eol()
				ast.Stmt(ast.EmptyStmt{})
			}
			stmt  // Hack to avoid V compiler bug
		}
	}
}

fn (mut p Parser) parse_expr_stmt() ?ast.Stmt {
	expr := p.parse_expr({}) ?
	p.consume_with_check(.eol, .eof)?
	return expr
}

fn (mut p Parser) parse_fn_decl() ast.FnDecl {
	p.consume_with_assert(.key_fn)
	name := p.consume().text
	mut node := ast.FnDecl{
		name: name
		stmts: []
	}
	p.consume_with_check(.l_paren) or { return node }
	// todo arg list
	p.consume_with_check(.r_paren) or { return node }

	p.consume_with_check(.l_brace) or { return node }

	for {
		if stmt := p.parse_stmt() {
			node.stmts << stmt
		}
		if p.kind(0) == .r_brace {
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
	return ast.Pipeline {
		exprs: exprs
	}
}

fn (mut p Parser) parse_call_fn() ?ast.Expr {
	name := p.consume().text
	p.consume_with_check(.l_paren) ?
	mut args := []ast.Expr{}
	if !p.@is(.r_paren) {
		args << p.parse_expr({}) ?
	}
	p.consume_with_check(.r_paren) ?
	f := ast.CallFn{
		name: name
		args: args
	}
	return f
}

fn (mut p Parser) parse_value() ?ast.Expr {
	tok := p.token(0)
	match tok.kind {
		.ident {
			return p.parse_call_fn()
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

fn (mut p Parser) error(msg string) &ast.ErrorNode {
	node := &ast.ErrorNode{
		msg: msg
	}
	p.consume()
	p.file.errors << node
	return node
}

fn error_node(err IError) &ast.ErrorNode {
	if err is ast.ErrorNode {
		return err
	}
	panic(err)
}
