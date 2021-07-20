// Copyright (c) 2021 zakuro <z@kuro.red>. All rights reserved.
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
module symbols

import cotowali.errors { unreachable }

pub struct ArrayTypeInfo {
pub:
	elem     Type
	variadic bool
}

fn (info ArrayTypeInfo) typename(s &Scope) string {
	elem_ts := s.must_lookup_type(info.elem)
	prefix := if info.variadic { '...' } else { '[]' }
	return '$prefix$elem_ts.name'
}

pub fn (ts &TypeSymbol) array_info() ?ArrayTypeInfo {
	return if ts.info is ArrayTypeInfo { ts.info } else { none }
}

pub fn (mut s Scope) lookup_or_register_array_type(info ArrayTypeInfo) &TypeSymbol {
	return s.lookup_or_register_type(name: info.typename(s), info: info)
}

pub fn (s Scope) lookup_array_type(info ArrayTypeInfo) ?&TypeSymbol {
	return s.lookup_type(info.typename(s))
}

pub fn (s Scope) must_lookup_array_type(info ArrayTypeInfo) &TypeSymbol {
	return s.lookup_array_type(info) or { panic(unreachable(err)) }
}
