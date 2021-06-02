module parser

import cotowari.ast
import cotowari.source { Pos }
import cotowari.token { Token }
import cotowari.symbols { Type, builtin_type }
import cotowari.errors { unreachable }

struct FnParamParsingInfo {
mut:
	name string
	typ  Type
	pos  Pos
}

struct FnSignatureParsingInfo {
	name Token
mut:
	is_varargs       bool
	varargs_elem_typ Type
	params           []FnParamParsingInfo
	ret_typ          Type = builtin_type(.void)
}

fn (mut p Parser) parse_fn_params(mut info FnSignatureParsingInfo) ? {
	p.consume_with_check(.l_paren) ?
	if _ := p.consume_if_kind_eq(.r_paren) {
		return
	}

	for {
		name_tok := p.consume_with_check(.ident) ?
		is_varargs := if _ := p.consume_if_kind_eq(.dotdotdot) { true } else { false }

		mut typ := p.parse_type() ?
		if is_varargs {
			info.is_varargs = true
			info.varargs_elem_typ = typ
			typ = p.scope.lookup_or_register_array_type(elem: typ).typ
		}

		info.params << FnParamParsingInfo{
			name: name_tok.text
			pos: name_tok.pos
			typ: typ
		}

		if is_varargs {
			p.consume_with_check(.r_paren) ?
			break
		}
		tail_tok := p.consume_with_check(.comma, .r_paren) ?
		match tail_tok.kind {
			.comma {}
			.r_paren { break }
			else { panic(unreachable) }
		}
	}
}

fn (mut p Parser) parse_fn_signature_info() ?FnSignatureParsingInfo {
	p.consume_with_assert(.key_fn)
	mut info := FnSignatureParsingInfo{
		name: p.consume_with_check(.ident) ?
	}

	p.parse_fn_params(mut info) ?
	if p.kind(0) != .l_brace {
		info.ret_typ = p.parse_type() ?
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
	p.open_scope(info.name.text)
	defer {
		p.close_scope()
	}
	mut params := []ast.Var{len: info.params.len}
	for i, param in info.params {
		params[i] = ast.Var{
			scope: p.scope
			pos: param.pos
			sym: p.scope.register_var(name: param.name, pos: param.pos, typ: param.typ) or {
				return p.duplicated_error(param.name, param.pos)
			}
		}
	}

	typ := outer_scope.lookup_or_register_fn_type(
		params: params.map(it.sym.typ)
		ret: info.ret_typ
		is_varargs: info.is_varargs
		varargs_elem: info.varargs_elem_typ
	).typ
	outer_scope.register_var(
		name: info.name.text
		pos: info.name.pos
		typ: typ
	) or { return p.duplicated_error(info.name.text, info.name.pos) }

	has_body := p.kind(0) == .l_brace
	mut node := ast.FnDecl{
		parent_scope: outer_scope
		name: info.name.text
		params: params
		has_body: has_body
		typ: typ
	}
	if has_body {
		node.body = p.parse_block_without_new_scope() ?
	}
	return node
}
