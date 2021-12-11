// Copyright (c) 2021 zakuro <z@kuro.red>. All rights reserved.
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
module parser

import cotowali.symbols { TupleElement, TypeSymbol }
import cotowali.ast

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

[inline]
fn tuple_element_error_msg(name string) string {
	return 'cannot use $name as tuple element'
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

	mut elements := []TupleElement{}
	for {
		ts := p.parse_type() ?

		mut element_pushed := false

		// Check element types. If element is invalid, report error but dont stop to parse
		if sequence_info := ts.sequence_info() {
			if elem_tuple := p.scope.must_lookup_type(sequence_info.elem).tuple_info() {
				// expand tuple element like `(...(int, int))`
				elements << elem_tuple.elements.map(it)
				element_pushed = true
			} else {
				p.error(tuple_element_error_msg('sequence type'), ts.pos)
			}
		}
		if _ := ts.tuple_info() {
			p.error(tuple_element_error_msg('tuple'), ts.pos)
		}

		if !element_pushed {
			elements << TupleElement{
				typ: ts.typ
			}
		}

		if _ := p.consume_if_kind_eq(.r_paren) {
			break
		}
		p.consume_with_check(.comma) ?
	}
	return if elements.len == 1 {
		// treat single value tuple as element type
		p.scope.must_lookup_type(elements[0].typ)
	} else {
		p.scope.lookup_or_register_tuple_type(elements: elements)
	}
}

fn (mut p Parser) parse_sequence_type() ?&TypeSymbol {
	$if trace_parser ? {
		p.trace_begin(@FN)
		defer {
			p.trace_end()
		}
	}

	p.consume_with_assert(.dotdotdot)
	elem := p.parse_type() ?
	return p.scope.lookup_or_register_sequence_type(elem: elem.typ)
}

fn (mut p Parser) parse_type() ?&TypeSymbol {
	$if trace_parser ? {
		p.trace_begin(@FN)
		defer {
			p.trace_end()
		}
	}

	start_pos := p.pos(0)

	mut ts := match p.kind(0) {
		.l_bracket { p.parse_array_type() ? }
		.key_map { p.parse_map_type() ? }
		.amp { p.parse_reference_type() ? }
		.dotdotdot { p.parse_sequence_type() ? }
		.l_paren { p.parse_tuple_type() ? }
		else { p.parse_ident_type() ? }
	}
	ts.pos = start_pos.merge(p.pos(-1))
	return ts
}

fn (mut p Parser) parse_type_decl() ?ast.Stmt {
	$if trace_parser ? {
		p.trace_begin(@FN)
		defer {
			p.trace_end()
		}
	}

	mut pos := p.pos(0)

	p.consume_with_assert(.key_type)
	ident := p.consume_with_check(.ident) ?
	p.consume_with_check(.assign) ?
	target := (p.parse_type() ?).typ

	pos = pos.merge(p.pos(-1))

	p.scope.register_alias_type(name: ident.text, target: target) or {
		return p.error(err.msg, pos)
	}

	return ast.Empty{}
}
