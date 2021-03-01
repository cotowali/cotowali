module lexer

import vash.token { TokenKind }
import vash.source { Letter }

fn kind(k TokenKind) TokenKind {
	return k
}

fn letter_to_kind(letter Letter) ?TokenKind {
	r := letter.rune()
	return rune_to_kind_table[r] or { return none }
}

const (
	rune_to_kind_table = map{
		`(`: kind(.l_par),
		`)`: kind(.r_par),
	}
)
