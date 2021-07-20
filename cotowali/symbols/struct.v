// Copyright (c) 2021 zakuro <z@kuro.red>. All rights reserved.
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
module symbols

pub struct StructTypeInfo {
pub:
	fields map[string]Type
}

fn (info StructTypeInfo) type_to_str(s &Scope) string {
	fields_str := info.fields.keys().map('$it ${s.must_lookup_type(info.fields[it]).name}').join(', ')
	return 'struct { $fields_str }'
}

pub fn (ts &TypeSymbol) struct_info() ?StructTypeInfo {
	return if ts.info is StructTypeInfo { ts.info } else { none }
}

pub fn (mut s Scope) register_struct_type(name string, info StructTypeInfo) ?&TypeSymbol {
	return s.register_type(name: name, info: info)
}
