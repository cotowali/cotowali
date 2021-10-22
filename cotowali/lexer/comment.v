// Copyright (c) 2021 zakuro <z@kuro.red>. All rights reserved.
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
module lexer

import cotowali.token { Token }
import cotowali.source { Char }
import cotowali.util { Unit }

[inline]
fn is_slash(c Char) bool {
	return c.byte() == `/`
}

fn (mut lex Lexer) try_skip_comment() ?Unit {
	cc := '${lex.char(0)}${lex.char(1)}'
	match cc {
		'//' { lex.skip_line_comment() }
		'/*' { lex.skip_block_comment() }
		else { return none }
	}

	return Unit{}
}

fn (mut lex Lexer) try_read_doc_comment() ?Token {
	ccc := '${lex.char(0)}${lex.char(1)}${lex.char(2)}'
	if ccc == '///' {
		lex.skip_n(3)
		lex.consume_not_for(is_eol)
		return lex.new_token(.doc_comment)
	}
	return none
}

// --

fn (mut lex Lexer) skip_line_comment() {
	$if trace_lexer ? {
		lex.trace_begin(@FN)
		defer {
			lex.trace_end()
		}
	}

	lex.skip_not_for(is_eol)
}

fn (mut lex Lexer) read_line_doc_comment() ?Token {
	$if trace_lexer ? {
		lex.trace_begin(@FN)
		defer {
			lex.trace_end()
		}
	}

	lex.skip_with_assert(is_slash)
	lex.skip_with_assert(is_slash)
	lex.skip_with_assert(is_slash)

	lex.consume_not_for(is_eol)
	return lex.new_token(.doc_comment)
}

// --

fn (mut lex Lexer) skip_block_comment() {
	$if trace_lexer ? {
		lex.trace_begin(@FN)
		defer {
			lex.trace_end()
		}
	}

	lex.skip_with_assert(is_slash)
	lex.skip_with_assert(fn (c Char) bool {
		return c[0] == `*`
	})

	mut depth := 1
	for depth > 0 {
		// '/*'
		if lex.byte() == `/` && lex.char(1).byte() == `*` {
			depth++
		}

		// '*/'
		if lex.prev_char[0] == `*` && lex.byte() == `/` {
			depth--
		}

		lex.skip()
	}
}
