module lexer

import cotowari.token { Token, TokenKind }
import cotowari.pos { Pos }

fn test(code string, tokens []Token) {
	lexer := new(path: '', code: code)
	mut i := 0
	for t1 in lexer {
		if !(i < tokens.len) {
			assert t1.kind == .eof
			return
		}
		t2 := tokens[i]
		assert t1 == t2
		i++
	}
}

fn ktest(code string, kinds []TokenKind) {
	lexer := new(path: '', code: code)
	mut i := 0
	for t1 in lexer {
		if !(i < kinds.len) {
			assert t1.kind == .eof
			return
		}
		k2 := kinds[i]
		assert t1.kind == k2
		i++
	}
}

fn t(kind TokenKind, text string) Token {
	return Token{kind, text, pos.new_none()}
}

fn test_lexer() {
	test(' 🐈__ a ', [
		// Pos{i, line, col, len, last_line, last_col}
		Token{.unknown, '🐈__', Pos{1, 1, 2, 6, 1, 4}},
		Token{.ident, 'a', Pos{8, 1, 6, 1, 1, 6}},
		Token{.eof, '', Pos{10, 1, 8, 1, 1, 8}},
	])

	ktest('fn f(a, b) {}', [.key_fn, .ident, .l_paren, .ident, .comma, .ident, .r_paren, .l_brace,
		.r_brace, .eof])
	ktest('let i = 0', [.key_let, .ident, .op_assign, .int_lit, .eof])
	ktest('&a.b | c', [.amp, .ident, .dot, .ident, .pipe, .ident, .eof])
	ktest('a && b || c &', [.ident, .op_and, .ident, .op_or, .ident, .amp, .eof])

	test('if i == 0 { } else if i == 1 {} else {}', [
		t(.key_if, 'if'),
		t(.ident, 'i'),
		t(.op_eq, '=='),
		t(.int_lit, '0'),
		t(.l_brace, '{'),
		t(.r_brace, '}'),
		t(.key_else, 'else'),
		t(.key_if, 'if'),
		t(.ident, 'i'),
		t(.op_eq, '=='),
		t(.int_lit, '1'),
		t(.l_brace, '{'),
		t(.r_brace, '}'),
		t(.key_else, 'else'),
		t(.l_brace, '{'),
		t(.r_brace, '}'),
		t(.eof, ''),
	])

	test('\n\r\n\r', [
		t(.eol, '\n'),
		t(.eol, '\r\n'),
		t(.eol, '\r'),
		t(.eof, ''),
		t(.eof, ''),
	])

	test('{(true + false - 2 * 3 / x) == 0}', [
		t(.l_brace, '{'),
		t(.l_paren, '('),
		t(.bool_lit, 'true'),
		t(.op_plus, '+'),
		t(.bool_lit, 'false'),
		t(.op_minus, '-'),
		t(.int_lit, '2'),
		t(.op_mul, '*'),
		t(.int_lit, '3'),
		t(.op_div, '/'),
		t(.ident, 'x'),
		t(.r_paren, ')'),
		t(.op_eq, '=='),
		t(.int_lit, '0'),
		t(.r_brace, '}'),
		t(.eof, ''),
	])
}

fn test_ident() {
	texts := ['a', '@a.a', '@./a.a', '@/usr/local/bin/', '@~/.bin/cmd.py']
	for text in texts {
		ktest(text, [.ident, .eof])
	}
}
