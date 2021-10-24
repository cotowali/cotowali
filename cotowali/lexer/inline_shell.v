// Copyright (c) 2021 zakuro <z@kuro.red>. All rights reserved.
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
module lexer

import cotowali.token { Token }

fn (mut lex Lexer) read_inline_shell_content() ?Token {
	$if trace_lexer ? {
		lex.trace_begin(@FN)
		defer {
			lex.trace_end()
		}
	}

	// TODO: Implement shell parser to report syntax error.
	// Current parser only detect nested brace.

	if lex.byte() == `%` {
		lex.consume()
		lex.consume_for_ident()
		return lex.new_token(.inline_shell_content_var)
	}

	for {
		if lex.is_eof() {
			return lex.error(lex.new_token(.inline_shell_content_text), 'unterminated inline shell')
		}
		match lex.byte() {
			`{` { lex.lex_ctx.current.inline_shell_brace_depth++ }
			`}` { lex.lex_ctx.current.inline_shell_brace_depth-- }
			`%` { break } // terminate .inline_shell_content_text
			else {}
		}
		if lex.lex_ctx.current.inline_shell_brace_depth == 0 {
			lex.lex_ctx.pop()
			break
		}
		lex.consume()
	}
	tok := lex.new_token(.inline_shell_content_text)
	return tok
}
