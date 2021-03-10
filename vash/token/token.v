module token

import vash.pos { Pos }

pub enum TokenKind {
	unknown
	ident
	key_let
	int_lit
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
	eol
	eof
}

pub enum TokenKindClass {
	op
}

[inline]
pub fn (k TokenKind) @is(class TokenKindClass) bool {
	return match class {
		.op { k in [.op_plus, .op_minus, .op_div, .op_mul] }
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
