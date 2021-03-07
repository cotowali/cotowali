module lexer

import vash.source { Char, Source }
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

[inline]
fn (lex &Lexer) idx() int {
	return lex.pos.i + lex.pos.len - 1
}

[inline]
fn (mut lex Lexer) close() {
	lex.closed = true
}

[inline]
pub fn (lex &Lexer) is_eof() bool {
	return !(lex.idx() < lex.source.code.len)
}

fn (mut lex Lexer) skip_whitespaces() {
	lex.consume_for(fn (c Char) bool {
		return c.@is(.whitespace)
	})
}

// --

fn k (kind TokenKind) TokenKind {
	return kind
}

fn (lex &Lexer) pos_for_new_token() Pos {
	last_col := lex.pos.last_col - 1
	last_line := lex.pos.last_line + (if last_col == 0 { -1 } else { 0 })
	return Pos{
		...lex.pos
		len: lex.pos.len - 1
		last_line: last_line
		last_col: last_col
	}
}

[inline]
fn (lex &Lexer) new_token(kind TokenKind) Token {
	return Token{
		kind: kind
		text: lex.text()
		pos: lex.pos_for_new_token()
	}
}

fn (mut lex Lexer) new_token_with_consume(kind TokenKind) Token {
	lex.consume()
	return lex.new_token(kind)
}

// --

[inline]
fn (lex &Lexer) char() Char {
	if lex.is_eof() {
		return Char('')
	}
	return lex.source.at(lex.idx())
}

[inline]
fn (lex &Lexer) char_is(class source.CharClass) bool {
	return lex.char().@is(class)
}

[inline]
fn (lex &Lexer) next_char() Char {
	idx := lex.idx() + utf8_char_len(lex.char()[0])
	return if idx < lex.source.code.len { lex.source.at(idx) } else { Char('') }
}

[inline]
fn (lex &Lexer) text() string {
	return lex.source.slice(lex.pos.i, lex.idx())
}

// --

[inline]
fn (mut lex Lexer) consume() {
	lex.pos.len += lex.char().len
	lex.pos.last_col++
}

fn (mut lex Lexer) consume_for(cond fn (Char) bool) {
	for !lex.is_eof() && cond(lex.char()) {
		lex.consume()
	}
}
