module lexer

import cotowari.token { Token, TokenKind }
import cotowari.source { Pos, none_pos }

fn test(code string, tokens []Token) {
	lexer := new_lexer(path: '', code: code)
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
	lexer := new_lexer(path: '', code: code)
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
	return Token{kind, text, none_pos}
}

fn test_lexer() {
	cr, lf := '\r', '\n'
	crlf := cr + lf
	test(' "🐈__" a ', [
		// Pos{i, line, col, len, last_line, last_col}
		Token{.string_lit, '🐈__', Pos{1, 1, 2, 8, 1, 6}},
		Token{.ident, 'a', Pos{10, 1, 8, 1, 1, 8}},
		Token{.eof, '', Pos{12, 1, 10, 1, 1, 10}},
	])
	ktest('fn f(a, b){}', [.key_fn, .ident, .l_paren, .ident, .comma, .ident, .r_paren, .l_brace,
		.r_brace, .eof])
	ktest('decl fn f()', [.key_decl, .key_fn, .ident, .l_paren, .r_paren])
	ktest('let i = 0', [.key_let, .ident, .op_assign, .int_lit, .eof])
	ktest('&a.b | c', [.amp, .ident, .dot, .ident, .pipe, .ident, .eof])
	ktest('a && b || c &', [.ident, .op_and, .ident, .op_or, .ident, .amp, .eof])
	ktest('return 0', [.key_return, .int_lit])
	ktest('assert a == b', [.key_assert, .ident, .op_eq, .ident])
	ktest('a < b || c > d', [.ident, .op_lt, .ident, .op_or, .ident, .op_gt, .ident])
	ktest('!cond', [.op_not, .ident])
	ktest('a+++++', [.ident, .op_plus_plus, .op_plus_plus, .op_plus])
	ktest('a-----', [.ident]) // TODO
	ktest('a -----', [.ident, .op_minus_minus, .op_minus_minus, .op_minus])

	test('if i == 0 { } else if i != 1 {} else {}', [
		t(.key_if, 'if'),
		t(.ident, 'i'),
		t(.op_eq, '=='),
		t(.int_lit, '0'),
		t(.l_brace, '{'),
		t(.r_brace, '}'),
		t(.key_else, 'else'),
		t(.key_if, 'if'),
		t(.ident, 'i'),
		t(.op_ne, '!='),
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
	test('a//abc' + cr + 'b//xxx' + lf + 'c//cr' + crlf + 'd//eee', [
		t(.ident, 'a'),
		t(.eol, cr),
		t(.ident, 'b'),
		t(.eol, lf),
		t(.ident, 'c'),
		t(.eol, crlf),
		t(.ident, 'd'),
	])
}

fn test_ident() {
	texts := ['a', '@a.a', '@./a.a', '@/usr/local/bin/', '@~/.bin/cmd.py']
	for text in texts {
		ktest(text, [.ident, .eof])
	}
}

fn test_string() {
	sq, dq := "'", '"'
	test("$dq'abc'$dq", [t(.string_lit, "'abc'")])
	test('$sq"abc"$sq', [t(.string_lit, '"abc"')])
}

fn test_inline_shell() {
	test(r'${echo 1}', [t(.inline_shell, 'echo 1')])
}
