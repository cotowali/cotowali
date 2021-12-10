// Copyright (c) 2021 zakuro <z@kuro.red>. All rights reserved.
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
module lexer

import cotowali.token { Token }
import cotowali.source { Char }
import cotowali.util { li_panic }

const (
	sq = `'`
	dq = `"`
	bs = `\\`
)

[params]
struct StringLiteralParams {
	is_glob bool
}

fn is_glob_char(c Char) bool {
	return c in ['*', '?']
}

fn (mut lex Lexer) read_single_quote_string_literal_content(params StringLiteralParams) Token {
	$if trace_lexer ? {
		lex.trace_begin(@FN)
		defer {
			lex.trace_end()
		}
	}

	if params.is_glob && is_glob_char(lex.char(0)) {
		lex.consume_for(fn (c Char) bool {
			return is_glob_char(c)
		})
		return lex.new_token(.string_literal_content_glob)
	}

	if lex.byte() == lexer.bs {
		next := lex.char(1)[0]
		if next == lexer.bs {
			return lex.new_token_with_consume_n(2, .string_literal_content_escaped_back_slash)
		} else if next == lexer.sq {
			return lex.new_token_with_consume_n(2, .string_literal_content_escaped_single_quote)
		}
	}

	for !lex.is_eof() {
		if lex.byte() == lexer.sq {
			break
		}
		if lex.byte() == lexer.bs && lex.char(1).byte() in [lexer.bs, lexer.sq] {
			// next is \\ or \'
			break
		}
		if params.is_glob && is_glob_char(lex.char(0)) {
			break
		}

		lex.consume()
	}

	tok := lex.new_token(.string_literal_content_text)
	return tok
}

fn (mut lex Lexer) read_double_quote_string_literal_content(params StringLiteralParams) Token {
	$if trace_lexer ? {
		lex.trace_begin(@FN)
		defer {
			lex.trace_end()
		}
	}

	if params.is_glob && is_glob_char(lex.char(0)) {
		lex.consume_for(fn (c Char) bool {
			return is_glob_char(c)
		})
		return lex.new_token(.string_literal_content_glob)
	}

	if lex.byte() == `$` {
		lex.consume()
		if is_ident_first_char(lex.char(0)) {
			lex.read_ident_or_keyword()
			return lex.new_token(.string_literal_content_var)
		} else if lex.byte() == `{` {
			lex.lex_ctx.push(kind: .inside_string_literal_expr_substitution)
			lex.consume()
			return lex.new_token(.string_literal_content_expr_open)
		}
	}

	if lex.byte() == lexer.bs {
		match lex.char(1).byte() {
			lexer.bs {
				return lex.new_token_with_consume_n(2, .string_literal_content_escaped_back_slash)
			}
			`$` {
				return lex.new_token_with_consume_n(2, .string_literal_content_escaped_dollar)
			}
			lexer.dq {
				return lex.new_token_with_consume_n(2, .string_literal_content_escaped_double_quote)
			}
			`n` {
				return lex.new_token_with_consume_n(2, .string_literal_content_escaped_newline)
			}
			`x` {
				lex.consume_n(2)
				if lex.char(0).@is(.hex_digit) && lex.char(1).@is(.hex_digit) {
					return lex.new_token_with_consume_n(2, .string_literal_content_hex)
				}
			}
			else {
				li_panic(@FN, @LINE, '')
			}
		}
	}

	for !lex.is_eof() {
		if lex.byte() in [lexer.dq, lexer.bs, `$`] {
			break
		}
		if params.is_glob && is_glob_char(lex.char(0)) {
			break
		}

		lex.consume()
	}

	tok := lex.new_token(.string_literal_content_text)
	return tok
}

fn (mut lex Lexer) read_raw_string_literal_content(quote byte) Token {
	$if trace_lexer ? {
		lex.trace_begin(@FN)
		defer {
			lex.trace_end()
		}
	}

	for !(lex.byte() == quote || lex.is_eof()) {
		lex.consume()
	}

	return lex.new_token(.string_literal_content_text)
}

pub fn (mut lex Lexer) try_read_for_string_literal() ?Token {
	match lex.lex_ctx.current.kind {
		.inside_single_quoted_string_literal {
			if lex.byte() == lexer.sq {
				lex.lex_ctx.pop()
				return lex.new_token_with_consume(.single_quote)
			}
			return lex.read_single_quote_string_literal_content()
		}
		.inside_double_quoted_string_literal {
			if lex.byte() == lexer.dq {
				lex.lex_ctx.pop()
				return lex.new_token_with_consume(.double_quote)
			}
			return lex.read_double_quote_string_literal_content()
		}
		.inside_single_quoted_glob_literal {
			if lex.byte() == lexer.sq {
				lex.lex_ctx.pop()
				return lex.new_token_with_consume(.single_quote)
			}
			return lex.read_single_quote_string_literal_content(is_glob: true)
		}
		.inside_double_quoted_glob_literal {
			if lex.byte() == lexer.dq {
				lex.lex_ctx.pop()
				return lex.new_token_with_consume(.double_quote)
			}
			return lex.read_double_quote_string_literal_content(is_glob: true)
		}
		.inside_raw_single_quoted_string_literal {
			if lex.byte() == lexer.sq {
				lex.lex_ctx.pop()
				return lex.new_token_with_consume(.single_quote)
			}
			return lex.read_raw_string_literal_content(lexer.sq)
		}
		.inside_raw_double_quoted_string_literal {
			if lex.byte() == lexer.dq {
				lex.lex_ctx.pop()
				return lex.new_token_with_consume(.double_quote)
			}
			return lex.read_raw_string_literal_content(lexer.dq)
		}
		.inside_string_literal_expr_substitution, .inside_inline_shell_expr_substitution, .normal {
			b := lex.byte()
			b2 := lex.char(1)[0]
			if b == lexer.sq {
				lex.lex_ctx.push(kind: .inside_single_quoted_string_literal)
				return lex.new_token_with_consume(.single_quote)
			} else if b == lexer.dq {
				lex.lex_ctx.push(kind: .inside_double_quoted_string_literal)
				return lex.new_token_with_consume(.double_quote)
			} else if b == `r` {
				if b2 == lexer.sq {
					lex.lex_ctx.push(kind: .inside_raw_single_quoted_string_literal)
					return lex.new_token_with_consume_n(2, .single_quote_with_r_prefix)
				} else if b2 == lexer.dq {
					lex.lex_ctx.push(kind: .inside_raw_double_quoted_string_literal)
					return lex.new_token_with_consume_n(2, .double_quote_with_r_prefix)
				}
			} else if b == `@` {
				if b2 == lexer.sq {
					lex.lex_ctx.push(kind: .inside_single_quoted_glob_literal)
					return lex.new_token_with_consume_n(2, .single_quote_with_at_prefix)
				} else if b2 == lexer.dq {
					lex.lex_ctx.push(kind: .inside_double_quoted_glob_literal)
					return lex.new_token_with_consume_n(2, .double_quote_with_at_prefix)
				}
			}
		}
		.inside_inline_shell {}
	}
	return none
}
