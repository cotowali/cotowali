// Copyright (c) 2021 zakuro <z@kuro.red>. All rights reserved.
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
module lexer

import cotowali.token { Token }
import cotowali.source { Char }
import cotowali.errors { LexerErr }
import cotowali.messages { unreachable }

pub fn (mut lex Lexer) next() ?Token {
	if lex.closed {
		return none
	}
	return lex.read() or {
		if err is LexerErr {
			return err.token
		}
		panic(unreachable(err))
	}
}

fn (mut lex Lexer) prepare_to_read() {
	// " $v " should be ['"', ' ' '$v', ' ', '"']. So don't skip whitespace inside double quote literal
	if lex.lex_ctx.current.kind in [.normal, .inside_string_literal_expr_substitution] {
		lex.skip_whitespaces()
	}

	lex.start_pos()
}

pub fn (mut lex Lexer) read() ?Token {
	$if trace_lexer ? {
		lex.trace_begin(@FN)
		defer {
			lex.trace_end()
		}
	}

	for {
		lex.prepare_to_read()
		if lex.is_eof() {
			lex.close()
			return Token{.eof, '', lex.pos}
		}

		if tok := lex.read_for_string_literal() {
			return tok
		}

		if tok := lex.read_doc_comment() {
			return tok
		}

		if _ := lex.try_skip_comment() {
			// found comment
			continue
		}

		// --

		c0, c1, c2 := lex.char(0), lex.char(1), lex.char(2)
		mut kind := tk(.unknown)

		// --

		ccc := '$c0$c1$c2'

		kind = table_for_three_chars_symbols[ccc] or { tk(.unknown) }
		if kind != .unknown {
			return lex.new_token_with_consume_n(3, kind)
		}

		// --

		cc := '$c0$c1'

		kind = table_for_two_chars_symbols[cc] or { tk(.unknown) }
		if kind != .unknown {
			return lex.new_token_with_consume_n(2, kind)
		}

		// --

		c := c0

		kind = table_for_one_char_symbols[c.byte()] or { tk(.unknown) }
		if kind != .unknown {
			if kind == .l_brace {
				lex.lex_ctx.current.brace_depth += 1
			}
			if kind == .r_brace {
				if lex.lex_ctx.current.kind == .inside_string_literal_expr_substitution
					&& lex.lex_ctx.current.brace_depth == 0 {
					lex.lex_ctx.pop()
					return lex.new_token_with_consume(.string_literal_content_expr_close)
				}

				lex.lex_ctx.current.brace_depth -= 1
			}
			return lex.new_token_with_consume(kind)
		}

		// --

		if is_ident_first_char(c) {
			return lex.read_ident_or_keyword()
		} else if is_digit(c) {
			return lex.read_number()
		} else if lex.is_eol() {
			return lex.read_eol()
		}

		return match c.byte() {
			`@` { lex.read_at_ident() }
			`\$` { lex.read_dollar_directive() }
			else { lex.read_unknown() }
		}
	}
	panic(unreachable(''))
}

fn (lex Lexer) is_eol() bool {
	return is_eol(lex.char(0))
}

fn (mut lex Lexer) read_eol() Token {
	$if trace_lexer ? {
		lex.trace_begin(@FN)
		defer {
			lex.trace_end()
		}
	}

	if lex.byte() == `\r` && lex.char(1).byte() == `\n` {
		lex.consume()
	}
	return lex.new_token_with_consume(.eol)
}

fn (mut lex Lexer) read_unknown() Token {
	$if trace_lexer ? {
		lex.trace_begin(@FN)
		defer {
			lex.trace_end()
		}
	}

	for !(lex.is_eof() || lex.char(0).@is(.whitespace) || lex.char(0) == '\n') {
		lex.consume()
	}
	return lex.new_token(.unknown)
}

fn is_ident_first_char(c Char) bool {
	return c.@is(.alphabet) || c.byte() == `_`
}

fn is_ident_char(c Char) bool {
	return is_ident_first_char(c) || is_digit(c) || c.byte() == `-`
}

fn is_digit(c Char) bool {
	return c.@is(.digit)
}

fn is_whitespace(c Char) bool {
	return c.@is(.whitespace)
}

fn is_eol(c Char) bool {
	return c.@is(.eol)
}

fn (mut lex Lexer) skip_whitespaces() {
	lex.consume_for(is_whitespace)
}

fn (mut lex Lexer) read_ident_or_keyword() Token {
	$if trace_lexer ? {
		lex.trace_begin(@FN)
		defer {
			lex.trace_end()
		}
	}

	lex.consume_for(is_ident_char)
	text := lex.text()
	pos := lex.pos_for_new_token()
	kind := table_for_keywords[text] or { tk(.ident) }
	return Token{
		pos: pos
		text: text
		kind: kind
	}
}

fn (mut lex Lexer) read_number() ?Token {
	$if trace_lexer ? {
		lex.trace_begin(@FN)
		defer {
			lex.trace_end()
		}
	}

	mut is_float := false
	mut err_msg := ''
	for lex.byte() == `.` || lex.char(0).@is(.digit) {
		if lex.byte() == `.` {
			if is_float {
				err_msg = 'too many decimal points in number'
			}
			is_float = true
		}
		lex.consume()
	}
	if lex.byte() in [`e`, `E`] && lex.char(1)[0] in [`+`, `-`] {
		lex.consume() // 'E'
		lex.consume() // '+'
		lex.consume_for_char_is(.digit)
		is_float = true
	}

	tok := lex.new_token(if is_float { tk(.float_literal) } else { tk(.int_literal) })
	return if err_msg.len == 0 { tok } else { lex.error(tok, err_msg) }
}

fn (mut lex Lexer) read_at_ident() Token {
	$if trace_lexer ? {
		lex.trace_begin(@FN)
		defer {
			lex.trace_end()
		}
	}

	return lex.new_token_with_consume_not_for(fn (c Char) bool {
		return is_whitespace(c) || c[0] in [`(`, `)`]
	}, .ident)
}

fn (mut lex Lexer) read_dollar_directive() Token {
	$if trace_lexer ? {
		lex.trace_begin(@FN)
		defer {
			lex.trace_end()
		}
	}

	lex.skip_with_assert(fn (c Char) bool {
		return c.byte() == `$`
	})
	if lex.byte() == `{` {
		lex.skip()
		mut depth := 1
		for {
			if lex.is_eof() {
				panic('unterminated inline shell')
			}
			match lex.byte() {
				`{` { depth++ }
				`}` { depth-- }
				else {}
			}
			if depth == 0 {
				break
			}
			lex.consume()
		}
		tok := lex.new_token(.inline_shell)
		lex.skip()
		return tok
	} else {
		panic('invalid dollar directive')
	}
}
