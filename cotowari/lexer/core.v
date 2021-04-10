module lexer

import cotowari.source { Char, Source }
import cotowari.token { Token, TokenKind }
import cotowari.pos { Pos }
import cotowari.util { min }

pub struct Lexer {
pub mut:
	source Source
mut:
	prev_char Char
	pos       Pos
	closed    bool // for iter
}

pub fn new_lexer(source Source) &Lexer {
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
	pos := lex.pos
	last_col := pos.last_col - 1
	last_line :=
		pos.last_line + (if last_col == 0 || lex.prev_char()[0] in [`\n`, `\r`] { -1 } else { 0 })
	return Pos{
		...pos
		len: pos.len - 1
		line: min(pos.line, last_line)
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

fn (mut lex Lexer) new_token_with_consume_n(n int, kind TokenKind) Token {
	for _ in 0 .. n {
		lex.consume()
	}
	return lex.new_token(kind)
}

fn (mut lex Lexer) new_token_with_consume_for(cond CharCond, kind TokenKind) Token {
	lex.consume_for(cond)
	return lex.new_token(kind)
}

fn (mut lex Lexer) new_token_with_consume_not_for(cond CharCond, kind TokenKind) Token {
	lex.consume_not_for(cond)
	return lex.new_token(kind)
}

// --

[inline]
fn (lex &Lexer) char() Char {
	if lex.is_eof() {
		return Char('\uFFFF')
	}
	return lex.source.at(lex.idx())
}

[inline]
fn (lex &Lexer) next_char() Char {
	idx := lex.idx() + utf8_char_len(lex.char()[0])
	return if idx < lex.source.code.len { lex.source.at(idx) } else { Char('\uFFFF') }
}

[inline]
fn (lex &Lexer) prev_char() Char {
	return if lex.idx() > 0 { lex.prev_char } else { Char('\uFFFF') }
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
	lex.prev_char = lex.char()
	lex.pos.len += lex.char().len
	lex.pos.last_col++
	if lex.char()[0] == `\n` || (lex.char()[0] == `\r` && lex.next_char()[0] != `\n`) {
		lex.pos.last_col = 1
		lex.pos.last_line++
	}
}

[inline]
fn (lex Lexer) @assert(cond CharCond) {
	$if !prod {
		if !cond(lex.char()) {
			dump(lex.char())
			assert cond(lex.char())
		}
	}
}

[inline]
fn (lex Lexer) assert_by_match_byte(c byte) {
	$if !prod {
		if c != lex.char()[0] {
			dump(lex.char())
			assert c != lex.char()[0]
		}
	}
}

fn (mut lex Lexer) consume_with_assert(cond CharCond) {
	lex.@assert(cond)
	lex.consume()
}

fn (mut lex Lexer) skip_with_assert(cond CharCond) {
	lex.@assert(cond)
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
