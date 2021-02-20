module token

import vash.pos { Pos }

pub enum TokenKind {
	unknown
	eof
}

pub struct Token {
pub:
	kind Kind
	text string
	pos  Pos
}
