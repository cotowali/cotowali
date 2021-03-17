module lexer

import vash.token { Token }
import vash.source { Char }

pub fn (mut lex Lexer) next() ?Token {
	if lex.closed {
		return none
	}
	return lex.read()
}

fn (mut lex Lexer) prepare_to_read() {
	lex.skip_whitespaces()
	lex.start_new_pos()
}

pub fn (mut lex Lexer) read() Token {
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
		`&` {
			if lex.next_char()[0] == `&` {
				lex.consume()
				return lex.new_token_with_consume(.op_and)
			}
			return lex.new_token_with_consume(.amp)
		}
		else {}
	}
	return match c[0] {
		`(` { lex.new_token_with_consume(.l_paren) }
		`)` { lex.new_token_with_consume(.r_paren) }
		`{` { lex.new_token_with_consume(.l_brace) }
		`}` { lex.new_token_with_consume(.r_brace) }
		`[` { lex.new_token_with_consume(.l_bracket) }
		`]` { lex.new_token_with_consume(.r_bracket) }
		`+` { lex.new_token_with_consume(.op_plus) }
		`-` { lex.new_token_with_consume(.op_minus) }
		`*` { lex.new_token_with_consume(.op_mul) }
		`/` { lex.new_token_with_consume(.op_div) }
		`.` { lex.new_token_with_consume(.dot) }
		`@` { lex.read_at_ident() }
		`\r`, `\n` { lex.read_newline() }
		else { lex.read_unknown() }
	}
}

fn (mut lex Lexer) read_newline() Token {
	if lex.char()[0] == `\r` && lex.next_char() == '\n' {
		lex.consume()
	}
	return lex.new_token_with_consume(.eol)
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

fn (mut lex Lexer) skip_whitespaces() {
	lex.consume_for(is_whitespace)
}

fn (mut lex Lexer) read_ident_or_keyword() Token {
	lex.consume_for(is_ident_char)
	text := lex.text()
	pos := lex.pos_for_new_token()
	kind := match text {
		'let' { k(.key_let) }
		'if' { k(.key_if) }
		'for' { k(.key_for) }
		'in' { k(.key_in) }
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
	lex.consume_for(is_digit)
	return lex.new_token(.int_lit)
}

fn (mut lex Lexer) read_at_ident() Token {
	lex.skip_with_assert(fn (c Char) bool {
		return c == '@'
	})
	lex.consume_not_for(is_whitespace)
	return lex.new_token(.ident)
}
