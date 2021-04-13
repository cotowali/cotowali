module util

import strings

struct Buf {
pub mut:
	data []byte
}

fn (mut b Buf) write(data []byte) ?int {
	b.data = data
	return data.len
}

fn (b Buf) bytes() []byte {
	return b.data
}

fn test_write() ? {
	buf := Buf{}
	write(buf, [byte(0)]) ?
	assert buf.data == [byte(0)]
	write(buf, 'abc') ?
	assert buf.data == [byte(`a`), `b`, `c`]
}
