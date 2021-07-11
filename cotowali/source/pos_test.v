// Copyright (c) 2021 The Cotowali Authors. All rights reserved.
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
module source

fn test_pos() {
	p := Pos{
		i: 5
		len: 2
		line: 2
		last_line: 2
		col: 2
		last_col: 3
	}
	assert pos(p) == p

	// auto set last_line and last_col
	assert pos(line: 2, col: 2, i: 5, len: 2) == p

	// auto set len to 1
	assert pos(Pos{}).len == 1

	// if multiline, don,t owerride last_col
	assert pos(i: 0, len: 3, line: 1, last_line: 2, col: 1, last_col: 1).last_col == 1
}

fn test_pos_extend() {
	p1 := pos(line: 1, col: 5, i: 4, len: 2)
	p2 := pos(line: 5, col: 1, i: 20, len: 3)
	result := pos(i: 4, len: 19, line: 1, last_line: 5, col: 5, last_col: 3)
	assert p1.merge(p2) == result
	assert p2.merge(p1) == result
}

fn test_pos_none() {
	assert !(pos({}).is_none())
	assert none_pos().is_none()
}
