// Copyright (c) 2021-2023 zakuro <z@kuro.red>. All rights reserved.
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
module sha3

#flag -I @VMODROOT/thirdparty/tiny_sha3
#flag    @VMODROOT/thirdparty/tiny_sha3/sha3.o
#include "sha3.h"

fn C.sha3(in_ voidptr, inlen usize, md voidptr, mdlen int) voidptr

fn sha3(data []u8, mdlen int) []u8 {
	md := []u8{len: mdlen}
	inlen := data.len * data.element_size
	unsafe {
		C.sha3(&u8(data.data) + data.offset, inlen, md.data, mdlen)
	}
	return md
}
