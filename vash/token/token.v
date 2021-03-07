module token

import vash.pos { Pos }

pub enum TokenKind {
	unknown
	ident
	key_let
	int_lit
	l_par
	r_par
	plus
	minus
	eol
	eof
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
