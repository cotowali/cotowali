module errors

import os

pub interface Formatter {
	format(Err) string
}

pub struct SimpleFormatter {}

pub fn (p SimpleFormatter) format(err Err) string {
	s := err.source
	file := os.file_name(s.path)
	pos := err.pos
	return '$file $pos.line,$pos.col: $err.msg\n'
}
