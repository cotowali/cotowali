// Copyright (c) 2021 zakuro <z@kuro.red>. All rights reserved.
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
module source

import os
import net.urllib { URL }
import cotowali.messages { unreachable }
import cotowali.util.checksum

const std_file = $embed_file('../../builtin/std.li')

pub const std = new_source('std.li', std_file.to_string())

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
	lines []string
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
			return urllib.parse('http://$s.path') or { panic(unreachable(err.msg)) }
		}
		.https {
			return urllib.parse('https://$s.path') or { panic(unreachable(err.msg)) }
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

fn (mut s Source) set_lines() {
	s.lines = s.code.split_into_lines()
}

pub fn (s &Source) line(i int) string {
	if s.lines.len == 0 {
		unsafe {
			s.set_lines()
		}
	}
	return if i <= s.lines.len { s.lines[i - 1] } else { '' }
}

pub fn (s &Source) file_name() string {
	return os.file_name(s.path)
}

pub fn read_file(path string) ?&Source {
	code := os.read_file(path) ?
	return new_source(path, code)
}
