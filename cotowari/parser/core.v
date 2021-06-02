module parser

import cotowari.lexer { Lexer }
import cotowari.token { Token, TokenCond, TokenKind, TokenKindClass }
import cotowari.config { Config }
import cotowari.ast
import cotowari.symbols { Scope, new_global_scope }
import cotowari.tracer { Tracer }
import cotowari.errors { unreachable }

pub struct Parser {
pub:
	config &Config
mut:
	count       int // counter to avoid some duplication (tmp name, etc...)
	tracer      Tracer
	brace_depth int
	lexer       Lexer
	prev_tok    Token
	buf         []Token
	token_idx   int
	file        &ast.File
	scope       &Scope

	restore_strategy RestoreStrategy
}

fn (mut p Parser) debug() {
	mut tokens := []Token{len: p.buf.len}
	for i, _ in tokens {
		tokens[i] = p.token(i)
	}
	p.tracer.write_object('Parser', map{
		'brace_depth':      p.brace_depth.str()
		'prev_tok':         p.prev_tok.str()
		'tokens':           tokens.str()
		'restore_strategy': p.restore_strategy.str()
	})
}

[inline]
fn (mut p Parser) trace_begin(f string, args ...string) {
	$if trace_parser ? {
		p.tracer.begin_fn(f, ...args)
		p.tracer.writeln('token: ${p.token(0)}')
	}
}

[inline]
fn (mut p Parser) trace_end() {
	$if trace_parser ? {
		p.tracer.end_fn()
	}
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

fn (mut p Parser) read_token() Token {
	tok := p.lexer.read() or {
		if err is errors.ErrWithToken {
			p.syntax_error(err.msg, err.token.pos)
			return err.token
		}
		panic(unreachable)
	}
	return tok
}

pub fn (mut p Parser) consume() Token {
	t := p.token(0)
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
	if p.kind(0) == .eol {
		p.consume_with_assert(.eol)
	}
}

fn (mut p Parser) skip_eol() {
	p.consume_for(fn (t Token) bool {
		return t.kind == .eol
	})
}

fn (mut p Parser) consume_with_check(kinds ...TokenKind) ?Token {
	found := p.consume()
	return if found.kind !in kinds { p.unexpected_token_error(found, ...kinds) } else { found }
}

fn (mut p Parser) consume_with_assert(kinds ...TokenKind) Token {
	$if debug {
		assert p.kind(0) in kinds
	}
	return p.consume()
}

[inline]
pub fn new_parser(lexer Lexer) Parser {
	scope := new_global_scope()
	mut p := Parser{
		lexer: lexer
		config: lexer.config
		buf: []Token{len: 3}
		scope: scope
		file: &ast.File{
			source: lexer.source
			scope: scope
		}
	}
	for _ in 0 .. p.buf.len {
		p.consume()
	}
	p.token_idx = 0
	return p
}

[inline]
fn (mut p Parser) open_scope(name string) &Scope {
	p.scope = p.scope.create_child(name)
	return p.scope
}

[inline]
fn (mut p Parser) close_scope() &Scope {
	p.scope = p.scope.parent() or { panic(err) }
	return p.scope
}
