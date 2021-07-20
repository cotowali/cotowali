// Copyright (c) 2021 zakuro <z@kuro.red>. All rights reserved.
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
module errors

import strings
import cotowali.source { Source }

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

	format_line := fn (s &Source, line int) string {
		return '${line:5d} | ' + s.line(line)
	}

	lines := [
		'$s.file_name() $pos.line,$pos.col: $err.msg',
		format_line(s, pos.line),
		'      | ' + ' '.repeat(pos.col - 1) + '^'.repeat(pos.last_col - pos.col + 1),
	]
	return lines.map('$it\n').join('')
}

pub fn (errors Errors) format(f Formatter) string {
	mut sb := strings.new_builder(10)

	for e in errors {
		sb.write_string(f.format(e))
	}
	return sb.str()
}
