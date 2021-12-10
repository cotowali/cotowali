// Copyright (c) 2021 zakuro <z@kuro.red>. All rights reserved.
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
module symbols

import cotowali.util { li_panic }

pub struct AliasTypeInfo {
pub:
	name   string
	target Type
}

pub fn (ts TypeSymbol) alias_info() ?AliasTypeInfo {
	return if ts.info is AliasTypeInfo { ts.info } else { none }
}

pub fn (mut s Scope) register_alias_type(info AliasTypeInfo) ?&TypeSymbol {
	return s.register_type(name: info.name, info: info)
}

pub fn (s Scope) lookup_alias_type(info AliasTypeInfo) ?&TypeSymbol {
	return s.lookup_type(info.name)
}

pub fn (s Scope) must_lookup_alias_type(info AliasTypeInfo) &TypeSymbol {
	return s.lookup_alias_type(info) or { li_panic(@FILE, @LINE, err) }
}

pub fn (ts &TypeSymbol) resolved() &TypeSymbol {
	return if alias := ts.alias_info() {
		// call recursive. but it will stop on non-alias type
		ts.scope.must_lookup_type(alias.target).resolved()
	} else {
		ts
	}
}
