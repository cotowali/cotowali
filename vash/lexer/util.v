module lexer

import vash.source { Letter, Source }
import vash.token { Token, TokenKind }
import vash.pos { Pos }

[inline]
fn (lex &Lexer) idx() int {
	return lex.pos.i + lex.pos.len - 1
}

[inline]
fn (lex &Lexer) letter() Letter {
	if lex.is_eof() {
		return Letter('')
	}
	return lex.source.at(lex.idx())
}

[inline]
fn (mut lex Lexer) close() {
	lex.closed = true
}

fn (lex &Lexer) pos_for_new_token() Pos {
	last_col := lex.pos.last_col - 1
	last_line := lex.pos.last_line + (if last_col == 0 { -1 } else { 0 })
	return Pos{
		...lex.pos
		len: lex.pos.len - 1
		last_line: last_line
		last_col: last_col
	}
}

[inline]
fn (lex &Lexer) new_token(kind TokenKind) Token {
	return Token{
		kind: kind
		text: lex.text()
		pos: lex.pos_for_new_token()
	}
}

[inline]
fn (mut lex Lexer) advance(n int) {
	lex.pos.len += lex.letter().len
	lex.pos.last_col += n
}

fn (mut lex Lexer) start() {
	// if pos is head, do nothing
	if lex.idx() == 0 {
		return
	}

	lex.pos = pos.new(
		i: lex.idx()
		col: lex.pos.last_col
		line: lex.pos.last_line
	)
}

[inline]
fn (lex &Lexer) text() string {
	return lex.source.slice(lex.pos.i, lex.idx())
}
