module token

import vash.pos { Pos }

pub enum TokenKind {
	unknown
	eof
}

pub struct Token {
pub:
	kind TokenKind
	text string
	pos  Pos
}
