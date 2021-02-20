module source

import os
import utils { check_bounds_if_required }

pub struct Source {
pub:
	path string
	code ustring
}

pub fn (s &Source) at(i int) Letter {
	return Letter(s.code.at(i))
}

pub fn (s &Source) slice(begin int, end int) []Letter {
	check_bounds_if_required(s.code.len, begin, end)
	len := end - begin
	mut letters := []Letter{len: len}
	for i in 0 .. len {
		letters[i] = s.at(begin + i)
	}
	return letters
}

pub fn read_file(path string) ?Source {
	code_str := os.read_file(path) ?
	return Source{
		path: path
		code: code_str.ustring()
	}
}

pub fn must_read_file(path string) Source {
	s := read_file(path) or { panic(err) }
	return s
}
