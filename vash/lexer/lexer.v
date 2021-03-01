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

[inline]
fn (lex &Lexer) idx() int {
	return lex.pos.i + lex.pos.len - 1
}

[inline]
fn (lex &Lexer) letter() Letter {
	return lex.source.at(lex.idx())
}

[inline]
fn (mut lex Lexer) close() {
	lex.closed = true
}

[inline]
pub fn (lex &Lexer) is_eof() bool {
	return !(lex.idx() < lex.source.code.len)
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

fn (mut lex Lexer) read_letter_token(kind TokenKind) Token {
	lex.advance(1)
	return lex.new_token(kind)
}

[inline]
fn (mut lex Lexer) advance(n int) {
	lex.pos.len += lex.letter().len
	lex.pos.last_col += n
}

[inline]
fn (lex &Lexer) is_whitespace() bool {
	return lex.letter().is_whitespace()
}

fn (mut lex Lexer) skip_whitespaces() {
	for !lex.is_eof() && lex.is_whitespace() {
		lex.advance(1)
	}
}

fn (mut lex Lexer) start() {
	// if pos is head, do nothing
	if lex.idx() == 0 {
		return
	}

	lex.pos = pos.new(
		i: lex.idx()
		col: lex.pos.last_col
		line: lex.pos.last_line
	)
}

[inline]
fn (lex &Lexer) text() string {
	return lex.source.slice(lex.pos.i, lex.idx())
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
		return lex.read_letter_token(kind)
	}

	for !(lex.is_eof() || lex.is_whitespace()) {
		lex.advance(1)
	}
	return lex.new_token(.unknown)
}
