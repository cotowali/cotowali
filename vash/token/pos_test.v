module token

fn test_new_pos() {
	pos := Pos{
		line: 2
		col: 2
		offset: 5
		len: 2
		last_line: 2
	}
	assert new_pos(pos) == pos

	// auto set last_line to line
	assert new_pos(line: 2, col: 2, offset: 5, len: 2) == pos

	// auto set len to 1
	assert new_pos(Pos{}).len == 1
}
