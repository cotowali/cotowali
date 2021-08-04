// Copyright (c) 2021 zakuro <z@kuro.red>. All rights reserved.
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
module errors

import cotowali.source { new_source, pos }

fn test_errors() {
	mut e := ErrorManager{}
	source_a := new_source('a.txt', 'code')
	source_b := new_source('b.txt', 'code')
	e.push_err(source: source_b, pos: pos(i: 1), msg: 'b1')
	e.push_warn(source: source_b, pos: pos(i: 2), msg: 'b2_w')
	e.push_err(source: source_b, pos: pos(i: 0), msg: 'b0')
	e.push_warn(source: source_a, pos: pos(i: 0), msg: 'a0_w')
	e.push_warn(source: source_a, pos: pos(i: 1), msg: 'a1_w')
	e.push_err(source: source_a, pos: pos(i: 2), msg: 'a2')

	expected := ['a0_w', 'a1_w', 'a2', 'b0', 'b1', 'b2_w']

	assert e.all().map(it.msg) == expected
}
