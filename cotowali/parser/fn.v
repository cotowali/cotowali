// Copyright (c) 2021 zakuro <z@kuro.red>. All rights reserved.
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
module parser

import cotowali.ast
import cotowali.source { Pos }
import cotowali.token { Token, TokenKind }
import cotowali.symbols {
	Scope,
	TypeSymbol,
	Var,
	builtin_type,
	new_placeholder_var,
}
import cotowali.util { li_panic, nil_to_none, struct_name }

struct FnParamParsingInfo {
mut:
	name     string
	name_pos Pos
	pos      Pos
	default  ast.Expr = ast.Empty{}
	ts       &TypeSymbol
}

fn (p &FnParamParsingInfo) has_default() bool {
	return p.default !is ast.Empty
}

fn (mut p Parser) register_function_param(param FnParamParsingInfo) ?ast.Var {
	param_sym := p.scope.register_var(name: param.name, pos: param.name_pos, typ: param.ts.typ) or {
		new_placeholder_var(param.name, param.name_pos)
		return p.error(err.msg, param.name_pos)
	}
	return ast.Var{
		ident: ast.Ident{
			scope: p.scope
			pos: param.name_pos
			text: param.name
		}
		sym: param_sym
	}
}

enum FnSignatureKind {
	default
	method
	infix_op
	prefix_op
	cast_op
}

struct FnSignatureParsingInfo {
mut:
	kind          FnSignatureKind = .default
	name          Token
	pipe_in_param FnParamParsingInfo
	params        []FnParamParsingInfo
	variadic      bool
	ret_ts        &TypeSymbol = unsafe { 0 }
}

fn (info FnSignatureParsingInfo) register_sym(mut scope Scope) ?&Var {
	ret_typ := if isnil(info.ret_ts) { builtin_type(.void) } else { info.ret_ts.typ }
	params := info.params.map(symbols.FunctionParam{
		name: it.name
		typ: it.ts.typ
		has_default: it.has_default()
	})
	return match info.kind {
		.default {
			scope.register_function(
				name: info.name.text
				pos: info.name.pos
				params: params
				variadic: info.variadic
				pipe_in: info.pipe_in_param.ts.typ
				ret: ret_typ
			)?
		}
		.method {
			mut receiver := info.params[0].ts
			receiver.register_method(
				name: info.name.text
				pos: info.name.pos
				params: params[1..]
				variadic: info.variadic
				pipe_in: info.pipe_in_param.ts.typ
				ret: ret_typ
			)?
		}
		.infix_op {
			scope.register_infix_op_function(info.name, // name is op token
				pos: info.name.pos
				params: params
				variadic: info.variadic
				pipe_in: info.pipe_in_param.ts.typ
				ret: ret_typ
			)?
		}
		.prefix_op {
			scope.register_prefix_op_function(info.name, // name is op token
				pos: info.name.pos
				params: params
				variadic: info.variadic
				pipe_in: info.pipe_in_param.ts.typ
				ret: ret_typ
			)?
		}
		.cast_op {
			scope.register_cast_function(
				pos: info.name.pos
				params: params
				variadic: info.variadic
				pipe_in: info.pipe_in_param.ts.typ
				ret: ret_typ
			)?
		}
	}
}

fn (mut p Parser) parse_fn_params(mut info FnSignatureParsingInfo) ? {
	p.consume_with_check(.l_paren)?
	if _ := p.consume_if_kind_eq(.r_paren) {
		return
	}

	for {
		name_tok := p.consume_with_check(.ident)?
		name_pos := name_tok.pos
		p.consume_with_check(.colon)?
		ts := p.parse_type()?
		pos := name_pos.merge(p.pos(-1))

		mut param := FnParamParsingInfo{
			name: name_tok.text
			name_pos: name_pos
			ts: ts
			pos: pos
		}

		if _ := p.consume_if_kind_eq(.assign) {
			param.default = p.parse_expr(.toplevel)?
		} else {
		}

		info.params << param

		if sequence_info := ts.sequence_info() {
			p.consume_with_check(.r_paren)?
			// varargs is normal (non variadic) array
			info.params[info.params.len - 1].ts = p.scope.lookup_or_register_array_type(
				elem: sequence_info.elem
			)
			info.variadic = true
			break
		}
		tail_tok := p.consume_with_check(.comma, .r_paren)?
		match tail_tok.kind {
			.comma {}
			.r_paren { break }
			else { li_panic(@FN, @FILE, @LINE, '') }
		}
	}
}

fn (mut p Parser) next_is_receiver_syntax() bool {
	// fn ( x : Type ) (int, int) |> f()
	//    | | +- kind(2) == .colon
	//    | +--- kind(1) == .ident
	//    +-|--- kind(0) == .l_paren
	//    | | +  kind(2) == .ident
	// fn ( x Type ) f() // frequently encountered invalid syntax.
	return p.kind(0) == .l_paren && p.kind(1) == .ident && p.kind(2) in [.colon, .ident]
}

fn (mut p Parser) parse_receiver() ?FnParamParsingInfo {
	p.consume_with_assert(.l_paren)
	{
		name_tok := p.consume_with_assert(.ident)
		name := name_tok.text
		name_pos := name_tok.pos

		p.consume_with_check(.colon)?
		ts := (p.parse_type()?)
		pos := name_pos.merge(p.pos(-1))

		p.consume_with_check(.r_paren)?
		return FnParamParsingInfo{
			name: name
			name_pos: name_pos
			ts: ts
			pos: pos
		}
	}
}

fn (mut p Parser) parse_signature_info() ?FnSignatureParsingInfo {
	p.consume_with_assert(.key_fn)
	mut info := FnSignatureParsingInfo{
		ret_ts: 0
	}
	info.pipe_in_param.ts = p.scope.must_lookup_type(builtin_type(.void))

	is_name_kind := fn (kind TokenKind) bool {
		return kind in [.ident, .key_as] || kind.@is(.op)
	}

	// fn ( x : Type ) (int, int) |> f()
	mut has_receiver := false
	if p.next_is_receiver_syntax() {
		rec := p.parse_receiver()?
		//     vvvvvvvvvvv parsed receiver
		// fn ( x : Type ) |> f()
		//                 ^^ kind == .pipe
		if _ := p.consume_if_kind_eq(.pipe) {
			info.pipe_in_param = rec
		} else {
			info.params << rec
			has_receiver = true
		}
	}

	if p.next_is_receiver_syntax() {
		pipe_in := p.parse_receiver()?
		//                vvvvvvvvvv
		// fn (rec: Type) (in: Type) |> f()
		if _ := p.consume_with_check(.pipe) {
			info.pipe_in_param = pipe_in
		}
	} else if !(is_name_kind(p.kind(0)) && p.kind(1) == .l_paren) {
		//    v kind(0) == .ident
		// fn f ( )
		//      ^ kind(1) == .l_paren
		//
		//    vvv kind(0) == .ident
		// fn int |> f()
		//        ^^ kind(1) != .l_paren
		//
		// fn + (v: int)
		//    ^ kind(0).@is(.op)
		//
		// fn (lhs: int) + (rhs: int)
		//               ^ kind(0).@is(.op)
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
		info.pipe_in_param.ts = (p.parse_type()?)
		p.consume_with_check(.pipe)?
	}

	if name := p.consume_if_kind_eq(.key_as) {
		info.name = name
		info.kind = .cast_op
	} else if name := p.consume_if_kind_is(.op) {
		info.name = name
		if has_receiver {
			info.kind = .infix_op
		} else {
			info.kind = .prefix_op
		}
	} else {
		info.name = p.consume_with_check(.ident)?
		if has_receiver {
			info.kind = .method
		}
	}

	p.parse_fn_params(mut info)?
	if p.kind(0) in [.l_brace, .eol] {
		// implicit void
		return info
	}

	//        vv
	// fn f() |> int
	// fn f(): int
	//       ^
	p.consume_with_check(.colon, .pipe)?
	info.ret_ts = p.parse_type()?

	return info
}

fn (mut p Parser) parse_fn_decl() ?ast.FnDecl {
	$if trace_parser ? {
		p.trace_begin(@FN)
		defer {
			p.trace_end()
		}
	}

	mut has_error := false
	info := p.parse_signature_info()?
	mut outer_scope := p.scope

	mut sym_name := if info.name.kind == .ident {
		info.name.text
	} else if info.kind == .cast_op {
		param_name := if info.params.len == 1 {
			info.params[0].ts.name
		} else {
			util.rand<u64>().str()
		}
		ret_name := if ret := nil_to_none(info.ret_ts) { ret.name } else { util.rand<u64>().str() }
		'as_${param_name}_$ret_name'
	} else {
		op_ident := info.name.kind.str_for_ident()
		type_names := info.params.map(it.ts.name).join('_')
		op_ident + type_names
	}
	sym := info.register_sym(mut outer_scope) or {
		has_error = true
		p.error(err.msg, info.name.pos)
		// use different name for duplicated function to create another scope
		sym_name += util.rand<u64>().str()
		new_placeholder_var(sym_name, info.name.pos)
	}

	p.open_scope(if sym.is_method() {
		'${sym.receiver_type_symbol().name}.$sym_name'
	} else {
		sym_name
	})
	defer {
		p.close_scope()
	}

	p.scope.owner = sym

	mut params := []ast.FnParam{len: info.params.len}
	for i, param in info.params {
		if registered := p.register_function_param(param) {
			params[i] = ast.FnParam{
				var_: registered
				default: param.default
				pos: param.pos
			}
		} else {
			has_error = true
			continue
		}
	}

	has_body := p.kind(0) == .l_brace
	mut node := ast.FnDecl{
		parent_scope: outer_scope
		sym: sym
		params: params
		has_body: has_body
		is_method: info.kind == .method
	}
	if info.pipe_in_param.name != '' {
		if registered := p.register_function_param(info.pipe_in_param) {
			node.pipe_in_param = registered
		} else {
			has_error = true
		}
	}

	if has_body {
		if body := p.parse_block_without_new_scope() {
			node.body = body
		} else {
			has_error = true
		}
	}
	if has_error {
		return none
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
		args << p.parse_expr(.toplevel)?
		p.skip_eol()

		if p.kind(0) == .r_paren {
			break
		}

		p.consume_with_check(.comma)?
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

	mut args := p.parse_call_args()?
	r_paren := p.consume_with_check(.r_paren)?
	return ast.CallExpr{
		scope: p.scope
		pos: left.pos().merge(r_paren.pos)
		func: left
		args: args
	}
}

fn (mut p Parser) parse_nameof_or_typeof() ?ast.Expr {
	$if trace_parser ? {
		p.trace_begin()
		defer {
			p.trace_end()
		}
	}

	key := p.consume_with_assert(.key_nameof, .key_typeof)
	p.consume_with_assert(.l_paren)
	args := p.parse_call_args()?
	r_paren := p.consume_with_check(.r_paren)?

	match key.kind {
		.key_nameof {
			return ast.Nameof{
				scope: p.scope
				args: args
				pos: key.pos.merge(r_paren.pos)
			}
		}
		.key_typeof {
			return ast.Typeof{
				scope: p.scope
				args: args
				pos: key.pos.merge(r_paren.pos)
			}
		}
		else {
			li_panic(@FN, @FILE, @LINE, 'invalid key')
		}
	}
}
