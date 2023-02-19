// Copyright (c) 2021-2023 zakuro <z@kuro.red>. All rights reserved.
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
module util

import strings

struct Buf {
pub mut:
	data []u8
}

fn (mut b Buf) write(data []u8) ?int {
	b.data = data
	return data.len
}

fn (b Buf) bytes() []u8 {
	return b.data
}

fn test_write() ? {
	mut buf := Buf{}
	write(mut buf, [u8(0)])?
	assert buf.data == [u8(0)]
	must_write(mut buf, 'abc')
	assert buf.data == [u8(`a`), `b`, `c`]
}
