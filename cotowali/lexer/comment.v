// Copyright (c) 2021 zakuro <z@kuro.red>. All rights reserved.
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
module lexer

import cotowali.source { Char }

fn (mut lex Lexer) skip_line_comment() {
	$if trace_lexer ? {
		lex.trace_begin(@FN)
		defer {
			lex.trace_end()
		}
	}

	lex.skip_not_for(is_eol)
}

fn (mut lex Lexer) skip_block_comment() {
	$if trace_lexer ? {
		lex.trace_begin(@FN)
		defer {
			lex.trace_end()
		}
	}

	lex.skip_with_assert(fn (c Char) bool {
		return c[0] == `/`
	})
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
