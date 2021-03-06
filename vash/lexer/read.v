module lexer

import vash.token { Token }
import vash.pos

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

	return match lex.char()[0] {
		`(` { lex.new_token_with_consume(.l_par) }
		`)` { lex.new_token_with_consume(.r_par) }
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
