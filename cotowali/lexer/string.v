// Copyright (c) 2021 zakuro <z@kuro.red>. All rights reserved.
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
module lexer

import cotowali.token { Token }

fn (mut lex Lexer) read_single_quote_string_lit_content() ?Token {
	$if trace_lexer ? {
		lex.trace_begin(@FN)
		defer {
			lex.trace_end()
		}
	}

	mut unterminated := false
	for lex.byte() != `\'` {
		lex.consume()
		if lex.is_eof() || is_eol(lex.char(0)) {
			unterminated = true
			break
		}
	}

	tok := lex.new_token(.string_lit_content_text)
	if unterminated {
		return lex.unterminated_string_lit_error(tok)
	}
	return tok
}

fn (mut lex Lexer) read_double_quote_string_lit_content() ?Token {
	$if trace_lexer ? {
		lex.trace_begin(@FN)
		defer {
			lex.trace_end()
		}
	}

	mut unterminated := false
	for lex.byte() != `"` {
		lex.consume()
		if lex.is_eof() || is_eol(lex.char(0)) {
			unterminated = true
			break
		}
	}

	tok := lex.new_token(.string_lit_content_text)
	if unterminated {
		return lex.unterminated_string_lit_error(tok)
	}
	return tok
}

fn (mut lex Lexer) unterminated_string_lit_error(tok Token) IError {
	lex.status_stack.pop() // force exit from inside_string status
	return lex.error(tok, 'unterminated string literal')
}
