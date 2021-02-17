module lexer

import vash.source

pub struct Lexer {
pub mut:
	source source.Source
mut:
	current source.Letter // utf8 character
	i       int
}

pub fn new(source source.Source) Lexer {
	return Lexer{
		source: source
		current: source.at(0)
	}
}
