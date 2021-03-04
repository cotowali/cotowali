module lexer

import vash.source { Letter, Source }
import vash.token { Token, TokenKind }
import vash.pos { Pos }



pub fn (mut lex Lexer) next() ?Token {
	return if !lex.closed { lex.read() } else { none }
}

pub fn (mut lex Lexer) read() Token {
	lex.skip_whitespaces()
	lex.start()
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
