// Copyright (c) 2021 zakuro <z@kuro.red>. All rights reserved.
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
module symbols

import cotowali.util { li_panic }

pub struct ArrayTypeInfo {
pub:
	elem Type
}

fn (info ArrayTypeInfo) typename(s &Scope) string {
	elem_ts := s.must_lookup_type(info.elem)
	return '[]$elem_ts.name'
}

pub fn (ts &TypeSymbol) array_info() ?ArrayTypeInfo {
	resolved := ts.resolved()
	return if resolved.info is ArrayTypeInfo { resolved.info } else { none }
}

pub fn (mut s Scope) lookup_or_register_array_type(info ArrayTypeInfo) &TypeSymbol {
	return if info.elem == builtin_type(.any) {
		s.lookup_or_register_type(name: info.typename(s), info: info)
	} else {
		// array type inherits []any
		base := s.must_lookup_array_type(elem: builtin_type(.any))
		s.lookup_or_register_type(name: info.typename(s), info: info, base: base)
	}
}

pub fn (s Scope) lookup_array_type(info ArrayTypeInfo) ?&TypeSymbol {
	return s.lookup_type(info.typename(s))
}

pub fn (s Scope) must_lookup_array_type(info ArrayTypeInfo) &TypeSymbol {
	return s.lookup_array_type(info) or { li_panic(@FN, @FILE, @LINE, err) }
}
