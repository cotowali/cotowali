// Copyright (c) 2021 The Cotowali Authors. All rights reserved.
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
module util

import strings

struct Buf {
pub mut:
	data []byte
}

fn (mut b Buf) write(data []byte) ?int {
	b.data = data
	return data.len
}

fn (b Buf) bytes() []byte {
	return b.data
}

fn test_write() ? {
	buf := Buf{}
	write(buf, [byte(0)]) ?
	assert buf.data == [byte(0)]
	must_write(buf, 'abc')
	assert buf.data == [byte(`a`), `b`, `c`]
}
