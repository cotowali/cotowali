module parser

import cotowari.lexer { Lexer }
import cotowari.token { Token, TokenKind, TokenKindClass }
import cotowari.config { Config }
import cotowari.ast
import cotowari.symbols { Scope, new_global_scope }

pub struct Parser {
pub:
	config &Config
mut:
	count       int // counter to avoid some duplication (tmp name, etc...)
	brace_depth int
	lexer       Lexer
	buf         []Token
	token_idx   int
	file        ast.File
	scope       &Scope
}

[inline]
pub fn (p &Parser) trace(f string, args ...string) {
	$if trace_parser ? {
		eprintln('${f}(${args.join(', ')}) > token: ${p.token(0)}')
	}
}

pub fn (p &Parser) token(i int) Token {
	if i >= p.buf.len {
		panic('cannot take token($i) (p.buf.len = $p.buf.len)')
	}
	if i < 0 {
		panic('cannot take negative token($i)')
	}
	return p.buf[(p.token_idx + i) % p.buf.len]
}

[inline]
pub fn (p &Parser) kind(i int) TokenKind {
	return p.token(i).kind
}

pub fn (mut p Parser) consume() Token {
	t := p.token(0)
	match t.kind {
		.l_brace { p.brace_depth++ }
		.r_brace { p.brace_depth-- }
		else {}
	}
	p.buf[p.token_idx % p.buf.len] = p.lexer.read()
	p.token_idx++
	return t
}

type TokenCond = fn (Token) bool

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
	if p.kind(0) !in kinds {
		found := p.token(0)
		if kinds.len == 0 {
			return p.error('unexpected token `$found.text`', found.pos)
		}
		mut expect := 'expect '
		if kinds.len == 1 {
			expect = '`$kinds[0].str()`'
		} else {
			expect = '${kinds[..kinds.len - 1].map(it.str()).join(', ')}, or `$kinds.last()`'
		}
		return p.error(expect + ', but found `$found.text`', found.pos)
	}
	return p.consume()
}

fn (mut p Parser) consume_with_assert(kinds ...TokenKind) Token {
	$if !prod {
		assert p.kind(0) in kinds
	}
	return p.consume()
}

[inline]
pub fn new_parser(lexer Lexer) Parser {
	mut p := Parser{
		lexer: lexer
		config: lexer.config
		buf: []Token{len: 3}
		scope: new_global_scope()
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
