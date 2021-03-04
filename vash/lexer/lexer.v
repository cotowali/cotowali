module lexer

import vash.source { Letter, Source }
import vash.token { Token, TokenKind }
import vash.pos { Pos }

pub struct Lexer {
pub mut:
	source Source
mut:
	pos    Pos
	closed bool // for iter
}

pub fn new(source Source) Lexer {
	return Lexer{
		source: source
	}
}

pub fn (mut lex Lexer) next() ?Token {
	if lex.closed {
		return none
	}

	lex.skip_whitespaces()
	lex.start()
	if lex.is_eof() {
		lex.close()
		return Token{.eof, '', lex.pos}
	}

	if kind := letter_to_kind(lex.letter()) {
		lex.advance(1)
		return lex.new_token(kind)
	}

	for !(lex.is_eof() || lex.letter().is_whitespace()) {
		if _ := letter_to_kind(lex.letter()) {
			break
		}
		lex.advance(1)
	}
	return lex.new_token(.unknown)
}


[inline]
fn (mut lex Lexer) is_eof() bool {
	return !(lex.idx() < lex.source.code.len)
}

fn (mut lex Lexer) skip_whitespaces() {
	for !lex.is_eof() && lex.letter().is_whitespace() {
		lex.advance(1)
	}
}
