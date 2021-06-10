module errors

import cotowari.source { new_source, pos }

fn test_errors() {
	mut e := Errors{}
	source_a := new_source('a.txt', 'code')
	source_b := new_source('b.txt', 'code')
	e.push(source: source_b, pos: pos(i: 1), msg: 'b1')
	e.push(source: source_b, pos: pos(i: 0), msg: 'b0')
	e.push(source: source_a, pos: pos(i: 0), msg: 'a0')
	e.push(source: source_a, pos: pos(i: 1), msg: 'a1')

	expected := ['a0', 'a1', 'b0', 'b1']

	for _ in 0 .. 2 {
		mut list := []Err{}
		for err in e {
			list << err
		}
		assert list.map(it.msg) == expected
	}

	assert e.list().map(it.msg) == expected
}
