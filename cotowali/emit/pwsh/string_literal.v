// Copyright (c) 2021 zakuro <z@kuro.red>. All rights reserved.
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
module pwsh

import cotowali.ast { Expr, StringLiteral }
import cotowali.token { Token }
import cotowali.symbols { builtin_type }
import cotowali.util { li_panic }

const invalid_string_literal = 'invalid string literal'

fn (mut e Emitter) single_quote_string_literal(expr StringLiteral) {
	e.write("'")
	defer {
		e.write("'")
	}
	for v in expr.contents {
		if v is Token {
			match v.kind {
				.string_literal_content_escaped_back_slash {
					e.write(r'\') // no need to escape backslash in powershell
				}
				.string_literal_content_escaped_single_quote {
					e.write("''")
				}
				.string_literal_content_text {
					e.write('$v.text')
				}
				.string_literal_content_glob {
					li_panic(@FILE, @LINE, 'glob is unimplemented')
				}
				else {
					li_panic(@FILE, @LINE, pwsh.invalid_string_literal)
				}
			}
		} else {
			li_panic(@FILE, @LINE, pwsh.invalid_string_literal)
		}
	}
}

fn (mut e Emitter) double_quote_string_literal(expr StringLiteral) {
	e.write('"')
	defer {
		e.write('"')
	}
	for v in expr.contents {
		if v is Token {
			match v.kind {
				.string_literal_content_escaped_newline {
					e.write('`n')
				}
				.string_literal_content_escaped_double_quote {
					e.write('""')
				}
				.string_literal_content_escaped_back_slash {
					e.write(r'\') // no need to escape backslash in powershell
				}
				.string_literal_content_escaped_dollar {
					e.write(r'`$')
				}
				.string_literal_content_glob {
					li_panic(@FILE, @LINE, 'glob is unimplemented')
				}
				.string_literal_content_hex {
					hex := '0' + v.text[1..] // tirm \xff -> 0xff
					e.write('\$([char]$hex)')
				}
				.string_literal_content_back_quote {
					e.write('``')
				}
				else {
					e.write(v.text.replace('`', '``')) // need to escape backquote in double-quoted literal
				}
			}
		} else if v is Expr {
			e.write(r'$(')
			e.expr(v.@as(builtin_type(.string)))
			e.write(r')')
		} else {
			li_panic(@FILE, @LINE, pwsh.invalid_string_literal)
		}
	}
}

fn (mut e Emitter) raw_string_literal(expr StringLiteral) {
	if expr.contents.len != 1 {
		li_panic(@FILE, @LINE, pwsh.invalid_string_literal)
	}

	content := expr.contents[0]
	if content is Token {
		text := match expr.close.kind {
			.single_quote { content.text }
			.double_quote { content.text.replace("'", "''") }
			else { li_panic(@FILE, @LINE, pwsh.invalid_string_literal) }
		}
		e.write("'$text'")
	} else {
		li_panic(@FILE, @LINE, pwsh.invalid_string_literal)
	}
}

fn (mut e Emitter) string_literal(expr StringLiteral, opt ExprOpt) {
	if expr.contents.len == 0 {
		e.write("''")
		return
	}
	match expr.open.kind {
		.single_quote, .single_quote_with_at_prefix { e.single_quote_string_literal(expr) }
		.double_quote, .double_quote_with_at_prefix { e.double_quote_string_literal(expr) }
		.single_quote_with_r_prefix, .double_quote_with_r_prefix { e.raw_string_literal(expr) }
		else { li_panic(@FILE, @LINE, 'not a string') }
	}
}
