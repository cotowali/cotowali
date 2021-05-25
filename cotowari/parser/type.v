module parser

import cotowari.symbols { Type }

fn (mut p Parser) parse_array_type() ?Type {
	p.trace(@FN)
	p.consume_with_assert(.l_bracket)
	p.consume_with_check(.r_bracket) ?
	elem := p.parse_type() ?
	return p.scope.lookup_or_register_array_type(elem: elem).typ
}

fn (mut p Parser) parse_type() ?Type {
	p.trace(@FN)
	match p.kind(0) {
		.l_bracket {
			return p.parse_array_type()
		}
		else {
			tok := p.consume_with_check(.ident) ?
			return (p.scope.lookup_type(tok.text) or { return p.error(err, tok.pos) }).typ
		}
	}
}
