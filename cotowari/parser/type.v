module parser

import cotowari.symbols { Type }

fn (mut p Parser) parse_type() ?Type {
	tok := p.consume_with_check(.ident) ?
	typ := (p.scope.lookup_type(tok.text) or { return p.error(err, tok.pos) }).typ
	return typ
}
