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

pub fn (mut p Parser) read() Token {
	p.buf[p.idx_in_buf] = p.lexer.next() or { p.buf[p.idx_in_buf] }
	p.idx_in_buf++
	return p.peek(0)
}

[inline]
pub fn new(lexer Lexer) Parser {
	mut p := Parser{
		lexer: lexer
		buf: []Token{len: 3}  // LL(3)
	}
	for i in 0..p.buf.len {
		p.buf[i] = p.lexer.next() or { p.buf[i - 1] } // at least p.lexer.next() returns 1 item, .eof. so (i - 1) >= 0
	}
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
