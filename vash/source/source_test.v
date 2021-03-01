// 🐈 <-- to multibyte character test
module source

import os

fn test_read_file() {
	got := read_file(@FILE) or { panic(err) }
	code := os.read_file(@FILE) or { panic(err) }
	expected := Source{
		path: @FILE
		code: code
	}

	assert got == expected
}

fn test_at() {
	s := read_file(@FILE) or { panic(err) }
	assert s.at(0) == '/'
	assert s.at(3) == '🐈'
	assert s.at(8) == '<'
}

fn test_slice() {
	s := read_file(@FILE) or { panic(err) }
	assert s.slice(1, 9) == '/ 🐈 <'
}
