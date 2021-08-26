// Copyright (c) 2021 zakuro <z@kuro.red>. All rights reserved.
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
module parser

import cotowali.context { Context }
import cotowali.source { Source }
import cotowali.symbols { Scope }
import cotowali.ast

pub fn (mut p Parser) parse(scope &Scope) &ast.File {
	p.scope = scope
	mut file := &ast.File{
		source: p.source()
	}

	mut ctx := p.ctx
	if !ctx.std_loaded() {
		ctx.std_source = source.std
		mut std_parser := new_parser(ctx.std_source, ctx)
		file.stmts << ast.RequireStmt{std_parser.parse(ctx.global_scope)}
	}

	p.ctx.sources[p.source().path] = file.source

	p.skip_eol()
	for p.kind(0) != .eof {
		file.stmts << p.parse_stmt()
	}
	return file
}

pub fn parse(s &Source, ctx &Context) &ast.File {
	mut p := new_parser(s, ctx)
	return p.parse(ctx.global_scope)
}

pub fn parse_file(path string, ctx &Context) ?&ast.File {
	return parse(source.read_file(path) ?, ctx)
}
