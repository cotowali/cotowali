module lexer

import vash.source
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

	if kind := letter_to_kind(lex.letter()) {
		lex.consume()
		return lex.new_token(kind)
	}

	match lex.letter().str() {
		'\r' {
			lex.consume()
			if lex.letter() == '\n' {
				lex.consume()
			}
			return lex.new_token(.eol)
		}
		'\n' {
			lex.consume()
			return lex.new_token(.eol)
		}
		else {}
	}

	for !(lex.is_eof() || lex.letter().is_whitespace() || lex.letter() == '\n') {
		if _ := letter_to_kind(lex.letter()) {
			break
		}
		lex.consume()
	}
	return lex.new_token(.unknown)
}
