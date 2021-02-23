module lexer

import vash.token { Token }
import vash.pos { Pos }

[flag]
enum LexerTestOption {
	@none
	ignore_pos
	ignore_text
}

struct LexerTester {
	opts LexerTestOption = .@none
}

fn (t &LexerTester) run(code string, expected_tokens []Token) {
	lexer := new(path: '', code: code.ustring())
	mut i := 0
	for tok in lexer {
		expected := expected_tokens[i]
		if !(t.opts.has(.ignore_pos) || t.opts.has(.ignore_text)) {
			assert tok == expected
		} else {
			if !t.opts.has(.ignore_pos) {
				assert tok.pos == expected.pos
			}
			if !t.opts.has(.ignore_text) {
				assert tok.text == expected.text
			}
		}
		i++
	}
}

fn test_lexer() {
	LexerTester{}.run(' _🐈_ a ', [
		/* Pos{i, line, col, len, last_line, last_col} */
		Token{.unknown, '_🐈_', Pos{1, 1, 2, 3, 1, 4}},
		Token{.unknown, 'a', Pos{5, 1, 6, 1, 1, 6}},
		Token{.eof, '', Pos{7, 1, 8, 1, 1, 8}},
	])
}
