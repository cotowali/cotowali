module pos

import utils.math { max }

pub struct Pos {
pub:
	offset    int
	len       int = 1
	line      int = 1
	last_line int = 1
	col       int = 1
	last_col  int = 1
}

[inline]
pub fn new(pos Pos) Pos {
	last_line := max(pos.line, pos.last_line)
	last_col := if pos.line == last_line { pos.col + pos.len } else { pos.last_col }
	return Pos{
		...pos,
		last_line: last_line,
		last_col: last_col,
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
		last_col: p2.last_col
	}
}
