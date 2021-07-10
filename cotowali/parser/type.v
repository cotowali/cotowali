module parser

import cotowali.symbols { Type, TypeSymbol }

fn (mut p Parser) parse_array_type() ?&TypeSymbol {
	$if trace_parser ? {
		p.trace_begin(@FN)
		defer {
			p.trace_end()
		}
	}

	p.consume_with_assert(.l_bracket)
	p.consume_with_check(.r_bracket) ?
	elem := p.parse_type() ?
	return p.scope.lookup_or_register_array_type(elem: elem.typ)
}

fn (mut p Parser) parse_ident_type() ?&TypeSymbol {
	$if trace_parser ? {
		p.trace_begin(@FN)
		defer {
			p.trace_end()
		}
	}

	tok := p.consume_with_check(.ident) ?
	return p.scope.lookup_type(tok.text) or { return p.error(err.msg, tok.pos) }
}

fn (mut p Parser) parse_map_type() ?&TypeSymbol {
	$if trace_parser ? {
		p.trace_begin(@FN)
		defer {
			p.trace_end()
		}
	}
	p.consume_with_assert(.key_map)
	p.consume_with_check(.l_bracket) ?
	key := p.parse_type() ?
	p.consume_with_check(.r_bracket) ?
	value := p.parse_type() ?
	return p.scope.lookup_or_register_map_type(key: key.typ, value: value.typ)
}

fn (mut p Parser) parse_reference_type() ?&TypeSymbol {
	$if trace_parser ? {
		p.trace_begin(@FN)
		defer {
			p.trace_end()
		}
	}

	p.consume_with_assert(.amp)
	target := p.parse_type() ?
	return p.scope.lookup_or_register_reference_type(target: target.typ)
}

fn (mut p Parser) parse_tuple_type() ?&TypeSymbol {
	$if trace_parser ? {
		p.trace_begin(@FN)
		defer {
			p.trace_end()
		}
	}

	p.consume_with_assert(.l_paren)
	if _ := p.consume_if_kind_eq(.r_paren) {
		return p.scope.lookup_or_register_tuple_type(elements: [])
	}

	mut elements := []Type{}
	for {
		elements << (p.parse_type() ?).typ
		if _ := p.consume_if_kind_eq(.r_paren) {
			break
		}
		p.consume_with_check(.comma) ?
	}
	return if elements.len == 1 {
		// treat single value tuple as element type
		p.scope.must_lookup_type(elements[0])
	} else {
		p.scope.lookup_or_register_tuple_type(elements: elements)
	}
}

fn (mut p Parser) parse_variadic_type() ?&TypeSymbol {
	$if trace_parser ? {
		p.trace_begin(@FN)
		defer {
			p.trace_end()
		}
	}

	p.consume_with_assert(.dotdotdot)
	elem := p.parse_type() ?
	return p.scope.lookup_or_register_array_type(elem: elem.typ, variadic: true)
}

fn (mut p Parser) parse_type() ?&TypeSymbol {
	$if trace_parser ? {
		p.trace_begin(@FN)
		defer {
			p.trace_end()
		}
	}

	match p.kind(0) {
		.l_bracket { return p.parse_array_type() }
		.key_map { return p.parse_map_type() }
		.amp { return p.parse_reference_type() }
		.dotdotdot { return p.parse_variadic_type() }
		.l_paren { return p.parse_tuple_type() }
		else { return p.parse_ident_type() }
	}
}
