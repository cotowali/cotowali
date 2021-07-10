module lexer

import cotowali.context { new_default_context }
import cotowali.token { Token, TokenKind }
import cotowali.source { Pos, none_pos }
import cotowali.errors

fn test(code string, tokens []Token) {
	ctx := new_default_context()
	lexer := new_lexer({ path: '', code: code }, ctx)
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
	ctx := new_default_context()
	lexer := new_lexer({ path: '', code: code }, ctx)
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

enum ErrOrOk {
	err
	ok
}

struct EkTestValue {
	kind   TokenKind
	status ErrOrOk
}

fn ek(k TokenKind, s ErrOrOk) EkTestValue {
	return {
		kind: k
		status: s
	}
}

fn (mut lex Lexer) e_read() (Token, ErrOrOk) {
	tok := lex.read() or {
		if err is errors.ErrWithToken {
			return err.token, ErrOrOk.err
		}
		panic(err)
	}
	return tok, ErrOrOk.ok
}

fn ektest(code string, values []EkTestValue) {
	ctx := new_default_context()
	mut lexer := new_lexer({ path: '', code: code }, ctx)
	mut i := 0
	for {
		t1, status := lexer.e_read()
		if !(i < values.len) {
			assert status == .ok
			assert t1.kind == .eof
			return
		}
		got := ek(t1.kind, status)
		want := values[i]
		assert got == want
		i++
	}
}

fn t(kind TokenKind, text string) Token {
	return Token{kind, text, none_pos()}
}

fn test_lexer() {
	cr, lf := '\r', '\n'
	crlf := cr + lf
	test(' "🐈__" a ', [
		// Pos{i, line, col, len, last_line, last_col}
		Token{.string_lit, '🐈__', Pos{1, 1, 2, 8, 1, 7}},
		Token{.ident, 'a', Pos{10, 1, 9, 1, 1, 9}},
		Token{.eof, '', Pos{12, 1, 11, 1, 1, 11}},
	])
	ktest('fn f(a, b){}', [.key_fn, .ident, .l_paren, .ident, .comma, .ident, .r_paren, .l_brace,
		.r_brace, .eof])
	ktest('decl fn f()', [.key_decl, .key_fn, .ident, .l_paren, .r_paren])
	ktest('var i = 0', [.key_var, .ident, .assign, .int_lit, .eof])
	ktest('&a.b |> c', [.amp, .ident, .dot, .ident, .pipe, .ident, .eof])
	ktest('a && b || c &', [.ident, .logical_and, .ident, .logical_or, .ident, .amp, .eof])
	ktest('return 0', [.key_return, .int_lit])
	ktest('assert a == b', [.key_assert, .ident, .eq, .ident])
	ktest('a < b || c > d', [.ident, .lt, .ident, .logical_or, .ident, .gt, .ident])
	ktest('a <= b || c >= d', [.ident, .le, .ident, .logical_or, .ident, .ge, .ident])
	ktest('!cond', [.not, .ident])
	ktest('a+++++', [.ident, .plus_plus, .plus_plus, .plus])
	ktest('a-----', [.ident]) // TODO
	ktest('a -----', [.ident, .minus_minus, .minus_minus, .minus])
	ktest('struct f { }', [.key_struct, .ident, .l_brace, .r_brace])
	ktest('"0" as int', [.string_lit, .key_as, .ident])
	ktest('#[attr]', [.hash, .l_bracket, .ident, .r_bracket])
	ktest('.....', [.dotdotdot, .dot, .dot])
	ktest('require "file.li"', [.key_require, .string_lit])
	ktest('yield 0', [.key_yield, .int_lit])
	ktest('while true { }', [.key_while, .bool_lit, .l_brace, .r_brace])
	ktest('use PATH', [.key_use, .ident])
	ktest('export PATH', [.key_export, .ident])

	ktest('n += 2', [.ident, .plus_assign, .int_lit])
	ktest('n -= 2', [.ident, .minus_assign, .int_lit])
	ktest('n *= 2', [.ident, .mul_assign, .int_lit])
	ktest('n /= 2', [.ident, .div_assign, .int_lit])
	ktest('n %= 2', [.ident, .mod_assign, .int_lit])

	test('if i == 0 { } else if i != 1 {} else {}', [
		t(.key_if, 'if'),
		t(.ident, 'i'),
		t(.eq, '=='),
		t(.int_lit, '0'),
		t(.l_brace, '{'),
		t(.r_brace, '}'),
		t(.key_else, 'else'),
		t(.key_if, 'if'),
		t(.ident, 'i'),
		t(.ne, '!='),
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
		t(.plus, '+'),
		t(.bool_lit, 'false'),
		t(.minus, '-'),
		t(.int_lit, '2'),
		t(.mul, '*'),
		t(.int_lit, '3'),
		t(.div, '/'),
		t(.ident, 'x'),
		t(.r_paren, ')'),
		t(.eq, '=='),
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

fn test_at_ident() {
	texts := ['@a.a', '@./a.a', '@/usr/local/bin/', '@~/.bin/cmd.py']
	for text in texts {
		test(text, [t(.ident, text)])
	}

	ktest('@expr()', [.ident, .l_paren, .r_paren])
}

fn test_string() {
	sq, dq := "'", '"'
	test("$dq'abc'$dq", [t(.string_lit, "'abc'")])
	test('$sq"abc"$sq', [t(.string_lit, '"abc"')])
	ektest('"a', [ek(.string_lit, .err), ek(.eof, .ok)])
	ektest('"a\na', [ek(.string_lit, .err), ek(.eol, .ok), ek(.ident, .ok)])
	ektest("'a", [ek(.string_lit, .err), ek(.eof, .ok)])
	ektest("'a\na", [ek(.string_lit, .err), ek(.eol, .ok), ek(.ident, .ok)])
}

fn test_inline_shell() {
	test(r'${echo 1}', [t(.inline_shell, 'echo 1')])
}

fn test_number() {
	test('1 1.1', [
		t(.int_lit, '1'),
		t(.float_lit, '1.1'),
	])

	ektest('1.1.1', [ek(.float_lit, .err)])
}
