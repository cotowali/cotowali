// Copyright (c) 2021 zakuro <z@kuro.red>. All rights reserved.
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
module source

import os
import net.urllib { URL }
import cotowali.util.checksum
import cotowali.util { li_panic }

pub type Line = string

pub fn (line Line) col(col int) Char {
	// col is 1-based

	if col < 1 {
		return ''
	}

	mut line_i := 0
	for i := 0; i < col - 1; i++ {
		line_i += utf8_char_len(line[line_i])
		if line_i >= line.len {
			return ''
		}
	}

	return line.substr(line_i, line_i + utf8_char_len(line[line_i]))
}

pub enum SourceScheme {
	local
	http
	https
	github
}

pub fn source_scheme_from_str(s string) ?SourceScheme {
	match s {
		'local' { return .local }
		'http' { return .http }
		'https' { return .https }
		'github' { return .github }
		else { return none }
	}
}

[heap]
pub struct Source {
mut:
	line_head_indices []int
pub:
	scheme SourceScheme = .local
	path   string
	code   string
}

pub fn new_source(path string, code string) &Source {
	return &Source{
		path: path
		code: code
	}
}

pub fn (s &Source) checksum(algo checksum.Algorithm) string {
	return checksum.hexhash(algo, s.code)
}

pub fn (s &Source) url() ?URL {
	match s.scheme {
		.http {
			return urllib.parse('http://$s.path') or { li_panic(@FN, @FILE, @LINE, err.msg) }
		}
		.https {
			return urllib.parse('https://$s.path') or { li_panic(@FN, @FILE, @LINE, err.msg) }
		}
		.github {
			return URL{
				scheme: 'github'
				path: s.path
				user: 0
			}
		}
		.local {
			return none
		}
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

fn (mut s Source) set_line_head_indices() {
	s.line_head_indices = [-1, 0] // line 0 is unused. line 1 is first line
	for i := 0; i < s.code.len; i++ {
		if s.at(i) == '\r' && s.at(i + 1) == '\n' {
			i++
		}
		if s.at(i) == '\n' {
			s.line_head_indices << i + 1
		}
	}
}

pub fn (s &Source) line(i int) Line {
	if s.line_head_indices.len == 0 {
		unsafe { s.set_line_head_indices() }
	}

	return if i + 1 < s.line_head_indices.len {
		s.slice(s.line_head_indices[i], s.line_head_indices[i + 1])
	} else if i == s.line_head_indices.len - 1 {
		s.slice(s.line_head_indices[i], s.code.len)
	} else {
		''
	}.trim_right('\n\r')
}

pub fn (s &Source) file_name() string {
	return os.file_name(s.path)
}

pub fn read_file(path string) ?&Source {
	code := os.read_file(path) ?
	return new_source(path, code)
}

pub fn get_cotowali_source_path(path string) string {
	return if path.ends_with('.li') { path } else { path + '.li' }
}
