// Copyright (c) 2021 The Cotowali Authors. All rights reserved.
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
module lexer

import cotowali.source { Char, CharCond, Pos, Source, pos }
import cotowali.token { Token, TokenKind }
import cotowali.context { Context }
import cotowali.util { min }
import cotowali.errors { ErrWithToken, unreachable }
import cotowali.debug { Tracer }

pub struct Lexer {
pub:
	source &Source
	ctx    &Context
mut:
	prev_char Char
	pos       Pos
	closed    bool // for iter

	tracer Tracer [if trace_lexer ?]
}

pub fn new_lexer(source &Source, ctx &Context) &Lexer {
	return &Lexer{
		source: source
		ctx: ctx
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

fn (mut lex Lexer) start_pos() {
	lex.pos = pos(
		i: lex.idx()
		col: lex.pos.last_col
		line: lex.pos.last_line
	)
}

// --

[if trace_lexer ?]
fn (mut lex Lexer) trace_begin(f string, args ...string) {
	lex.tracer.begin_fn(f, ...args)
	lex.tracer.write_field('char', lex.char(0).replace_each(['\n', r'\n', '\r', r'\r']))
}

[if trace_lexer ?]
fn (mut lex Lexer) trace_end() {
	lex.tracer.end_fn()
}

// --

fn (mut lex Lexer) error(token Token, msg string) IError {
	$if trace_lexer ? {
		lex.trace_begin(@FN, '$token', msg)
		defer {
			lex.trace_end()
		}
	}
	return &ErrWithToken{
		source: lex.source
		token: token
		msg: msg
	}
}

// --

fn tk(k TokenKind) TokenKind {
	return k
}

fn (lex &Lexer) pos_for_new_token() Pos {
	pos := lex.pos
	last_col := pos.last_col - 1
	last_line := pos.last_line +
		(if last_col == 0 || lex.prev_char().byte() in [`\n`, `\r`] { -1 } else { 0 })
	return Pos{
		...pos
		len: pos.len - 1
		line: min(pos.line, last_line)
		last_line: last_line
		// last_col becomes 0 at the beginning of the file or right after eol.
		// So use col when last_col is 0
		last_col: if last_col == 0 { pos.col } else { last_col }
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

fn (lex &Lexer) byte() byte {
	return lex.char(0).byte()
}

fn (lex &Lexer) char(n int) Char {
	if lex.is_eof() {
		return Char('\uFFFF')
	}
	mut idx := lex.idx()
	mut c := lex.source.at(idx)
	match n {
		0 {}
		1 {
			idx += utf8_char_len(c.byte())
			c = if idx < lex.source.code.len { lex.source.at(idx) } else { Char('\uFFFF') }
		}
		else {
			for _ in 0 .. n {
				idx += utf8_char_len(c.byte())
				if idx >= lex.source.code.len {
					return Char('\uFFFF')
				}
				c = lex.source.at(idx)
			}
		}
	}
	return c
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
	lex.start_pos()
}

[inline]
fn (mut lex Lexer) consume() {
	c := lex.char(0)
	lex.prev_char = c
	lex.pos.len += c.len
	lex.pos.last_col += utf8_str_visible_length(c)
	if c.byte() == `\n` || (c.byte() == `\r` && lex.char(1).byte() != `\n`) {
		lex.pos.last_col = 1
		lex.pos.last_line++
	}
}

[inline]
fn (lex Lexer) @assert(cond CharCond) {
	$if debug {
		if !cond(lex.char(0)) {
			dump(lex.char(0))
			panic(unreachable(''))
		}
	}
}

fn (mut lex Lexer) consume_with_assert(cond CharCond) {
	$if debug {
		lex.@assert(cond)
	}
	lex.consume()
}

fn (mut lex Lexer) skip_with_assert(cond CharCond) {
	$if debug {
		lex.@assert(cond)
	}
	lex.skip()
}

fn (mut lex Lexer) consume_for(cond CharCond) {
	for !lex.is_eof() && cond(lex.char(0)) {
		lex.consume()
	}
}

fn (mut lex Lexer) consume_not_for(cond CharCond) {
	for !lex.is_eof() && !cond(lex.char(0)) {
		lex.consume()
	}
}

fn (mut lex Lexer) skip_for(cond CharCond) {
	lex.consume_for(cond)
	lex.start_pos()
}

fn (mut lex Lexer) skip_not_for(cond CharCond) {
	lex.consume_not_for(cond)
	lex.start_pos()
}
