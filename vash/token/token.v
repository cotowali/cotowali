module token

import vash.pos { Pos }

enum Kind {
	unknown
}

struct Token {
pub:
	kind Kind
	text string
	pos  Pos
}
