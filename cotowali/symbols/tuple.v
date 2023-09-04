// Copyright (c) 2021-2023 zakuro <z@kuro.red>
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
module symbols

import cotowali.util { li_panic }

pub struct TupleElement {
pub:
	typ Type [required]
}

pub struct TupleTypeInfo {
pub:
	elements []TupleElement
}

pub fn (ts TypeSymbol) tuple_info() ?TupleTypeInfo {
	resolved := ts.resolved()
	return if resolved.info is TupleTypeInfo { resolved.info } else { none }
}

fn (info TupleTypeInfo) typename(s &Scope) string {
	return '(${info.elements.map(s.must_lookup_type(it.typ).name).join(', ')})'
}

pub fn (mut s Scope) lookup_or_register_tuple_type(info TupleTypeInfo) &TypeSymbol {
	return s.lookup_or_register_type(name: info.typename(s), info: info)
}

pub fn (s Scope) lookup_tuple_type(info TupleTypeInfo) !&TypeSymbol {
	return s.lookup_type(info.typename(s))
}

pub fn (s Scope) must_lookup_tuple_type(info TupleTypeInfo) &TypeSymbol {
	return s.lookup_tuple_type(info) or { li_panic(@FN, @FILE, @LINE, err) }
}
