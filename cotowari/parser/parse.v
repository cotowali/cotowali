module parser

import cotowari.context { Context }
import cotowari.source
import cotowari.lexer { new_lexer }
import cotowari.ast

pub fn (mut p Parser) parse() &ast.File {
	p.ctx.sources[p.source().path] = p.source()
	for p.kind(0) != .eof {
		p.file.stmts << p.parse_stmt()
	}
	return p.file
}

pub fn parse_file(path string, ctx &Context) ?&ast.File {
	s := source.read_file(path) ?
	mut p := new_parser(new_lexer(s, ctx))
	return p.parse()
}
