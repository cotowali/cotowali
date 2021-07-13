// Copyright (c) 2021 The Cotowali Authors. All rights reserved.
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
module source

import os

fn test_read_file() {
	got := read_file(@FILE) or { panic(err) }
	code := os.read_file(@FILE) or { panic(err) }
	expected := Source{
		path: @FILE
		code: code
		lines: code.split_into_lines()
	}

	assert got == expected
}

fn test_at() {
	s := new_source('', '// 🐈 nyan')
	assert s.at(0) == '/'
	assert s.at(3) == '🐈'
	assert s.at(8) == 'n'
}

fn test_slice() {
	s := new_source('', '// 🐈 nyan')
	assert s.slice(1, 9) == '/ 🐈 n'
}

fn test_line() ? {
	s := read_file(@FILE) ?
	assert s.line(2) == '//'
	assert s.line(100000) == ''
}
