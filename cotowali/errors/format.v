// Copyright (c) 2021 The Cotowali Authors. All rights reserved.
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
module errors

import strings

pub interface Formatter {
	format(Err) string
}

pub struct SimpleFormatter {}

pub fn (p SimpleFormatter) format(err Err) string {
	s := err.source
	pos := err.pos
	return '$s.file_name() $pos.line,$pos.col: $err.msg\n'
}

pub struct PrettyFormatter {}

pub fn (p PrettyFormatter) format(err Err) string {
	s := err.source
	pos := err.pos
	line := s.line(pos.line)
	l1 := '$s.file_name() $pos.line,$pos.col: $err.msg'
	l2 := '${pos.line:5d}| ' + line
	l3 := '     | ' + ' '.repeat(pos.col - 1) + '^'.repeat(pos.last_col - pos.col + 1)
	underline_len := utf8_str_visible_length(s.slice(pos.i, pos.i + pos.len))
	return '$l1\n$l2\n$l3\n'
}

pub fn (errors Errors) format(f Formatter) string {
	mut sb := strings.new_builder(10)

	for e in errors {
		sb.write_string(f.format(e))
	}
	return sb.str()
}
