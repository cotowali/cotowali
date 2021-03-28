module source

import os

pub struct Source {
pub:
	path string
	code string
}

// at returns one Char at code[i]
pub fn (s &Source) at(i int) Char {
	end := i + utf8_char_len(s.code[i])
	return Char(s.code[i..end])
}

pub fn (s &Source) slice(begin int, end int) string {
	return s.code.substr(begin, end)
}

pub fn read_file(path string) ?Source {
	code_text := os.read_file(path) ?
	return Source{
		path: path
		code: code_text
	}
}
