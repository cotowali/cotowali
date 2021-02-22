module lexer

import vash.source { Source }
import vash.token { Token }
import vash.pos { Pos }

fn test_lexer() {
	code := '_🐈_'
	// Pos{i, line, col, len, last_line, last_col}
	tokens := [
		Token{.unknown, '_🐈_', Pos{0, 1, 1, 3, 1, 3}}
		Token{.eof, '', Pos{3, 1, 4, 1, 1, 4}}
	]
	lexer := new(path: '', code: code.ustring())

	mut i := 0
	for tok in lexer {
		expected := tokens[i]
		assert tok == expected
		i++
	}
}
