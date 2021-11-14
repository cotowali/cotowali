// Copyright (c) 2021 zakuro <z@kuro.red>. All rights reserved.
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
module parser

import cotowali.lexer { Lexer, new_lexer }
import cotowali.token { Token, TokenCond, TokenKind, TokenKindClass }
import cotowali.context { Context }
import cotowali.symbols { Scope }
import cotowali.debug { Tracer }
import cotowali.messages { unreachable }
import cotowali.errors { LexerErr, LexerWarn }
import cotowali.source { Pos, Source }

pub struct Parser {
pub mut:
	ctx &Context
mut:
	count       int // counter to avoid some duplication (tmp name, etc...)
	brace_depth int
	lexer       Lexer
	prev_tok    Token
	buf         []Token
	token_idx   int
	scope       &Scope

	if_directive_depth int

	restore_strategy RestoreStrategy

	tracer Tracer [if trace_parser ?]
}

[inline]
fn (mut p Parser) source() &Source {
	return p.lexer.source
}

fn (mut p Parser) debug() {
	mut tokens := []Token{len: p.buf.len}
	for i, _ in tokens {
		tokens[i] = p.token(i)
	}
	p.tracer.write_object('Parser', {
		'brace_depth':      p.brace_depth.str()
		'prev_tok':         p.prev_tok.str()
		'tokens':           tokens.str()
		'restore_strategy': p.restore_strategy.str()
	})
}

[inline; if trace_parser ?]
fn (mut p Parser) trace_begin(f string, args ...string) {
	p.tracer.begin_fn(f, ...args)
}

[inline; if trace_parser ?]
fn (mut p Parser) trace_end() {
	p.tracer.end_fn()
}

pub fn (p &Parser) token(i int) Token {
	if i >= p.buf.len {
		panic('cannot take token($i) (p.buf.len = $p.buf.len)')
	}
	if i < 0 {
		if i == -1 {
			return p.prev_tok
		}
		panic('cannot take negative token($i)')
	}
	return p.buf[(p.token_idx + i) % p.buf.len]
}

[inline]
pub fn (p &Parser) kind(i int) TokenKind {
	return p.token(i).kind
}

[inline]
pub fn (p &Parser) pos(i int) Pos {
	return p.token(i).pos
}

fn (mut p Parser) read_token() Token {
	tok := p.lexer.read() or {
		match err {
			LexerErr {
				p.syntax_error(err.msg, err.token.pos)
				return err.token
			}
			LexerWarn {
				p.warn(err.msg, err.token.pos)
				return err.token
			}
			else {}
		}
		panic(unreachable(err))
	}
	return tok
}

pub fn (mut p Parser) consume() Token {
	t := p.token(0)
	$if trace_parser ? {
		p.trace_begin(@FN)
		defer {
			p.tracer.write_field('token', t.short_str())
			p.trace_end()
		}
	}
	match t.kind {
		.l_brace { p.brace_depth++ }
		.r_brace { p.brace_depth-- }
		else {}
	}
	last_idx := p.token_idx % p.buf.len
	p.prev_tok = p.buf[last_idx]
	p.buf[last_idx] = p.read_token()
	p.token_idx++
	return t
}

fn (mut p Parser) consume_for(cond TokenCond) []Token {
	mut tokens := []Token{}
	for cond(p.token(0)) {
		tokens << p.consume()
	}
	return tokens
}

fn (mut p Parser) consume_if(cond TokenCond) ?Token {
	if cond(p.token(0)) {
		return p.consume()
	}
	return none
}

fn (mut p Parser) consume_if_kind_eq(kind TokenKind) ?Token {
	if p.kind(0) == kind {
		return p.consume()
	}
	return none
}

fn (mut p Parser) consume_if_kind_is(class TokenKindClass) ?Token {
	if p.kind(0).@is(class) {
		return p.consume()
	}
	return none
}

fn (mut p Parser) skip_until_eol() {
	p.consume_for(fn (t Token) bool {
		return t.kind !in [.eol, .eof]
	})
}

fn (mut p Parser) skip_eol() {
	p.consume_for(fn (t Token) bool {
		return t.kind == .eol
	})
}

fn (mut p Parser) check(kinds ...TokenKind) ?Token {
	found := p.token(0)
	return if found.kind !in kinds { p.unexpected_token_error(found, ...kinds) } else { found }
}

fn (mut p Parser) consume_with_check(kinds ...TokenKind) ?Token {
	p.check(...kinds) ?
	return p.consume()
}

fn (mut p Parser) consume_with_assert(kinds ...TokenKind) Token {
	$if debug {
		assert p.kind(0) in kinds
	}
	return p.consume()
}

pub fn new_parser(source &Source, ctx &Context) Parser {
	mut p := Parser{
		lexer: new_lexer(source, ctx)
		ctx: ctx
		buf: []Token{len: 3}
		scope: ctx.global_scope
	}
	for _ in 0 .. p.buf.len {
		p.consume()
	}
	p.token_idx = 0
	return p
}

fn (mut p Parser) open_scope(name string) &Scope {
	p.scope = p.scope.get_or_create_child(name)
	p.scope.pos = p.pos(0)
	return p.scope
}

fn (mut p Parser) close_scope() &Scope {
	p.scope.pos = p.scope.pos.merge(p.pos(0))
	p.scope = p.scope.parent() or { panic(err) }
	return p.scope
}
