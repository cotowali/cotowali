module parser

import vash.source { Source }
import vash.lexer { Lexer }
import vash.token { Token }
import vash.ast

pub struct Parser {
mut:
	lexer Lexer
	buf []Token
	idx_in_buf int
}

pub fn (p &Parser) peek(i int) Token {
	return p.buf[(p.idx_in_buf + i) % p.buf.len]
}

pub fn (mut p Parser) read() {
	next_idx := (p.idx_in_buf + 1) % p.buf.len
	p.buf[next_idx] = p.lexer.next() or { p.buf[p.idx_in_buf] }
	p.idx_in_buf = next_idx
}

[inline]
pub fn new(lexer Lexer) Parser {
	return Parser{
		lexer: lexer
	}
}

pub fn (p &Parser) source() Source {
	return p.lexer.source
}

pub fn (mut p Parser) parse() ?ast.File {
	return ast.File{
		path: p.source().path
	}
}
