module token

import cotowali.source { Pos }

pub enum TokenKind {
	unknown
	at_ident
	ident
	key_as
	key_assert
	key_decl
	key_else
	key_export
	key_fn
	key_for
	key_if
	key_in
	key_require
	key_return
	key_struct
	key_use
	key_var
	key_while
	key_yield
	inline_shell
	comma
	hash
	dot
	dotdotdot
	amp
	question
	int_lit
	float_lit
	bool_lit
	string_lit
	l_paren
	r_paren
	l_brace
	r_brace
	l_bracket
	r_bracket
	pipe
	plus
	minus
	div
	mul
	mod
	logical_and
	logical_or
	assign
	not
	eq
	ne
	gt
	ge
	lt
	le
	plus_plus
	minus_minus
	eol
	eof
}

[inline]
fn (k TokenKind) is_op() bool {
	return k in [
		.pipe,
		.plus,
		.minus,
		.div,
		.mul,
		.mod,
		.logical_and,
		.logical_and,
		.assign,
		.not,
		.eq,
		.ne,
		.gt,
		.ge,
		.lt,
		.le,
	]
}

[inline]
fn (k TokenKind) is_comparsion_op() bool {
	return k in [
		.eq,
		.ne,
		.gt,
		.ge,
		.lt,
		.le,
	]
}

[inline]
fn (k TokenKind) is_logical_infix_op() bool {
	return k in [.logical_and, .logical_or]
}

[inline]
fn (k TokenKind) is_prefix_op() bool {
	return k in [
		.amp,
		.plus,
		.minus,
		.not,
	]
}

[inline]
fn (k TokenKind) is_postfix_op() bool {
	return k in [
		.plus_plus,
		.minus_minus,
	]
}

[inline]
fn (k TokenKind) is_infix_op() bool {
	return k.is_comparsion_op() || k.is_logical_infix_op()
		|| k in [.pipe, .plus, .minus, .mul, .div, .mod]
}

[inline]
fn (k TokenKind) is_literal() bool {
	return k in [
		.int_lit,
		.float_lit,
		.bool_lit,
		.string_lit,
	]
}

[inline]
fn (k TokenKind) is_keyword() bool {
	return k in [
		.key_as,
		.key_assert,
		.key_decl,
		.key_else,
		.key_export,
		.key_fn,
		.key_for,
		.key_if,
		.key_in,
		.key_require,
		.key_return,
		.key_struct,
		.key_use,
		.key_var,
		.key_while,
		.key_yield,
	]
}

pub enum TokenKindClass {
	op
	comparsion_op
	infix_op
	logical_infix_op
	prefix_op
	postfix_op
	literal
	keyword
}

[inline]
pub fn (k TokenKind) @is(class TokenKindClass) bool {
	return match class {
		.op { k.is_op() }
		.comparsion_op { k.is_comparsion_op() }
		.logical_infix_op { k.is_logical_infix_op() }
		.infix_op { k.is_infix_op() }
		.prefix_op { k.is_prefix_op() }
		.postfix_op { k.is_postfix_op() }
		.literal { k.is_literal() }
		.keyword { k.is_keyword() }
	}
}

pub struct Token {
pub:
	kind TokenKind
	text string
	pos  Pos
}

pub type TokenCond = fn (Token) bool

pub fn (lhs Token) == (rhs Token) bool {
	return if lhs.pos.is_none() || rhs.pos.is_none() {
		lhs.kind == rhs.kind && lhs.text == rhs.text
	} else {
		lhs.kind == rhs.kind && lhs.text == rhs.text && lhs.pos == rhs.pos
	}
}

[inline]
fn (t Token) text_for_str() string {
	return t.text.replace_each(['\\', '\\\\', '\n', r'\n', '\r', r'\r'])
}

pub fn (t Token) str() string {
	return "Token{ .$t.kind, '$t.text_for_str()', $t.pos }"
}

pub fn (t Token) short_str() string {
	return "{ .$t.kind, '$t.text_for_str()' }"
}
