module lexer

import vash.source { Char, CharClass, Source }
import vash.token { Token, TokenKind }
import vash.pos { Pos }
import vash.util { @assert }

pub struct Lexer {
pub mut:
	source Source
mut:
	pos    Pos
	closed bool // for iter
}

pub fn new(source Source) &Lexer {
	return &Lexer{
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
fn (lex &Lexer) closed() bool {
	return lex.closed
}

[inline]
pub fn (lex &Lexer) is_eof() bool {
	return !(lex.idx() < lex.source.code.len)
}

fn (mut lex Lexer) start_new_pos() {
	lex.pos = pos.new(
		i: lex.idx()
		col: lex.pos.last_col
		line: lex.pos.last_line
	)
}

// --

fn k(kind TokenKind) TokenKind {
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
fn (mut lex Lexer) skip() {
	lex.consume()
	lex.start_new_pos()
}

[inline]
fn (mut lex Lexer) consume() {
	lex.pos.len += lex.char().len
	lex.pos.last_col++
}

fn (mut lex Lexer) consume_with_assert(cond CharCond) {
	@assert(cond(lex.char()), '', file: @FILE, name: @FN line: @LINE)
	lex.consume()
}

fn (mut lex Lexer) skip_with_assert(cond CharCond) {
	@assert(cond(lex.char()), '', file: @FILE, name: @FN line: @LINE)
	lex.skip()
}

type CharCond = fn (Char) bool

fn (mut lex Lexer) consume_for(cond CharCond) {
	for !lex.is_eof() && cond(lex.char()) {
		lex.consume()
	}
}

fn (mut lex Lexer) consume_not_for(cond CharCond) {
	for !lex.is_eof() && !cond(lex.char()) {
		lex.consume()
	}
}
