// Copyright (c) 2021 zakuro <z@kuro.red>. All rights reserved.
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
module lexer

import cotowali.context { new_default_context }
import cotowali.token { Token, TokenKind }
import cotowali.source { Pos, new_source, none_pos }
import cotowali.errors

fn test(fn_name string, line string, code string, tokens []Token) {
	println('@FN: $fn_name, LINE: $line')

	ctx := new_default_context()
	lexer := new_lexer(new_source('', code), ctx)
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

fn ktest(fn_name string, line string, code string, kinds []TokenKind) {
	println('@FN: $fn_name, LINE: $line')

	ctx := new_default_context()
	lexer := new_lexer(new_source('', code), ctx)
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
	return EkTestValue{
		kind: k
		status: s
	}
}

fn (mut lex Lexer) e_read() (Token, ErrOrOk) {
	tok := lex.read() or {
		if err is errors.LexerErr {
			return err.token, ErrOrOk.err
		}
		panic(err)
	}
	return tok, ErrOrOk.ok
}

fn ektest(fn_name string, line string, code string, values []EkTestValue) {
	println('@FN: $fn_name, LINE: $line')

	ctx := new_default_context()
	mut lexer := new_lexer(new_source('', code), ctx)
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
	test(@FN, @LINE, ' "🐈__" a ', [
		// Pos{i, line, col, len, last_line, last_col}
		Token{.double_quote, '"', Pos{1, 1, 2, 1, 1, 2}},
		Token{.string_literal_content_text, '🐈__', Pos{2, 1, 3, 6, 1, 6}},
		Token{.double_quote, '"', Pos{8, 1, 7, 1, 1, 7}},
		Token{.ident, 'a', Pos{10, 1, 9, 1, 1, 9}},
		Token{.eof, '', Pos{12, 1, 11, 1, 1, 11}},
	])
	ktest(@FN, @LINE, 'fn f(a, b){}', [.key_fn, .ident, .l_paren, .ident, .comma, .ident, .r_paren,
		.l_brace, .r_brace, .eof])
	ktest(@FN, @LINE, 'var i = 0', [.key_var, .ident, .assign, .int_literal, .eof])
	ktest(@FN, @LINE, '&a.b |> c', [.amp, .ident, .dot, .ident, .pipe, .ident, .eof])
	ktest(@FN, @LINE, 'a && b || c &', [.ident, .logical_and, .ident, .logical_or, .ident, .amp,
		.eof,
	])
	ktest(@FN, @LINE, 'return 0', [.key_return, .int_literal])
	ktest(@FN, @LINE, 'assert a == b', [.key_assert, .ident, .eq, .ident])
	ktest(@FN, @LINE, 'a < b || c > d', [.ident, .lt, .ident, .logical_or, .ident, .gt, .ident])
	ktest(@FN, @LINE, 'a <= b || c >= d', [.ident, .le, .ident, .logical_or, .ident, .ge, .ident])
	ktest(@FN, @LINE, '!cond', [.not, .ident])
	ktest(@FN, @LINE, 'a+++++', [.ident, .plus_plus, .plus_plus, .plus])
	ktest(@FN, @LINE, 'a-----', [.ident]) // TODO
	ktest(@FN, @LINE, 'a -----', [.ident, .minus_minus, .minus_minus, .minus])
	ktest(@FN, @LINE, 'struct f { }', [.key_struct, .ident, .l_brace, .r_brace])
	ktest(@FN, @LINE, '{ 0: 0 }', [.l_brace, .int_literal, .colon, .int_literal, .r_brace])
	ktest(@FN, @LINE, 'map[string]string', [.key_map, .l_bracket, .ident, .r_bracket, .ident])
	ktest(@FN, @LINE, '0.0 as int', [.float_literal, .key_as, .ident])
	ktest(@FN, @LINE, '#[attr]', [.hash, .l_bracket, .ident, .r_bracket])
	ktest(@FN, @LINE, '.....', [.dotdotdot, .dot, .dot])
	ktest(@FN, @LINE, 'require "file.li"', [.key_require, .double_quote, .string_literal_content_text,
		.double_quote,
	])
	ktest(@FN, @LINE, 'yield 0', [.key_yield, .int_literal])
	ktest(@FN, @LINE, 'while true { }', [.key_while, .bool_literal, .l_brace, .r_brace])
	ktest(@FN, @LINE, 'use PATH', [.key_use, .ident])
	ktest(@FN, @LINE, 'export PATH', [.key_export, .ident])

	ktest(@FN, @LINE, 'n += 2', [.ident, .plus_assign, .int_literal])
	ktest(@FN, @LINE, 'n -= 2', [.ident, .minus_assign, .int_literal])
	ktest(@FN, @LINE, 'n *= 2', [.ident, .mul_assign, .int_literal])
	ktest(@FN, @LINE, 'n /= 2', [.ident, .div_assign, .int_literal])
	ktest(@FN, @LINE, 'n %= 2', [.ident, .mod_assign, .int_literal])

	test(@FN, @LINE, 'if i == 0 { } else if i != 1 {} else {}', [
		t(.key_if, 'if'),
		t(.ident, 'i'),
		t(.eq, '=='),
		t(.int_literal, '0'),
		t(.l_brace, '{'),
		t(.r_brace, '}'),
		t(.key_else, 'else'),
		t(.key_if, 'if'),
		t(.ident, 'i'),
		t(.ne, '!='),
		t(.int_literal, '1'),
		t(.l_brace, '{'),
		t(.r_brace, '}'),
		t(.key_else, 'else'),
		t(.l_brace, '{'),
		t(.r_brace, '}'),
		t(.eof, ''),
	])

	test(@FN, @LINE, '\n\r\n\r', [
		t(.eol, '\n'),
		t(.eol, '\r\n'),
		t(.eol, '\r'),
		t(.eof, ''),
		t(.eof, ''),
	])

	test(@FN, @LINE, '{(true + false - 2 * 3 / x) == 0}', [
		t(.l_brace, '{'),
		t(.l_paren, '('),
		t(.bool_literal, 'true'),
		t(.plus, '+'),
		t(.bool_literal, 'false'),
		t(.minus, '-'),
		t(.int_literal, '2'),
		t(.mul, '*'),
		t(.int_literal, '3'),
		t(.div, '/'),
		t(.ident, 'x'),
		t(.r_paren, ')'),
		t(.eq, '=='),
		t(.int_literal, '0'),
		t(.r_brace, '}'),
		t(.eof, ''),
	])
	test(@FN, @LINE, 'a//abc' + cr + 'b//xxx' + lf + 'c//cr' + crlf + 'd//eee', [
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
		test(@FN, @LINE, text, [t(.ident, text)])
	}

	ktest(@FN, @LINE, '@expr()', [.ident, .l_paren, .r_paren])
}

fn test_string() {
	test(@FN, @LINE, "$dq'abc'$dq", [
		t(.double_quote, '"'),
		t(.string_literal_content_text, "'abc'"),
		t(.double_quote, '"'),
	])
	test(@FN, @LINE, '$sq"abc"$sq', [
		t(.single_quote, "'"),
		t(.string_literal_content_text, '"abc"'),
		t(.single_quote, "'"),
	])

	test(@FN, @LINE, "'" + r"a\\\n\'" + r'\"' + "'", [
		t(.single_quote, "'"),
		t(.string_literal_content_text, 'a'),
		t(.string_literal_content_escaped_back_slash, r'\\'),
		t(.string_literal_content_text, r'\n'),
		t(.string_literal_content_escaped_single_quote, r"\'"),
		t(.string_literal_content_text, r'\"'),
		t(.single_quote, "'"),
	])
	ktest(@FN, @LINE, r"'\\\\'", [
		.single_quote,
		.string_literal_content_escaped_back_slash,
		.string_literal_content_escaped_back_slash,
		.single_quote,
	])

	ktest(@FN, @LINE, r'"a\\"', [
		.double_quote,
		.string_literal_content_text,
		.string_literal_content_escaped_back_slash,
		.double_quote,
	])

	ektest(@FN, @LINE, '"a', [ek(.double_quote, .ok), ek(.string_literal_content_text,
		.err)])
	ektest(@FN, @LINE, '"a\na', [
		ek(.double_quote, .ok),
		ek(.string_literal_content_text, .err),
		ek(.eol, .ok),
		ek(.ident, .ok),
	])
	ektest(@FN, @LINE, "'a", [
		ek(.single_quote, .ok),
		ek(.string_literal_content_text, .err),
		ek(.eof, .ok),
	])
	ektest(@FN, @LINE, "'a\na", [
		ek(.single_quote, .ok),
		ek(.string_literal_content_text, .err),
		ek(.eol, .ok),
		ek(.ident, .ok),
	])

	test(@FN, @LINE, r"r'\\\n\''", [
		t(.single_quote_with_r_prefix, "r'"),
		t(.string_literal_content_text, '$bs$bs${bs}n$bs'),
		t(.single_quote, "'"),
		t(.single_quote, "'"),
	])
	test(@FN, @LINE, r'r"\\\n\""', [
		t(.double_quote_with_r_prefix, 'r"'),
		t(.string_literal_content_text, '$bs$bs${bs}n$bs'),
		t(.double_quote, '"'),
		t(.double_quote, '"'),
	])
}

fn test_inline_shell() {
	test(@FN, @LINE, r'${echo 1}', [t(.inline_shell, 'echo 1')])
}

fn test_number() {
	test(@FN, @LINE, '1 1.1 1E+9 1e-9', [
		t(.int_literal, '1'),
		t(.float_literal, '1.1'),
		t(.float_literal, '1E+9'),
		t(.float_literal, '1e-9'),
	])

	ektest(@FN, @LINE, '1.1.1', [ek(.float_literal, .err)])
}

fn test_multiline() {
	lines := [
		's1 s2',
		's3  s4 ',
		'',
		' s5 ',
	]
	code := lines.join('\n')
	test(@FN, @LINE, code, [
		// Pos{i, line, col, len, last_line, last_col}
		Token{.ident, 's1', Pos{0, 1, 1, 2, 1, 2}},
		Token{.ident, 's2', Pos{3, 1, 4, 2, 1, 5}},
		Token{.eol, '\n', Pos{5, 1, lines[0].len + 1, 1, 1, lines[0].len + 1}},
		Token{.ident, 's3', Pos{6, 2, 1, 2, 2, 2}},
		Token{.ident, 's4', Pos{10, 2, 5, 2, 2, 6}},
		Token{.eol, '\n', Pos{13, 2, lines[1].len + 1, 1, 2, lines[1].len + 1}},
		Token{.eol, '\n', Pos{14, 3, lines[2].len + 1, 1, 3, lines[2].len + 1}},
		Token{.ident, 's5', Pos{16, 4, 2, 2, 4, 3}},
		Token{.eof, '', Pos{code.len, 4, lines[3].len + 1, 1, 4, lines[3].len + 1}},
	])
}
