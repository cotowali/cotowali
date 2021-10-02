// Copyright (c) 2021 zakuro <z@kuro.red>. All rights reserved.
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
module parser

import cotowali.ast
import cotowali.source { Pos }
import cotowali.token { Token }
import cotowali.symbols { Scope, Type, TypeSymbol, Var, builtin_type }
import cotowali.messages { unreachable }
import cotowali.util { struct_name }

struct FnParamParsingInfo {
mut:
	name string
	ts   &TypeSymbol
	pos  Pos
}

struct FnSignatureParsingInfo {
mut:
	is_method bool
	name      Token
	pipe_in   Type = builtin_type(.void)
	params    []FnParamParsingInfo
	ret_typ   Type = builtin_type(.void)
}

fn (info FnSignatureParsingInfo) register_sym(mut scope Scope) ?&Var {
	if info.is_method {
		mut receiver := info.params[0].ts
		return receiver.register_method(
			name: info.name.text
			pos: info.name.pos
			params: info.params[1..].map(it.ts.typ)
			pipe_in: info.pipe_in
			ret: info.ret_typ
		)
	} else {
		return scope.register_fn(
			name: info.name.text
			pos: info.name.pos
			params: info.params.map(it.ts.typ)
			pipe_in: info.pipe_in
			ret: info.ret_typ
		)
	}
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
			ts: ts
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

	if p.kind(0) == .l_paren && p.kind(1) == .ident && p.kind(2) in [.colon, .ident] {
		// fn ( x : Type ) (int, int) |> f()
		//    | | +- kind(2) == .colon
		//    | +--- kind(1) == .ident
		//    +-|--- kind(0) == .l_paren
		//    | | +  kind(2) == .ident
		// fn ( x Type ) f() // frequently encountered invalid syntax.
		info.is_method = true
		p.consume_with_assert(.l_paren)
		rec_name_tok := p.consume_with_assert(.ident)
		p.consume_with_check(.colon) ?
		rec_ts := (p.parse_type() ?)
		info.params << FnParamParsingInfo{
			name: rec_name_tok.text
			pos: rec_name_tok.pos
			ts: rec_ts
		}
		p.consume_with_check(.r_paren) ?
	}

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
		// fn ... int |> f()
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
	if p.kind(0) in [.l_brace, .eol] {
		// implicit void
		return info
	}

	//        vv
	// fn f() |> int
	// fn f(): int
	//       ^
	p.consume_with_check(.colon, .pipe) ?
	info.ret_typ = (p.parse_type() ?).typ

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

	sym := info.register_sym(mut outer_scope) or { return p.error(err.msg, info.name.pos) }

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
			sym: p.scope.register_var(name: param.name, pos: param.pos, typ: param.ts.typ) or {
				return p.error(err.msg, param.pos)
			}
		}
	}

	has_body := p.kind(0) == .l_brace
	mut node := ast.FnDecl{
		parent_scope: outer_scope
		sym: sym
		params: params
		has_body: has_body
		is_method: info.is_method
	}
	if has_body {
		node.body = p.parse_block_without_new_scope() ?
	}
	return node
}

fn (mut p Parser) parse_call_args() ?[]ast.Expr {
	p.skip_eol()
	if p.kind(0) == .r_paren {
		return []
	}

	mut args := []ast.Expr{cap: 2}
	for {
		args << p.parse_expr(.toplevel) ?
		p.skip_eol()

		if p.kind(0) == .r_paren {
			break
		}

		p.consume_with_check(.comma) ?
		p.skip_eol()

		if p.kind(0) == .r_paren {
			// ends with trailing comman
			break
		}
	}
	return args
}

fn (mut p Parser) parse_call_expr_with_left(left ast.Expr) ?ast.Expr {
	$if trace_parser ? {
		p.trace_begin(@FN, '${struct_name(left)}{...}')
		defer {
			p.trace_end()
		}
	}

	p.consume_with_assert(.l_paren)

	mut args := p.parse_call_args() ?
	r_paren := p.consume_with_check(.r_paren) ?
	return ast.CallExpr{
		scope: p.scope
		pos: left.pos().merge(r_paren.pos)
		func: left
		args: args
	}
}
