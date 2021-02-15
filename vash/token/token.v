module token

enum Kind {
	unknown
}

struct Token {
pub:
	kind Kind
	text string
	pos  Pos
}
