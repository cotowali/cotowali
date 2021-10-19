// Copyright (c) 2021 zakuro <z@kuro.red>. All rights reserved.
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
module parser

import cotowali.context { Context }
import cotowali.source { Source, SourceScheme }
import cotowali.symbols { Scope }
import cotowali.ast
import net.urllib { URL }
import net.http

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
	if path in ctx.sources {
		return none
	}
	return parse(source.read_file(path) ?, ctx)
}

pub fn parse_remote_file(url &URL, ctx &Context) ?&ast.File {
	url_str := url.str()

	mut scheme := SourceScheme.local // placeholder
	// return stmt in match expr will be compile error. so we use match stmt
	match url.scheme {
		'http' { scheme = SourceScheme.http }
		'https' { scheme = SourceScheme.https }
		else { return error('invalid scheme: $url.scheme') }
	}

	path := url_str.trim_prefix('$url.scheme:').trim_prefix('//')
	if path in ctx.sources {
		return none
	}

	res := http.get(url_str) or { return error('failed to get $url_str') }
	if res.status() != .ok {
		return error('faild to get $url_str ($res.status_code $res.status_msg)')
	}
	source_code := res.text

	return parse(&Source{
		scheme: scheme
		path: path
		code: source_code
	}, ctx)
}
