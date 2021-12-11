// Copyright (c) 2021 zakuro <z@kuro.red>. All rights reserved.
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
module symbols

import cotowali.util { li_panic }

pub struct ReferenceTypeInfo {
pub:
	target Type
}

fn (info ReferenceTypeInfo) typename(s &Scope) string {
	return '&${s.must_lookup_type(info.target).name}'
}

pub fn (mut s Scope) lookup_or_register_reference_type(info ReferenceTypeInfo) &TypeSymbol {
	return s.lookup_or_register_type(name: info.typename(s), info: info)
}

pub fn (s Scope) lookup_reference_type(info ReferenceTypeInfo) ?&TypeSymbol {
	return s.lookup_type(info.typename(s))
}

pub fn (s Scope) must_lookup_reference_type(info ReferenceTypeInfo) &TypeSymbol {
	return s.lookup_reference_type(info) or { li_panic(@FILE, @LINE, err) }
}
