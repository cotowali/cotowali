module source

fn test_new_pos() {
	pos := Pos{
		i: 5
		len: 2
		line: 2
		last_line: 2
		col: 2
		last_col: 3
	}
	assert new_pos(pos) == pos

	// auto set last_line and last_col
	assert new_pos(line: 2, col: 2, i: 5, len: 2) == pos

	// auto set len to 1
	assert new_pos(Pos{}).len == 1

	// if multiline, don,t owerride last_col
	assert new_pos(i: 0, len: 3, line: 1, last_line: 2, col: 1, last_col: 1).last_col == 1
}

fn test_pos_extend() {
	p1 := new_pos(line: 1, col: 5, i: 4, len: 2)
	p2 := new_pos(line: 5, col: 1, i: 20, len: 3)
	result := new_pos(i: 4, len: 19, line: 1, last_line: 5, col: 5, last_col: 3)
	assert p1.merge(p2) == result
	assert p2.merge(p1) == result
}

fn test_pos_none() {
	assert !(new_pos({}).is_none())
	assert none_pos.is_none()
}
