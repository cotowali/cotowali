module parser

import cotowari.source { Source }
import cotowari.lexer { Lexer }
import cotowari.token { Token, TokenKind }
import cotowari.ast
import cotowari.errors
import cotowari.symbols { Scope, new_global_scope }

pub struct Parser {
mut:
	count       int // counter to avoid some duplication (tmp name, etc...)
	brace_depth int
	lexer       Lexer
	buf         []Token
	token_idx   int
	file        ast.File
	scope       &Scope
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

[inline]
fn (p &Parser) @is(kind TokenKind) bool {
	return p.kind(0) == kind
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

fn (mut p Parser) consume_if_kind_is(kind TokenKind) ?Token {
	if p.@is(kind) {
		return p.consume()
	}
	return none
}

fn (mut p Parser) skip_until_eol() {
	p.consume_for(fn (t Token) bool {
		return t.kind !in [.eol, .eof]
	})
	if p.@is(.eol) {
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
		found := p.token(0).text
		if kinds.len == 0 {
			return IError(p.error('unexpected token `$found`'))
		}
		mut expect := 'expect '
		if kinds.len == 1 {
			expect = '`$kinds[0].str()`'
		} else {
			expect = '${kinds[..kinds.len - 1].map(it.str()).join(', ')}, or `$kinds.last()`'
		}
		return IError(p.error(expect + ', but found $found'))
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
		buf: []Token{len: 3}
		scope: new_global_scope()
	}
	for _ in 0 .. p.buf.len {
		p.consume()
	}
	p.token_idx = 0
	return p
}

pub fn (p &Parser) source() Source {
	return p.lexer.source
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

fn (mut p Parser) error(msg string) &errors.Error {
	err := &errors.Error{
		msg: msg
	}
	p.consume()
	p.file.errors << err
	return err
}

fn error_node(err IError) &errors.Error {
	if err is errors.Error {
		return err
	}
	panic(err)
}
