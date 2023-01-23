// Copyright (c) 2021 zakuro <z@kuro.red>. All rights reserved.
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
module lexer

import cotowali.token { Token }

fn (mut lex Lexer) read_inline_shell_content() ?Token {
	// TODO: Implement shell parser to report syntax error.
	// Current parser only detect nested brace.

	if lex.byte() == `%` {
		lex.consume()
		if lex.byte() == `{` {
			lex.lex_ctx.push(kind: .inside_inline_shell_expr_substitution)
			return lex.new_token_with_consume(.inline_shell_content_expr_substitution_open)
		}
		lex.consume_for_ident()
		return lex.new_token(.inline_shell_content_var)
	}

	for {
		if lex.is_eof() {
			return lex.error(lex.new_token(.inline_shell_content_text), 'unterminated inline shell')
		}
		match lex.byte() {
			`{` {
				lex.lex_ctx.current.inline_shell_brace_depth++
			}
			`}` {
				lex.lex_ctx.current.inline_shell_brace_depth--
			}
			`%` {
				if lex.char(1).byte() == `%` {
					// escaped %
					// consume first %. next % will be consumed like all other chars
					lex.consume()
				} else {
					break // terminate .inline_shell_content_text
				}
			}
			else {}
		}
		if lex.lex_ctx.current.inline_shell_brace_depth == 0 {
			lex.lex_ctx.pop()
			break
		}
		lex.consume()
	}
	return Token{
		kind: .inline_shell_content_text
		pos: lex.pos_for_new_token()
		text: lex.text().replace('%%', '%') // replace escaped %. And text will be raw shell code
	}
}
