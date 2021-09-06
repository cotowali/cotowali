// Copyright (c) 2021 zakuro <z@kuro.red>. All rights reserved.
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
module parser

import cotowali.ast
import cotowali.source { Pos }
import cotowali.token { Token }
import cotowali.symbols { Type, builtin_type }
import cotowali.errors { unreachable }

struct FnParamParsingInfo {
mut:
	name string
	typ  Type
	pos  Pos
}

struct FnSignatureParsingInfo {
mut:
	name    Token
	pipe_in Type = builtin_type(.void)
	params  []FnParamParsingInfo
	ret_typ Type = builtin_type(.void)
}

fn (mut p Parser) parse_fn_params(mut info FnSignatureParsingInfo) ? {
	p.consume_with_check(.l_paren) ?
	if _ := p.consume_if_kind_eq(.r_paren) {
		return
	}

	for {
		name_tok := p.consume_with_check(.ident) ?
		p.consume_with_check(.colon) ?
		ts := p.parse_type() ?

		info.params << FnParamParsingInfo{
			name: name_tok.text
			pos: name_tok.pos
			typ: ts.typ
		}

		if array_info := ts.array_info() {
			if array_info.variadic {
				p.consume_with_check(.r_paren) ?
				break
			}
		}
		tail_tok := p.consume_with_check(.comma, .r_paren) ?
		match tail_tok.kind {
			.comma {}
			.r_paren { break }
			else { panic(unreachable('')) }
		}
	}
}

fn (mut p Parser) parse_fn_signature_info() ?FnSignatureParsingInfo {
	p.consume_with_assert(.key_fn)
	mut info := FnSignatureParsingInfo{}

	if !(p.kind(0) == .ident && p.kind(1) == .l_paren) {
		//    v kind(0) == .ident
		// fn f ( )
		//      ^ kind(1) == .l_paren
		//
		//    vvv kind(0) == .ident
		// fn int |> f()
		//        ^^ kind(1) != .l_paren
		//
		//    v kind(0) != .ident
		// fn [ ] int |> f()
		//      ^ kind(1) != .l_paren
		//
		//    vvv kind(0) != .ident
		// fn ... int _> f()
		//        ^^^ kind(1) != .l_paren
		//
		//    vvv kind(0) != .ident
		// fn ... ( int, int ) |> f()
		//        ^ kind(1) == .l_paren
		info.pipe_in = (p.parse_type() ?).typ
		p.consume_with_check(.pipe) ?
	}

	info.name = p.consume_with_check(.ident) ?

	p.parse_fn_params(mut info) ?
	if p.kind(0) != .l_brace {
		// consume output pipe symbol (optional)
		//        vv
		// fn f() |> int
		//        ^^
		p.consume_if_kind_eq(.pipe) or {}

		info.ret_typ = (p.parse_type() ?).typ
	}

	return info
}

fn (mut p Parser) parse_fn_decl() ?ast.FnDecl {
	$if trace_parser ? {
		p.trace_begin(@FN)
		defer {
			p.trace_end()
		}
	}

	info := p.parse_fn_signature_info() ?
	mut outer_scope := p.scope

	sym := outer_scope.register_fn(
		name: info.name.text
		pos: info.name.pos
		params: info.params.map(it.typ)
		pipe_in: info.pipe_in
		ret: info.ret_typ
	) or { return p.duplicated_error(info.name.text, info.name.pos) }

	p.open_scope(info.name.text)
	defer {
		p.close_scope()
	}
	p.scope.owner = sym

	mut params := []ast.Var{len: info.params.len}
	for i, param in info.params {
		params[i] = ast.Var{
			ident: ast.Ident{
				scope: p.scope
				pos: param.pos
				text: param.name
			}
			sym: p.scope.register_var(name: param.name, pos: param.pos, typ: param.typ) or {
				return p.duplicated_error(param.name, param.pos)
			}
		}
	}

	has_body := p.kind(0) == .l_brace
	mut node := ast.FnDecl{
		parent_scope: outer_scope
		sym: sym
		params: params
		has_body: has_body
	}
	if has_body {
		node.body = p.parse_block_without_new_scope() ?
	}
	return node
}
