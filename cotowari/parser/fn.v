module parser

import cotowari.ast
import cotowari.source { Pos }

struct FnParamParsingInfo {
mut:
	name     string
	typename string
	pos      Pos
}

struct FnSignatureParsingInfo {
	name string
mut:
	params       []FnParamParsingInfo
	ret_typename string
}

fn (mut p Parser) parse_fn_params() ?[]FnParamParsingInfo {
	mut params := []FnParamParsingInfo{}
	if p.kind(0) == .ident {
		for {
			name := p.consume_with_check(.ident) ?
			typ := p.consume_with_check(.ident) ?
			params << FnParamParsingInfo{
				name: name.text
				pos: name.pos
				typename: typ.text
			}
			if p.kind(0) == .r_paren {
				break
			} else {
				p.consume_with_check(.comma) ?
			}
		}
	}
	return params
}

fn (mut p Parser) parse_fn_signature_info() ?FnSignatureParsingInfo {
	p.consume_with_assert(.key_fn)
	mut info := FnSignatureParsingInfo{
		name: p.consume().text
	}

	p.consume_with_check(.l_paren) ?
	info.params = p.parse_fn_params() ?
	p.consume_with_check(.r_paren) ?
	if ret := p.consume_if_kind_eq(.ident) {
		info.ret_typename = ret.text
	}

	return info
}

fn (mut p Parser) parse_fn_decl() ?ast.FnDecl {
	info := p.parse_fn_signature_info() ?
	mut outer_scope := p.scope
	p.open_scope(info.name)
	defer {
		p.close_scope()
	}
	mut params := []ast.Var{len: info.params.len}
	for i, param in info.params {
		params[i] = ast.Var{
			scope: p.scope
			pos: param.pos
			// TODO: type
			sym: p.scope.register_var(name: param.name) or { return p.duplicated_error(param.name) }
		}
	}
	// TODO: type
	outer_scope.register_var(name: info.name) or { return p.duplicated_error(info.name) }

	has_body := p.kind(0) == .l_brace
	mut node := ast.FnDecl{
		name: info.name
		params: params
		has_body: has_body
	}
	if has_body {
		node.body = p.parse_block_without_new_scope() ?
	}
	return node
}
