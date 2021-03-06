module lexer

import vash.token { Token }
import vash.pos
import vash.source { Char }

pub fn (mut lex Lexer) next() ?Token {
	return if !lex.closed { lex.read() } else { none }
}

fn (mut lex Lexer) prepare_to_read() {
	lex.skip_whitespaces()
	lex.pos = pos.new(
		i: lex.idx()
		col: lex.pos.last_col
		line: lex.pos.last_line
	)
}

pub fn (mut lex Lexer) read() Token {
	lex.prepare_to_read()
	if lex.is_eof() {
		lex.close()
		return Token{.eof, '', lex.pos}
	}

	c := lex.char()
	if is_ident_first_char(c) {
		return lex.read_ident()
	} else if is_digit(c) {
		return lex.read_number()
	}

	return match c[0] {
		`(` { lex.new_token_with_consume(.l_par) }
		`)` { lex.new_token_with_consume(.r_par) }
		`+` { lex.new_token_with_consume(.plus) }
		`-` { lex.new_token_with_consume(.minus) }
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
	for !(lex.is_eof() || lex.char_is(.whitespace) || lex.char() == '\n') {
		lex.consume()
	}
	return lex.new_token(.unknown)
}

fn is_ident_first_char(c Char) bool {
	return c.@is(.alphabet) || c[0] == `_`
}

fn is_ident_char(c Char) bool {
	return is_ident_first_char(c) || is_digit(c)
}

fn is_digit(c Char) bool {
	return c.@is(.digit)
}

fn (mut lex Lexer) read_ident() Token {
	lex.consume_for(is_ident_char)
	return lex.new_token(.ident)
}

fn (mut lex Lexer) read_number() Token {
	lex.consume_for(is_digit)
	return lex.new_token(.int_lit)
}
