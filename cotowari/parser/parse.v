module parser

import cotowari.source
import cotowari.lexer
import cotowari.token { TokenKind }
import cotowari.ast
import cotowari.symbols

pub fn (mut p Parser) parse() ast.File {
	p.file = ast.File{
		path: p.source().path
		scope: p.scope
	}
	for !p.@is(.eof) {
		p.file.stmts << p.parse_stmt()
	}
	return p.file
}

pub fn parse_file(path string) ?ast.File {
	s := source.read_file(path) ?
	mut p := new(lexer.new(s))
	return p.parse()
}
