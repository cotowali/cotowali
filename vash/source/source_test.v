// 🐈 <-- to multibyte character test
module source

import utils.os

fn test_read_file() {
	got := must_read_file(@FILE)

	expected := Source{
		path: @FILE
		code: os.must_read_file(@FILE).ustring()
	}

	assert got == expected
}

fn test_at() {
	s := must_read_file(@FILE)
	assert s.at(0) == '/'
	assert s.at(3) == '🐈'
}
