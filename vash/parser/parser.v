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

pub fn (mut p Parser) consume() Token {
	t := p.token(0)
	p.buf[p.token_idx % p.buf.len] = p.lexer.read()
	p.token_idx++
	return t
}

fn (mut p Parser) consume_with_check(kind TokenKind) ? {
	if p.kind(0) != kind {
		return IError(p.error('expcet `$kind`, but found `${p.token(0).text}`'))
	}
	p.consume()
}

fn (mut p Parser) consume_with_assert(kind TokenKind) {
	@assert(p.kind(0) == kind, 'p.kind(0) = ${p.kind(0)}; kind = $kind',
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
	p.file.stmts = p.stmts()
	return p.file
}

pub fn parse_file(path string) ?ast.File {
	s := source.read_file(path) ?
	mut p := new(lexer.new(s))
	return p.parse()
}

fn (mut p Parser) stmts() []ast.Stmt {
	stmt := p.parse_stmt() or {
		return []
	}
	return [stmt]
}

fn (mut p Parser) parse_stmt() ?ast.Stmt {
	return match p.kind(0) {
		.key_fn { ast.Stmt(p.parse_fn_decl()) }
		else {
			expr := p.parse_expr() ?
			ast.Stmt(expr)
		}
	}
}

fn (mut p Parser) parse_fn_decl() ast.FnDecl {
	p.consume_with_assert(.key_fn)
	name := p.consume().text
	mut node := ast.FnDecl {
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

fn (mut p Parser) parse_expr() ?ast.Expr {
	match p.token(0).kind {
		.ident { return p.parse_call_fn() }
		else { return p.parse_value() }
	}
}

fn (mut p Parser) parse_call_fn() ?ast.Expr {
	name := p.consume().text
	p.consume_with_check(.l_paren) ?
	exprs := [p.parse_expr() ?]
	f := ast.CallFn{
		name: name
		args: exprs
	}
	p.consume_with_check(.r_paren) ?
	return f
}

fn (mut p Parser) parse_value() ?ast.Expr {
	tok := p.token(0)
	match tok.kind {
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
