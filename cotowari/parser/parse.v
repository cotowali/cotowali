module parser

import cotowari.context { Context }
import cotowari.source
import cotowari.lexer { new_lexer }
import cotowari.ast

pub fn (mut p Parser) parse() &ast.File {
	if !p.ctx.std_loaded() {
		p.ctx.std_source = source.std
		mut std_parser := new_parser(new_lexer(p.ctx.std_source, p.ctx))
		p.file.stmts << ast.RequireStmt{std_parser.parse()}
	}

	p.ctx.sources[p.source().path] = p.source()

	p.skip_eol()
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
