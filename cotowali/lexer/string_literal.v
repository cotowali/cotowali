// Copyright (c) 2021 zakuro <z@kuro.red>. All rights reserved.
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
module lexer

import cotowali.token { Token }
import cotowali.source { Char }

const (
	sq = `'`
	dq = `"`
	bs = `\\`
)

fn (mut lex Lexer) read_single_quote_string_literal_content() Token {
	$if trace_lexer ? {
		lex.trace_begin(@FN)
		defer {
			lex.trace_end()
		}
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

		lex.consume()
	}

	tok := lex.new_token(.string_literal_content_text)
	return tok
}

fn (mut lex Lexer) read_double_quote_string_literal_content() Token {
	$if trace_lexer ? {
		lex.trace_begin(@FN)
		defer {
			lex.trace_end()
		}
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
		next := lex.char(1).byte()
		if next == lexer.bs {
			return lex.new_token_with_consume_n(2, .string_literal_content_escaped_back_slash)
		} else if next == `$` {
			return lex.new_token_with_consume_n(2, .string_literal_content_escaped_dollar)
		} else if next == lexer.dq {
			return lex.new_token_with_consume_n(2, .string_literal_content_escaped_double_quote)
		} else if next == `n` {
			return lex.new_token_with_consume_n(2, .string_literal_content_escaped_newline)
		}
	}

	lex.consume_not_for(fn (c Char) bool {
		return c.byte() in [lexer.dq, lexer.bs, `$`]
	})

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
		.inside_string_literal_expr_substitution, .normal {
			b := lex.byte()
			if b == lexer.sq {
				lex.lex_ctx.push(kind: .inside_single_quoted_string_literal)
				return lex.new_token_with_consume(.single_quote)
			} else if b == lexer.dq {
				lex.lex_ctx.push(kind: .inside_double_quoted_string_literal)
				return lex.new_token_with_consume(.double_quote)
			} else if b == `r` {
				b2 := lex.char(1)[0]
				if b2 == lexer.sq {
					lex.lex_ctx.push(kind: .inside_raw_single_quoted_string_literal)
					return lex.new_token_with_consume_n(2, .single_quote_with_r_prefix)
				} else if b2 == lexer.dq {
					lex.lex_ctx.push(kind: .inside_raw_double_quoted_string_literal)
					return lex.new_token_with_consume_n(2, .double_quote_with_r_prefix)
				}
			}
		}
		.inside_inline_shell {}
	}
	return none
}
