module lexer

import vash.token { Token, TokenKind }
import vash.pos { Pos }

[flag]
enum TokenMatchOption {
	@none
	ignore_kind
	ignore_pos
	ignore_text
}

struct TokenToTest {
	token Token
	opts  TokenMatchOption
}

fn test(code string, expected_tokens []TokenToTest) {
	lexer := new(path: '', code: code)
	mut i := 0
	for t1 in lexer {
		expected := expected_tokens[i]
		opts := expected.opts
		t2 := expected.token
		if !(opts.has(.ignore_pos) || opts.has(.ignore_text)) {
			assert t1 == t2
		} else {
			if !opts.has(.ignore_pos) {
				assert t1.pos == t2.pos
			}
			if !opts.has(.ignore_text) {
				assert t1.text == t2.text
			}
			if !opts.has(.ignore_kind) {
				assert t1.kind == t2.kind
			}
		}
		i++
	}
}

fn tt(token Token, opts TokenMatchOption) TokenToTest {
	return TokenToTest{token, opts}
}

fn t(kind TokenKind, text string, pos Pos) TokenToTest {
	return tt(Token{kind, text, pos}, .@none)
}

fn t1(kind TokenKind, text string) TokenToTest {
	return tt({ kind: kind, text: text }, .ignore_pos)
}

fn t2(text string, pos Pos) TokenToTest {
	return tt({ text: text, pos: pos }, .ignore_kind)
}

fn t_kind(kind TokenKind) TokenToTest{
	return tt({ kind: kind }, .ignore_pos & .ignore_text)
}

fn t_text(text string) TokenToTest {
	return tt({ text: text }, .ignore_pos & .ignore_kind)
}

fn test_lexer() {
	test(' _🐈_ a ', [
		/* Pos{i, line, col, len, last_line, last_col} */
		t(.unknown, '_🐈_', Pos{1, 1, 2, 6, 1, 4}),
		t(.unknown, 'a', Pos{8, 1, 6, 1, 1, 6}),
		t(.eof, '', Pos{10, 1, 8, 1, 1, 8}),
	])
}
