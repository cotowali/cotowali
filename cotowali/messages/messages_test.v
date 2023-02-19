// Copyright (c) 2021-2023 zakuro <z@kuro.red>
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
module messages

fn test_invalid_key() {
	base_msg := 'invalid key `k`'
	assert invalid_key('k') == base_msg
	assert invalid_key('k', expects: ['a']) == '${base_msg}, expecting `a`'
	assert invalid_key('k', expects: ['a', 'b']) == '${base_msg}, expecting `a` or `b`'
	assert invalid_key('k', expects: ['a', 'b', 'c']) == '${base_msg}, expecting `a`, `b`, or `c`'
}
