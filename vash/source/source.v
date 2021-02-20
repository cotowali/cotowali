module source

import os
import utils { check_bounds_if_required }

pub struct Source {
pub:
	path string
	code []Letter
}

[inline]
pub fn code<T>(text T) []Letter {
	$if T is []Letter {
		return text
	}
	mut ustr := ustring{}
	$if T is ustring {
		ustr = text
	} $else {
		ustr = text.ustring()
	}
	mut code := []Letter{len: ustr.len}
	for i, _ in code {
		code[i] = ustr.at(i)
	}
	return code
}

pub fn (s &Source) at(i int) Letter {
	return s.code[i]
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
	code_text := os.read_file(path) ?
	return Source{
		path: path
		code: code(code_text)
	}
}

pub fn must_read_file(path string) Source {
	s := read_file(path) or { panic(err) }
	return s
}
