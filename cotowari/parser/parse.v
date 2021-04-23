module parser

import cotowari.source
import cotowari.lexer { new_lexer }
import cotowari.ast

pub fn (mut p Parser) parse() ast.File {
	p.file = ast.File{
		source: p.lexer.source
		scope: p.scope
	}
	for p.kind(0) != .eof {
		p.file.stmts << p.parse_stmt()
	}
	return p.file
}

pub fn parse_file(path string) ?ast.File {
	s := source.read_file(path) ?
	mut p := new_parser(new_lexer(s))
	return p.parse()
}
