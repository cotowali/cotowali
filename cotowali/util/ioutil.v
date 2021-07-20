// Copyright (c) 2021 zakuro <z@kuro.red>. All rights reserved.
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
module util

import io

type WritableData = []byte | string

pub fn write(w io.Writer, data WritableData) ?int {
	return w.write(match data {
		string { data.bytes() }
		[]byte { data }
	})
}

pub fn must_write(w io.Writer, data WritableData) int {
	return write(w, data) or { panic(err) }
}
