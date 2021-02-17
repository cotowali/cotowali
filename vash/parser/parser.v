module parser

import vash.source { Source }
import vash.lexer { Lexer }
import vash.ast

pub struct Parser {
mut:
	lexer Lexer
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
