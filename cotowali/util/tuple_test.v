module util

fn test_tuple() {
	assert tuple2(0, ['a', 'b', 'c']).str() == "(0, ['a', 'b', 'c'])"
}

fn test_pair() {
	v1, v2 := 0, ['a', 'b', 'c']
	assert pair(v1, v2).tuple() == tuple2(v1, v2)
	assert pair(0, ['a', 'b', 'c']).str() == "(0, ['a', 'b', 'c'])"
}
