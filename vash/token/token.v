module token

import vash.pos { Pos }

pub enum TokenKind {
	unknown
	ident
	key_let
	key_if
	int_lit
	bool_lit
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
	eol
	eof
}

pub enum TokenKindClass {
	op
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
	]
}

[inline]
fn (k TokenKind) is_literal() bool {
	return k in [
		.int_lit,
		.bool_lit,
	]
}

[inline]
fn (k TokenKind) is_keyword() bool {
	return k in [
		.key_let,
		.key_if,
	]
}

[inline]
pub fn (k TokenKind) @is(class TokenKindClass) bool {
	return match class {
		.op { k.is_op() }
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
