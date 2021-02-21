module pos

pub struct Pos {
pub:
	offset    int
	len       int = 1
	line      int = 1
	col       int = 1
	last_line int = 1
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
