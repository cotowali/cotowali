// 🐈 <-- to multibyte character test
module source

import os

fn test_read_file() {
	got := must_read_file(@FILE)
	code := os.read_file(@FILE) or { panic(err) }
	expected := Source{
		path: @FILE
		code: code
	}

	assert got == expected
}

fn test_at() {
	s := must_read_file(@FILE)
	assert s.at(0) == '/'
	assert s.at(3) == '🐈'
	assert s.at(8) == '<'
}

fn test_slice() {
	s := must_read_file(@FILE)
	assert s.slice(1, 9) == '/ 🐈 <'
}
