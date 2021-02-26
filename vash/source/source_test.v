// 🐈 <-- to multibyte character test
module source

import osutil

fn test_read_file() {
	got := must_read_file(@FILE)

	expected := Source{
		path: @FILE
		code: osutil.must_read_file(@FILE)
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
