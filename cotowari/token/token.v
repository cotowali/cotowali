module token

import cotowari.source { Pos }

pub enum TokenKind {
	unknown
	ident
	key_as
	key_assert
	key_fn
	key_let
	key_if
	key_else
	key_for
	key_in
	key_return
	key_decl
	key_struct
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
	op_plus_plus
	op_minus_minus
	eol
	eof
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
fn (k TokenKind) is_prefix_op() bool {
	return k in [
		.op_plus,
		.op_minus,
		.op_not,
	]
}

[inline]
fn (k TokenKind) is_suffix_op() bool {
	return k in [
		.op_plus_plus,
		.op_minus_minus,
	]
}

[inline]
fn (k TokenKind) is_binary_op() bool {
	return k in [
		.op_eq,
		.op_ne,
		.op_gt,
		.op_lt,
		.op_plus,
		.op_minus,
		.op_mul,
		.op_div,
		.op_mod,
		.op_and,
		.op_or,
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
		.key_as,
		.key_assert,
		.key_fn,
		.key_let,
		.key_if,
		.key_else,
		.key_for,
		.key_in,
		.key_return,
		.key_decl,
		.key_struct,
	]
}

pub enum TokenKindClass {
	op
	comparsion_op
	binary_op
	prefix_op
	suffix_op
	literal
	keyword
}

[inline]
pub fn (k TokenKind) @is(class TokenKindClass) bool {
	return match class {
		.op { k.is_op() }
		.comparsion_op { k.is_comparsion_op() }
		.binary_op { k.is_binary_op() }
		.prefix_op { k.is_prefix_op() }
		.suffix_op { k.is_suffix_op() }
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
