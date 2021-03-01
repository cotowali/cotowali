module lexer

import vash.token { Token, TokenKind }
import vash.pos { Pos }

fn test(code string, tokens []Token) {
	lexer := new(path: '', code: code)
	mut i := 0
	for t1 in lexer {
		t2 := tokens[i]
		assert t1 == t2
		i++
	}
}

fn t(kind TokenKind, text string, pos Pos) Token {
	return Token{kind, text, pos}
}

fn test_lexer() {
	test(' _🐈_ a ', [
		// Pos{i, line, col, len, last_line, last_col}
		t(.unknown, '_🐈_', Pos{1, 1, 2, 6, 1, 4}),
		t(.unknown, 'a', Pos{8, 1, 6, 1, 1, 6}),
		t(.eof, '', Pos{10, 1, 8, 1, 1, 8}),
	])
}
