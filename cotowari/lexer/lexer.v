module lexer

import cotowari.token { Token }
import cotowari.source { Char }
import cotowari.errors { unreachable }

pub fn (mut lex Lexer) next() ?Token {
	if lex.closed {
		return none
	}
	return lex.read()
}

fn (mut lex Lexer) prepare_to_read() {
	lex.skip_whitespaces()
	lex.start_pos()
}

pub fn (mut lex Lexer) read() Token {
	for {
		lex.prepare_to_read()
		if lex.is_eof() {
			lex.close()
			return Token{.eof, '', lex.pos}
		}

		c := lex.char()
		if is_ident_first_char(c) {
			return lex.read_ident_or_keyword()
		} else if is_digit(c) {
			return lex.read_number()
		}

		match c[0] {
			`+` {
				return if lex.next_char()[0] == `+` {
					lex.new_token_with_consume_n(2, .op_plus_plus)
				} else {
					lex.new_token_with_consume(.op_plus)
				}
			}
			`-` {
				return if lex.next_char()[0] == `-` {
					lex.new_token_with_consume_n(2, .op_minus_minus)
				} else {
					lex.new_token_with_consume(.op_minus)
				}
			}
			`/` {
				if lex.next_char()[0] == `/` {
					lex.skip_not_for(is_eol)
					continue
				}
				return lex.new_token_with_consume(.op_div)
			}
			`&` {
				return if lex.next_char()[0] == `&` {
					lex.new_token_with_consume_n(2, .op_and)
				} else {
					lex.new_token_with_consume(.amp)
				}
			}
			`|` {
				return if lex.next_char()[0] == `|` {
					lex.new_token_with_consume_n(2, .op_or)
				} else {
					lex.new_token_with_consume(.pipe)
				}
			}
			`=` {
				return if lex.next_char()[0] == `=` {
					lex.new_token_with_consume_n(2, .op_eq)
				} else {
					lex.new_token_with_consume(.op_assign)
				}
			}
			`!` {
				return if lex.next_char()[0] == `=` {
					lex.new_token_with_consume_n(2, .op_ne)
				} else {
					lex.new_token_with_consume(.op_not)
				}
			}
			`<` {
				return lex.new_token_with_consume(.op_lt)
			}
			`>` {
				return lex.new_token_with_consume(.op_gt)
			}
			else {
				if lex.is_eol() {
					return lex.read_newline()
				}
			}
		}
		return match c[0] {
			`(` { lex.new_token_with_consume(.l_paren) }
			`)` { lex.new_token_with_consume(.r_paren) }
			`{` { lex.new_token_with_consume(.l_brace) }
			`}` { lex.new_token_with_consume(.r_brace) }
			`[` { lex.new_token_with_consume(.l_bracket) }
			`]` { lex.new_token_with_consume(.r_bracket) }
			`*` { lex.new_token_with_consume(.op_mul) }
			`%` { lex.new_token_with_consume(.op_mod) }
			`,` { lex.new_token_with_consume(.comma) }
			`.` { lex.new_token_with_consume(.dot) }
			`@` { lex.read_at_ident() }
			`\$` { lex.read_dollar_directive() }
			`\'`, `"` { lex.read_string_lit(c[0]) }
			else { lex.read_unknown() }
		}
	}
	panic(unreachable)
}

fn (lex Lexer) is_eol() bool {
	return lex.char()[0] in [`\n`, `\r`]
}

fn (mut lex Lexer) read_newline() Token {
	if lex.char()[0] == `\r` && lex.next_char() == '\n' {
		lex.consume()
	}
	return lex.new_token_with_consume(.eol)
}

fn (mut lex Lexer) read_string_lit(quote byte) Token {
	lex.assert_by_match_byte(quote)
	lex.consume()
	for lex.char()[0] != quote {
		lex.consume()
		if lex.is_eof() || lex.is_eol() {
			panic('unterminated string literal') // TODO: error handling
		}
	}
	lex.assert_by_match_byte(quote)
	lex.consume()
	text := lex.text()
	return Token{
		kind: .string_lit
		pos: lex.pos_for_new_token()
		text: text[1..text.len - 1]
	}
}

fn (mut lex Lexer) read_unknown() Token {
	for !(lex.is_eof() || lex.char().@is(.whitespace) || lex.char() == '\n') {
		lex.consume()
	}
	return lex.new_token(.unknown)
}

fn is_ident_first_char(c Char) bool {
	return c.@is(.alphabet) || c[0] == `_`
}

fn is_ident_char(c Char) bool {
	return is_ident_first_char(c) || is_digit(c) || c[0] == `-`
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
	lex.consume_for(is_ident_char)
	text := lex.text()
	pos := lex.pos_for_new_token()
	kind := match text {
		'assert' { k(.key_assert) }
		'let' { k(.key_let) }
		'if' { k(.key_if) }
		'else' { k(.key_else) }
		'for' { k(.key_for) }
		'in' { k(.key_in) }
		'fn' { k(.key_fn) }
		'return' { k(.key_return) }
		'decl' { k(.key_decl) }
		'struct' { k(.key_struct) }
		'true', 'false' { k(.bool_lit) }
		else { k(.ident) }
	}
	return Token{
		pos: pos
		text: text
		kind: kind
	}
}

fn (mut lex Lexer) read_number() Token {
	return lex.new_token_with_consume_for(is_digit, .int_lit)
}

fn (mut lex Lexer) read_at_ident() Token {
	lex.skip_with_assert(fn (c Char) bool {
		return c == '@'
	})
	return lex.new_token_with_consume_not_for(is_whitespace, .ident)
}

fn (mut lex Lexer) read_dollar_directive() Token {
	lex.skip_with_assert(fn (c Char) bool {
		return c[0] == `\$`
	})
	if lex.char()[0] == `{` {
		lex.skip()
		for lex.char()[0] != `}` {
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
