module parser

import cotowari.ast
import cotowari.source { Pos }
import cotowari.token { Token }
import cotowari.symbols { Type, builtin_type }

struct FnParamParsingInfo {
mut:
	name string
	typ  Type
	pos  Pos
}

struct FnSignatureParsingInfo {
	name Token
mut:
	params  []FnParamParsingInfo
	ret_typ Type = builtin_type(.void)
}

fn (mut p Parser) parse_fn_params() ?[]FnParamParsingInfo {
	mut params := []FnParamParsingInfo{}
	if p.kind(0) == .ident {
		for {
			name_tok := p.consume_with_check(.ident) ?
			typ := p.parse_type() ?
			params << FnParamParsingInfo{
				name: name_tok.text
				pos: name_tok.pos
				typ: typ
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
		name: p.consume_with_check(.ident) ?
	}

	p.consume_with_check(.l_paren) ?
	info.params = p.parse_fn_params() ?
	p.consume_with_check(.r_paren) ?
	if p.kind(0) != .l_brace {
		info.ret_typ = p.parse_type() ?
	}

	return info
}

fn (mut p Parser) parse_fn_decl() ?ast.FnDecl {
	p.trace(@FN)
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
