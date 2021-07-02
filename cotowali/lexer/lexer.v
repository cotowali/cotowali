module lexer

import cotowali.token { Token }
import cotowali.source { Char }
import cotowali.errors { ErrWithToken, unreachable }

pub fn (mut lex Lexer) next() ?Token {
	if lex.closed {
		return none
	}
	return lex.read() or {
		if err is ErrWithToken {
			return err.token
		}
		panic(unreachable())
	}
}

fn (mut lex Lexer) prepare_to_read() {
	lex.skip_whitespaces()
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

		c := lex.char(0)
		if is_ident_first_char(c) {
			return lex.read_ident_or_keyword()
		} else if is_digit(c) {
			return lex.read_number()
		} else if lex.is_eol() {
			return lex.read_newline()
		}

		mut kind := k(.unknown)

		ccc := '${lex.char(0)}${lex.char(1)}${lex.char(2)}'

		kind = table_for_three_chars_symbols[ccc] or { k(.unknown) }
		if kind != .unknown {
			return lex.new_token_with_consume_n(3, kind)
		}

		cc := ccc[..2]

		if cc == '//' {
			// comment
			lex.skip_not_for(is_eol)
			continue
		}

		kind = table_for_two_chars_symbols[cc] or { k(.unknown) }
		if kind != .unknown {
			return lex.new_token_with_consume_n(2, kind)
		}

		kind = table_for_one_char_symbols[c.byte()] or { k(.unknown) }
		if kind != .unknown {
			return lex.new_token_with_consume(kind)
		}

		match c.byte() {
			`@` { return lex.read_at_ident() }
			`\$` { return lex.read_dollar_directive() }
			`\'`, `"` { return lex.read_string_lit(c.byte()) }
			else { return lex.read_unknown() }
		}
	}
	panic(unreachable())
}

fn (lex Lexer) is_eol() bool {
	return is_eol(lex.char(0))
}

fn (mut lex Lexer) read_newline() Token {
	$if trace_lexer ? {
		lex.trace_begin(@FN)
		defer {
			lex.trace_end()
		}
	}

	if lex.char(0).byte() == `\r` && lex.char(1).byte() == `\n` {
		lex.consume()
	}
	return lex.new_token_with_consume(.eol)
}

fn (mut lex Lexer) read_string_lit(quote byte) ?Token {
	$if trace_lexer ? {
		lex.trace_begin(@FN, '$quote')
		defer {
			lex.trace_end()
		}
	}

	lex.consume()
	begin := lex.idx()
	mut unterminated := false
	for lex.char(0).byte() != quote {
		lex.consume()
		if lex.is_eof() || is_eol(lex.char(0)) {
			unterminated = true
			break
		}
	}

	end := lex.idx()
	if !unterminated {
		lex.consume() // consume quote.
	}

	tok := Token{
		kind: .string_lit
		pos: lex.pos_for_new_token()
		text: lex.source.slice(begin, end)
	}
	if unterminated {
		return lex.error(tok, 'unterminated string literal')
	}
	return tok
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
	kind := table_for_keywords[text] or { k(.ident) }
	return Token{
		pos: pos
		text: text
		kind: kind
	}
}

fn (mut lex Lexer) read_number() Token {
	$if trace_lexer ? {
		lex.trace_begin(@FN)
		defer {
			lex.trace_end()
		}
	}

	return lex.new_token_with_consume_for(is_digit, .int_lit)
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
	}, .at_ident)
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
	if lex.char(0).byte() == `{` {
		lex.skip()
		for lex.char(0).byte() != `}` {
			if lex.is_eof() {
				panic('unterminated inline shell')
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
