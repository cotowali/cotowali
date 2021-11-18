// Copyright (c) 2021 zakuro <z@kuro.red>. All rights reserved.
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
module ast

import cotowali.source { Pos }

pub struct Attr {
pub:
	// #[name]
	pos  Pos
	name string
}

pub enum AttrKind {
	mangle
	test
	unknown
}

const attr_name_kind_table = {
	'unknown': AttrKind.unknown
	'mangle':  .mangle
	'test':    .test
}

pub fn (attr Attr) kind() AttrKind {
	return ast.attr_name_kind_table[attr.name] or { AttrKind.unknown }
}
