// Copyright (c) 2021 zakuro <z@kuro.red>. All rights reserved.
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
module symbols

import cotowali.messages { unreachable }

pub struct SequenceTypeInfo {
pub:
	elem Type
}

fn (info SequenceTypeInfo) typename(s &Scope) string {
	elem_ts := s.must_lookup_type(info.elem)
	return '...$elem_ts.name'
}

pub fn (ts &TypeSymbol) sequence_info() ?SequenceTypeInfo {
	resolved := ts.resolved()
	return if resolved.info is SequenceTypeInfo { resolved.info } else { none }
}

pub fn (mut s Scope) lookup_or_register_sequence_type(info SequenceTypeInfo) &TypeSymbol {
	return s.lookup_or_register_type(name: info.typename(s), info: info)
}

pub fn (s Scope) lookup_sequence_type(info SequenceTypeInfo) ?&TypeSymbol {
	return s.lookup_type(info.typename(s))
}

pub fn (s Scope) must_lookup_sequence_type(info SequenceTypeInfo) &TypeSymbol {
	return s.lookup_sequence_type(info) or { panic(unreachable(err)) }
}
