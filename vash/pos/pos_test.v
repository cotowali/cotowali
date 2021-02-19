module pos

fn test_new() {
	pos := Pos{
		line: 2
		col: 2
		offset: 5
		len: 2
		last_line: 2
	}
	assert new(pos) == pos

	// auto set last_line to line
	assert new(line: 2, col: 2, offset: 5, len: 2) == pos

	// auto set len to 1
	assert new(Pos{}).len == 1
}

fn test_pos_extend() {
	p1 := new(line: 1, col: 5, offset: 4, len: 2)
	p2 := new(line: 5, col: 0, offset: 20, len: 3)
	result := new(line: 1, col: 5, offset: 4, len: 19, last_line: 5)
	assert p1.merge(p2) == result
	assert p2.merge(p1) == result
}
