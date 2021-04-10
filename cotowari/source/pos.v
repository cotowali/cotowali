module source

import cotowari.util { max }

pub struct Pos {
pub:
	i    int
	line int = 1
	col  int = 1
pub mut:
	len       int = 1
	last_line int = 1
	last_col  int = 1
}

[inline]
pub fn pos(pos Pos) Pos {
	last_line := max(pos.line, pos.last_line)
	last_col := if pos.line == last_line { pos.col + pos.len - 1 } else { pos.last_col }
	return Pos{
		...pos
		last_line: last_line
		last_col: last_col
	}
}

const (
	none_pos = Pos{-1, -1, -1, -1, -1, -1}
)

[inline]
pub fn (p Pos) is_none() bool {
	return p.i < 0
}

pub fn (p1 Pos) merge(p2 Pos) Pos {
	if p1.i > p2.i {
		return p2.merge(p1)
	}
	return Pos{
		...p1
		len: p2.i - p1.i + p2.len
		last_line: p2.last_line
		last_col: p2.last_col
	}
}

pub fn (p Pos) str() string {
	if p.is_none() {
		return 'none'
	}
	return 'Pos{ i: $p.i-${p.i + p.len}, line: $p.line-$p.last_line, col: $p.col-$p.last_col }'
}
