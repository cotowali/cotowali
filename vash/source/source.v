module source

import os
import encoding.utf8

pub struct Source {
pub:
	path string
	code string
}

// at returns one Letter at code[i]
pub fn (s &Source) at(i int) Letter {
	end := i + utf8.char_len(s.code[i])
	return Letter(s.code[i..end])
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

pub fn must_read_file(path string) Source {
	s := read_file(path) or { panic(err) }
	return s
}
