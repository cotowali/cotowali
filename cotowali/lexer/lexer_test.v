// Copyright (c) 2021 zakuro <z@kuro.red>. All rights reserved.
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
module lexer

import cotowali.context { new_default_context }
import cotowali.token { Token, TokenKind }
import cotowali.source { Pos, Source, new_source, none_pos }
import cotowali.errors

type StrOrStrArray = []string | string

fn code(code StrOrStrArray) &Source {
	return new_source('', match code {
		string { code }
		[]string { code.map(it + '\n').join('') }
	})
}

fn test(fn_name string, line string, source &Source, tokens []Token) {
	println('@FN: $fn_name, LINE: $line')

	ctx := new_default_context()
	lexer := new_lexer(source, ctx)
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
	s1 := code(' "🐈__" a ')
	test(@FN, @LINE, s1, [
		// Pos{i, line, col, len, last_line, last_col}
		Token{.double_quote, '"', Pos{s1, 1, 1, 2, 1, 1, 2}},
		Token{.string_literal_content_text, '🐈__', Pos{s1, 2, 1, 3, 6, 1, 6}},
		Token{.double_quote, '"', Pos{s1, 8, 1, 7, 1, 1, 7}},
		Token{.ident, 'a', Pos{s1, 10, 1, 9, 1, 1, 9}},
		Token{.eof, '', Pos{s1, 12, 1, 11, 1, 1, 11}},
	])
	ktest(@FN, @LINE, 'module x::y', [.key_module, .ident, .coloncolon, .ident])
	ktest(@FN, @LINE, 'fn f(a, b){}', [.key_fn, .ident, .l_paren, .ident, .comma, .ident, .r_paren,
		.l_brace, .r_brace, .eof])
	ktest(@FN, @LINE, 'var i = 0', [.key_var, .ident, .assign, .int_literal, .eof])
	ktest(@FN, @LINE, '&a.b |> c', [.amp, .ident, .dot, .ident, .pipe, .ident, .eof])
	ktest(@FN, @LINE, 'a && b || c &', [.ident, .logical_and, .ident, .logical_or, .ident, .amp,
		.eof])
	ktest(@FN, @LINE, 'return 0;', [.key_return, .int_literal, .semicolon])
	ktest(@FN, @LINE, 'assert a == b', [.key_assert, .ident, .eq, .ident])
	ktest(@FN, @LINE, 'a < b || c > d', [.ident, .lt, .ident, .logical_or, .ident, .gt, .ident])
	ktest(@FN, @LINE, 'a <= b || c >= d', [.ident, .le, .ident, .logical_or, .ident, .ge, .ident])
	ktest(@FN, @LINE, '!cond', [.not, .ident])
	ktest(@FN, @LINE, 'a+++++', [.ident, .plusplus, .plusplus, .plus])
	ktest(@FN, @LINE, 'a-----', [.ident]) // TODO
	ktest(@FN, @LINE, 'a -----', [.ident, .minusminus, .minusminus, .minus])
	ktest(@FN, @LINE, 'a*****', [.ident, .pow, .pow, .mul])
	ktest(@FN, @LINE, 'struct f { }', [.key_struct, .ident, .l_brace, .r_brace])
	ktest(@FN, @LINE, '{ 0: 0 }', [.l_brace, .int_literal, .colon, .int_literal, .r_brace])
	ktest(@FN, @LINE, 'map[string]string', [.key_map, .l_bracket, .ident, .r_bracket, .ident])
	ktest(@FN, @LINE, '0.0 as int', [.float_literal, .key_as, .ident])
	ktest(@FN, @LINE, '#[attr]', [.hash, .l_bracket, .ident, .r_bracket])
	ktest(@FN, @LINE, 'f()?', [.ident, .l_paren, .r_paren, .question])
	ktest(@FN, @LINE, '.....', [.dotdotdot, .dot, .dot])
	ktest(@FN, @LINE, ':::::', [.coloncolon, .coloncolon, .colon])
	ktest(@FN, @LINE, 'require "file.li"', [.key_require, .double_quote, .string_literal_content_text,
		.double_quote])
	ktest(@FN, @LINE, 'yield 0', [.key_yield, .int_literal])
	ktest(@FN, @LINE, 'while true { }', [.key_while, .bool_literal, .l_brace, .r_brace])
	ktest(@FN, @LINE, 'use PATH', [.key_use, .ident])
	ktest(@FN, @LINE, 'export PATH', [.key_export, .ident])
	ktest(@FN, @LINE, 'nameof(v)', [.key_nameof, .l_paren, .ident, .r_paren])

	ktest(@FN, @LINE, 'n += 2', [.ident, .plus_assign, .int_literal])
	ktest(@FN, @LINE, 'n -= 2', [.ident, .minus_assign, .int_literal])
	ktest(@FN, @LINE, 'n *= 2', [.ident, .mul_assign, .int_literal])
	ktest(@FN, @LINE, 'n /= 2', [.ident, .div_assign, .int_literal])
	ktest(@FN, @LINE, 'n %= 2', [.ident, .mod_assign, .int_literal])
	ktest(@FN, @LINE, 'n **= 2', [.ident, .pow_assign, .int_literal])

	test(@FN, @LINE, code('if i == 0 { } else if i != 1 {} else {}'), [
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

	test(@FN, @LINE, code('\n\r\n\r'), [
		t(.eol, '\n'),
		t(.eol, '\r\n'),
		t(.eol, '\r'),
		t(.eof, ''),
		t(.eof, ''),
	])

	test(@FN, @LINE, code('{(true + false - 2 * 3 / x) == 0}'), [
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
}

fn test_comment() {
	cr, lf := '\r', '\n'
	crlf := cr + lf

	test(@FN, @LINE, code('a//abc' + cr + 'b//xxx' + lf + 'c//cr' + crlf + 'd//eee'),
		[
		t(.ident, 'a'),
		t(.eol, cr),
		t(.ident, 'b'),
		t(.eol, lf),
		t(.ident, 'c'),
		t(.eol, crlf),
		t(.ident, 'd'),
	])
	test(@FN, @LINE, code('a/* /* xx */ */b'), [
		t(.ident, 'a'),
		t(.ident, 'b'),
	])

	test(@FN, @LINE, code('a/// comment // comment' + lf + 'b'), [
		t(.ident, 'a'),
		t(.doc_comment, ' comment // comment'),
		t(.eol, lf),
		t(.ident, 'b'),
	])
}

fn test_at_ident() {
	texts := ['@a.a', '@./a.a', '@/usr/local/bin/', '@~/.bin/cmd.py']
	for text in texts {
		test(@FN, @LINE, code(text), [t(.ident, text)])
	}

	ktest(@FN, @LINE, '@expr()', [.ident, .l_paren, .r_paren])
}

fn test_string() {
	test(@FN, @LINE, code("$dq'a\nb\nc'$dq"), [
		t(.double_quote, '"'),
		t(.string_literal_content_text, "'a\nb\nc'"),
		t(.double_quote, '"'),
	])
	test(@FN, @LINE, code('$sq"a\nb\nc"$sq'), [
		t(.single_quote, "'"),
		t(.string_literal_content_text, '"a\nb\nc"'),
		t(.single_quote, "'"),
	])

	test(@FN, @LINE, code(r'"  x  "'), [
		t(.double_quote, '"'),
		t(.string_literal_content_text, '  x  '),
		t(.double_quote, '"'),
	])

	test(@FN, @LINE, code("'" + r"a\\\n\'" + r'\"' + "'"), [
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

	ktest(@FN, @LINE, '"a', [.double_quote, .string_literal_content_text])
	ktest(@FN, @LINE, "'a", [.single_quote, .string_literal_content_text, .eof])

	test(@FN, @LINE, code(r"r'\\\n\''"), [
		t(.single_quote_with_r_prefix, "r'"),
		t(.string_literal_content_text, '$bs$bs${bs}n$bs'),
		t(.single_quote, "'"),
		t(.single_quote, "'"),
	])
	test(@FN, @LINE, code(r'r"\\\n\""'), [
		t(.double_quote_with_r_prefix, 'r"'),
		t(.string_literal_content_text, '$bs$bs${bs}n$bs'),
		t(.double_quote, '"'),
		t(.double_quote, '"'),
	])
}

fn test_glob() {
	ktest(@FN, @LINE, '"**"', [.double_quote, .string_literal_content_text, .double_quote])
	ktest(@FN, @LINE, "'**'", [.single_quote, .string_literal_content_text, .single_quote])
	test(@FN, @LINE, code('@"a/**/*.txt"'), [
		t(.double_quote_with_at_prefix, '@"'),
		t(.string_literal_content_text, 'a/'),
		t(.string_literal_content_glob, '**'),
		t(.string_literal_content_text, '/'),
		t(.string_literal_content_glob, '*'),
		t(.string_literal_content_text, '.txt'),
		t(.double_quote, '"'),
	])

	test(@FN, @LINE, code("@'a/**/*.txt'"), [
		t(.single_quote_with_at_prefix, "@'"),
		t(.string_literal_content_text, 'a/'),
		t(.string_literal_content_glob, '**'),
		t(.string_literal_content_text, '/'),
		t(.string_literal_content_glob, '*'),
		t(.string_literal_content_text, '.txt'),
		t(.single_quote, "'"),
	])
}

fn test_string_expr_substitution() {
	ktest(@FN, @LINE, r"'${x}'", [.single_quote, .string_literal_content_text, .single_quote])
	test(@FN, @LINE, code(r'"${x}"'), [
		t(.double_quote, '"'),
		t(.string_literal_content_expr_open, r'${'),
		t(.ident, 'x'),
		t(.string_literal_content_expr_close, '}'),
		t(.double_quote, '"'),
	])

	test(@FN, @LINE, code(r'"${ "a" {} " b ${ {} "${ "x" }"} $v" "${ ([ }" }}"'), [
		t(.double_quote, '"'),
		t(.string_literal_content_expr_open, r'${'),
		t(.double_quote, '"'),
		t(.string_literal_content_text, 'a'),
		t(.double_quote, '"'),
		t(.l_brace, '{'),
		t(.r_brace, '}'),
		t(.double_quote, '"'),
		t(.string_literal_content_text, ' b '),
		t(.string_literal_content_expr_open, r'${'),
		t(.l_brace, '{'),
		t(.r_brace, '}'),
		t(.double_quote, '"'),
		t(.string_literal_content_expr_open, r'${'),
		t(.double_quote, '"'),
		t(.string_literal_content_text, 'x'),
		t(.double_quote, '"'),
		t(.string_literal_content_expr_close, r'}'),
		t(.double_quote, '"'),
		t(.string_literal_content_expr_close, r'}'),
		t(.string_literal_content_text, ' '),
		t(.string_literal_content_var, r'$v'),
		t(.double_quote, '"'),
		t(.double_quote, '"'),
		t(.string_literal_content_expr_open, r'${'),
		t(.l_paren, '('),
		t(.l_bracket, '['),
		t(.string_literal_content_expr_close, r'}'),
		t(.double_quote, '"'),
		t(.string_literal_content_expr_close, r'}'),
		t(.string_literal_content_text, '}'),
		t(.double_quote, '"'),
	])
}

fn test_inline_shell() {
	test(@FN, @LINE, code('sh {} x'), [
		t(.ident, 'sh'),
		t(.l_brace, '{'),
		t(.inline_shell_content_text, ''),
		t(.r_brace, '}'),
		t(.ident, 'x'),
	])

	test(@FN, @LINE, code(r'sh { echo 1 } x'), [
		t(.ident, 'sh'),
		t(.l_brace, '{'),
		t(.inline_shell_content_text, ' echo 1 '),
		t(.r_brace, '}'),
		t(.ident, 'x'),
	])
	test(@FN, @LINE, code(r'sh { echo ${n} } x'), [
		t(.ident, 'sh'),
		t(.l_brace, '{'),
		t(.inline_shell_content_text, r' echo ${n} '),
		t(.r_brace, '}'),
		t(.ident, 'x'),
	])

	test(@FN, @LINE, code(r'sh { echo $%n } x'), [
		t(.ident, 'sh'),
		t(.l_brace, '{'),
		t(.inline_shell_content_text, r' echo $'),
		t(.inline_shell_content_var, '%n'),
		t(.inline_shell_content_text, ' '),
		t(.r_brace, '}'),
		t(.ident, 'x'),
	])

	test(@FN, @LINE, code(r'inline { echo $%n } x'), [
		t(.ident, 'inline'),
		t(.l_brace, '{'),
		t(.inline_shell_content_text, r' echo $'),
		t(.inline_shell_content_var, '%n'),
		t(.inline_shell_content_text, ' '),
		t(.r_brace, '}'),
		t(.ident, 'x'),
	])

	test(@FN, @LINE, code([
		r'sh { ',
		r'  %n=10',
		r'  echo $%n',
		r'}',
	]), [
		t(.ident, 'sh'),
		t(.l_brace, '{'),
		t(.inline_shell_content_text, ' \n  '),
		t(.inline_shell_content_var, '%n'),
		t(.inline_shell_content_text, '=10\n  echo \$'),
		t(.inline_shell_content_var, '%n'),
		t(.inline_shell_content_text, '\n'),
		t(.r_brace, '}'),
		t(.eol, '\n'),
	])

	// escaped %
	test(@FN, @LINE, code(r"sh { printf '%%s' $%str }"), [
		t(.ident, 'sh'),
		t(.l_brace, '{'),
		t(.inline_shell_content_text, r" printf '%s' $"),
		t(.inline_shell_content_var, '%str'),
		t(.inline_shell_content_text, ' '),
		t(.r_brace, '}'),
	])
}

fn test_mix_inline_shell_and_string() {
	//             0                                                 0
	//             +-------------------------------------------------+
	//             |       1                                    1    |
	//             |       +------------------------------------+    |
	//             |       |      2                          2  |    |
	//             |       |      +--------------------------+  |    |
	//             |       |      |      3                 3 |  |    |
	//             |       |      |      +-----------------+ |  |    |
	//             |       |      |      |       4       4 | |  |    |
	//             |       |      |      |       +-------+ | |  |    |
	//             v       v      v      v       v       v v v  v    v
	s := code(r'sh { echo %{ "$a ${ b sh { echo %{ r"$a" } } }" } %n }')
	test(@FN, @LINE, s, [
		t(.ident, 'sh'),
		t(.l_brace, '{'), // ------------------------------------------------------+ 0
		t(.inline_shell_content_text, r' echo '), //                               |
		t(.inline_shell_content_expr_substitution_open, r'%{'), //-------------+ 1 |
		t(.double_quote, '"'), //                                              |   |
		t(.string_literal_content_var, r'$a'), //                              |   |
		t(.string_literal_content_text, r' '), //                              |   |
		t(.string_literal_content_expr_open, r'${'), //--------------------+ 2 |   |
		t(.ident, 'b'), //                                                 |   |   |
		t(.ident, 'sh'), //                                               |   |   |
		t(.l_brace, '{'), // ------------------------------------------+ 3 |   |   |
		t(.inline_shell_content_text, r' echo '), //                   |   |   |   |
		t(.inline_shell_content_expr_substitution_open, r'%{'), //-+ 4 |   |   |   |
		t(.double_quote_with_r_prefix, 'r"'), //                   |   |   |   |   |
		t(.string_literal_content_text, r'$a'), //                 |   |   |   |   |
		t(.double_quote, '"'), //                                  |   |   |   |   |
		t(.inline_shell_content_expr_substitution_close, r'}'), //-+ 4 |   |   |   |
		t(.inline_shell_content_text, ' '), //                         |   |   |   |
		t(.r_brace, '}'), // ------------------------------------------+ 3 |   |   |
		t(.string_literal_content_expr_close, '}'), //---------------------+ 2 |   |
		t(.double_quote, '"'), // ---------------------------------------------|   |
		t(.inline_shell_content_expr_substitution_close, r'}'), //-------------+ 1 |
		t(.inline_shell_content_text, ' '), //                                     |
		t(.inline_shell_content_var, '%n'), //                                     |
		t(.inline_shell_content_text, ' '), //                                     |
		t(.r_brace, '}'), // ------------------------------------------------------+ 0
	])
}

fn test_number() {
	test(@FN, @LINE, code('1 1.1 1E+9 1e-9'), [
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
	s := code(lines)
	test(@FN, @LINE, s, [
		// Pos{source, i, line, col, len, last_line, last_col}
		Token{.ident, 's1', Pos{s, 0, 1, 1, 2, 1, 2}},
		Token{.ident, 's2', Pos{s, 3, 1, 4, 2, 1, 5}},
		Token{.eol, '\n', Pos{s, 5, 1, lines[0].len + 1, 1, 1, lines[0].len + 1}},
		Token{.ident, 's3', Pos{s, 6, 2, 1, 2, 2, 2}},
		Token{.ident, 's4', Pos{s, 10, 2, 5, 2, 2, 6}},
		Token{.eol, '\n', Pos{s, 13, 2, lines[1].len + 1, 1, 2, lines[1].len + 1}},
		Token{.eol, '\n', Pos{s, 14, 3, lines[2].len + 1, 1, 3, lines[2].len + 1}},
		Token{.ident, 's5', Pos{s, 16, 4, 2, 2, 4, 3}},
		Token{.eol, '\n', Pos{s, 19, 4, lines[3].len + 1, 1, 4, lines[3].len + 1}},
		Token{.eof, '', Pos{s, s.code.len, 5, 1, 1, 5, 1}},
	])
}
