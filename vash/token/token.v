module token

import vash.pos { Pos }

pub enum TokenKind {
	unknown
	l_par
	r_par
	eof
}

pub struct Token {
pub:
	kind TokenKind
	text string
	pos  Pos
}
