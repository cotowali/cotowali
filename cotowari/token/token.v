module token

import cotowari.source { Pos }

pub enum TokenKind {
	unknown
	ident
	key_assert
	key_fn
	key_let
	key_if
	key_else
	key_for
	key_in
	key_return
	inline_shell
	comma
	dot
	amp
	pipe
	question
	int_lit
	bool_lit
	string_lit
	l_paren
	r_paren
	l_brace
	r_brace
	l_bracket
	r_bracket
	op_plus
	op_minus
	op_div
	op_mul
	op_mod
	op_and
	op_or
	op_assign
	op_not
	op_eq
	op_ne
	op_gt
	op_lt
	eol
	eof
}

pub enum TokenKindClass {
	op
	comparsion_op
	literal
	keyword
}

[inline]
fn (k TokenKind) is_op() bool {
	return k in [
		.op_plus,
		.op_minus,
		.op_div,
		.op_mul,
		.op_mod,
		.op_and,
		.op_or,
		.op_assign,
		.op_not,
		.op_eq,
		.op_ne,
		.op_gt,
		.op_lt,
	]
}

[inline]
fn (k TokenKind) is_comparsion_op() bool {
	return k in [
		.op_eq,
		.op_ne,
		.op_gt,
		.op_lt,
	]
}

[inline]
fn (k TokenKind) is_literal() bool {
	return k in [
		.int_lit,
		.bool_lit,
		.string_lit,
	]
}

[inline]
fn (k TokenKind) is_keyword() bool {
	return k in [
		.key_assert,
		.key_fn,
		.key_let,
		.key_if,
		.key_else,
		.key_for,
		.key_in,
		.key_return,
	]
}

[inline]
pub fn (k TokenKind) @is(class TokenKindClass) bool {
	return match class {
		.op { k.is_op() }
		.comparsion_op { k.is_comparsion_op() }
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

pub fn (lhs Token) == (rhs Token) bool {
	return if lhs.pos.is_none() || rhs.pos.is_none() {
		lhs.kind == rhs.kind && lhs.text == rhs.text
	} else {
		lhs.kind == rhs.kind && lhs.text == rhs.text && lhs.pos == rhs.pos
	}
}

pub fn (t Token) str() string {
	return "Token{ .$t.kind, '$t.text', $t.pos }"
}
