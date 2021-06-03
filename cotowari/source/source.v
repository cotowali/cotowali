module source

import os

[heap]
pub struct Source {
pub:
	path string
	code string
}

pub fn new_source(path string, code string) &Source {
	return &Source{
		path: path
		code: code
	}
}

// at returns one Char at code[i]
pub fn (s &Source) at(i int) Char {
	end := i + utf8_char_len(s.code[i])
	return Char(s.code[i..end])
}

pub fn (s &Source) slice(begin int, end int) string {
	return s.code.substr(begin, end)
}

pub fn read_file(path string) ?&Source {
	code := os.read_file(path) ?
	return new_source(path, code)
}
