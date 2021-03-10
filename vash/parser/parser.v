module parser

import vash.source { Source }
import vash.lexer { Lexer }
import vash.token { Token }
import vash.ast

pub struct Parser {
mut:
	lexer Lexer
	buf []Token
	token_idx int
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

pub fn (mut p Parser) read() Token {
	p.buf[p.token_idx % p.buf.len] = p.lexer.read()
	p.token_idx++
	return p.token(0)
}

[inline]
pub fn new(lexer Lexer) Parser {
	mut p := Parser{
		lexer: lexer
		buf: []Token{len: 3}  // LL(3)
	}
	for _ in 0..p.buf.len {
		p.read()
	}
	p.token_idx = 0
	return p
}

pub fn (p &Parser) source() Source {
	return p.lexer.source
}

pub fn (mut p Parser) parse() ?ast.File {
	return ast.File{
		path: p.source().path
	}
}
