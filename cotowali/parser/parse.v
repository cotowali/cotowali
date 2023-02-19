// Copyright (c) 2021-2023 zakuro <z@kuro.red>. All rights reserved.
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
module parser

import cotowali.context { Context }
import cotowali.environment { cotowali_builtin_path, cotowali_testing_path, find_file_path_in_cotowali_path }
import cotowali.source { Source, SourceScheme, get_cotowali_source_path, source_scheme_from_str }
import cotowali.symbols { Scope }
import cotowali.ast
import cotowali.compiler_directives { missing_endif_directive }
import cotowali.util { li_panic }
import cotowali.util.http
import net.urllib { URL }
import os

pub fn (mut p Parser) parse(scope &Scope) &ast.File {
	p.scope = scope
	mut file := &ast.File{
		source: p.source()
	}

	mut ctx := p.ctx
	if !(ctx.builtin_loaded() || ctx.config.no_builtin) {
		ctx.builtin_source = source.read_file(cotowali_builtin_path()) or {
			li_panic(@FN, @FILE, @LINE, err)
		}
		mut builtin_parser := new_parser(ctx.builtin_source, ctx)
		file.stmts << ast.RequireStmt{
			file: builtin_parser.parse(ctx.global_scope)
		}
	}
	if ctx.config.is_test && !ctx.testing_loaded() {
		ctx.testing_source = source.read_file(cotowali_testing_path()) or {
			li_panic(@FN, @FILE, @LINE, err)
		}
		mut testing_parser := new_parser(ctx.testing_source, ctx)
		file.stmts << ast.RequireStmt{
			file: testing_parser.parse(ctx.global_scope)
		}
	}

	p.ctx.sources[p.source().path] = file.source

	p.skip_eol()
	for p.kind(0) != .eof {
		file.stmts << p.parse_stmt()
	}
	if p.if_directive_depth > 0 {
		p.error(missing_endif_directive(), p.pos(0))
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
	s := source.read_file(path) or { li_panic(@FN, @FILE, @LINE, err) }
	return parse(s, ctx)
}

pub fn parse_file_relative(base_source &Source, path string, ctx &Context) ?&ast.File {
	source_path := get_cotowali_source_path(path)
	if source_url := base_source.url() {
		url := source_url.resolve_reference(&URL{ user: 0, path: source_path }) or {
			li_panic(@FN, @FILE, @LINE, 'faild to resolve url')
		}
		return parse_remote_file(url, ctx)
	}

	resolved_path := os.real_path(os.join_path(os.dir(base_source.path), source_path))
	return parse_file(resolved_path, ctx)
}

pub fn parse_file_in_cotowali_path(file string, ctx &Context) ?&ast.File {
	path := find_file_path_in_cotowali_path(get_cotowali_source_path(file)) or { return err }
	return parse_file(path, ctx)
}

pub fn parse_remote_file(url URL, ctx &Context) ?&ast.File {
	mut scheme := source_scheme_from_str(url.scheme) or {
		return error('invalid scheme: ${url.scheme}')
	}

	mut http_url := convert_to_http_url(scheme, url)

	http_url_str := http_url.str()
	path := if scheme in [.http, .https] {
		http_url_str.trim_string_left('${url.scheme}:').trim_string_left('//')
	} else {
		http_url.path
	}

	if path in ctx.sources {
		return none
	}

	res := http.get(http_url_str) or {
		return error('failed to get ${http_url_str} (${err.msg()})')
	}
	if res.status() != .ok {
		return error('faild to get ${http_url_str} (${res.status_code} ${res.status()})')
	}
	source_code := res.text

	return parse(&Source{
		scheme: scheme
		path: path
		code: source_code
	}, ctx)
}

pub fn normalize_url(scheme SourceScheme, url URL) URL {
	if scheme in [SourceScheme.http, .https] {
		return url
	}

	mut new_url := URL{
		...url
	}

	// opaque is 'cotowali/cotowali' for 'github:cotowali/cotowali'
	if url.opaque != '' {
		new_url.opaque = ''
		new_url.path = url.opaque
		if url.path != '' {
			new_url.path += '/${url.path}'
		}
	}
	return new_url
}

pub fn convert_to_http_url(scheme SourceScheme, url URL) URL {
	if scheme in [.http, .https] {
		return url
	}

	mut http_url := normalize_url(scheme, url)

	http_url.scheme = 'https'
	if scheme == .github {
		http_url.host = 'raw.githubusercontent.com'
		http_url.path = http_url.path.replace_once('@', '/')
	}
	return http_url
}
