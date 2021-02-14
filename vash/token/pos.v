module token

struct Pos {
pub:
	line      int // 1-based
	col       int // 1-based
	offset    int
	len       int
	last_line int
}

pub fn new_pos(pos Pos) Pos {
	return Pos{
		line: pos.line
		col: pos.col
		offset: pos.offset
		len: if pos.len == 0 {
			1
		} else {
			pos.len
		}
		last_line: if pos.last_line == 0 {
			pos.line
		} else {
			pos.last_line
		}
	}
}

pub fn (p1 Pos) merge(p2 Pos) Pos {
	if p1.offset > p2.offset {
		return p2.merge(p1)
	}
	return Pos{
		...p1
		len: p2.offset - p1.offset + p2.len
		last_line: p2.last_line
	}
}
