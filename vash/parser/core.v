module parser

import vash.source { Source }
import vash.lexer { Lexer }
import vash.token { Token, TokenKind }
import vash.ast
import vash.errors

pub struct Parser {
mut:
	brace_depth int
	lexer       Lexer
	buf         []token.Token
	token_idx   int
	file        ast.File
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
	match t.kind {
		.l_brace { p.brace_depth++ }
		.r_brace { p.brace_depth-- }
		else {}
	}
	p.buf[p.token_idx % p.buf.len] = p.lexer.read()
	p.token_idx++
	return t
}

type TokenCond = fn (Token) bool

fn (mut p Parser) consume_for(cond TokenCond) []Token {
	mut tokens := []Token{}
	for cond(p.token(0)) {
		tokens << p.consume()
	}
	return tokens
}

fn (mut p Parser) consume_if(cond TokenCond) ?Token {
	if cond(p.token(0)) {
		return p.consume()
	}
	return none
}

fn (mut p Parser) consume_if_kind_is(kind TokenKind) ?Token {
	if p.@is(kind) {
		return p.consume()
	}
	return none
}

fn (mut p Parser) skip_until_eol() {
	p.consume_for(fn (t Token) bool {
		return t.kind !in [.eol, .eof]
	})
	if p.@is(.eol) {
		p.consume_with_assert(.eol)
	}
}

fn (mut p Parser) skip_eol() {
	p.consume_for(fn (t Token) bool {
		return t.kind == .eol
	})
}

fn (mut p Parser) consume_with_check(kinds ...TokenKind) ?Token {
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
	return p.consume()
}

fn (mut p Parser) consume_with_assert(kinds ...TokenKind) Token {
	$if !prod {
		assert p.kind(0) in kinds
	}
	return p.consume()
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

fn (mut p Parser) error(msg string) &errors.Error {
	err := &errors.Error{
		msg: msg
	}
	p.consume()
	p.file.errors << err
	return err
}

fn error_node(err IError) &errors.Error {
	if err is errors.Error {
		return err
	}
	panic(err)
}
