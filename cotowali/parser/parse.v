// Copyright (c) 2021 zakuro <z@kuro.red>. All rights reserved.
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
module parser

import cotowali.context { Context }
import cotowali.source
import cotowali.ast

pub fn (mut p Parser) parse() &ast.File {
	mut file := &ast.File{
		source: p.source()
	}

	if !p.ctx.std_loaded() {
		p.ctx.std_source = source.std
		mut std_parser := new_parser(p.ctx.std_source, p.ctx)
		file.stmts << ast.RequireStmt{std_parser.parse()}
	}

	p.ctx.sources[p.source().path] = file.source

	p.skip_eol()
	for p.kind(0) != .eof {
		file.stmts << p.parse_stmt()
	}
	return file
}

pub fn parse_file(path string, ctx &Context) ?&ast.File {
	s := source.read_file(path) ?
	mut p := new_parser(s, ctx)
	return p.parse()
}
