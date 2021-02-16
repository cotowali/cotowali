module source

import os

struct Source {
pub:
	path string
	code ustring
}

fn (s &Source) at(i int) string {
	return s.code.at(i)
}

fn read_file(path string) ?Source {
	code_str := os.read_file(path) ?
	return Source{
		path: path
		code: code_str.ustring()
	}
}

fn must_read_file(path string) Source {
	s := read_file(path) or { panic(err) }
	return s
}
