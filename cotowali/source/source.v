module source

import os

const std_file = $embed_file('../../builtin/std.li')

pub const std = new_source('std.ri', std_file.to_string())

[heap]
pub struct Source {
	lines []string
pub:
	path string
	code string
}

pub fn new_source(path string, code string) &Source {
	return &Source{
		path: path
		code: code
		lines: code.split_into_lines()
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

pub fn (s &Source) line(i int) string {
	return if i < s.lines.len { s.lines[i] } else { '' }
}

pub fn (s &Source) file_name() string {
	return os.file_name(s.path)
}

pub fn read_file(path string) ?&Source {
	code := os.read_file(path) ?
	return new_source(path, code)
}
