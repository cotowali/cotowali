// Copyright (c) 2021 zakuro <z@kuro.red>. All rights reserved.
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
module source

import cotowali.util { max, nil_to_none }

pub struct Pos {
	source &Source = unsafe { 0 }
pub:
	i    int = -1
	line int = 1
	col  int = 1
pub mut:
	len       int = 1
	last_line int = 1
	last_col  int = 1
}

pub fn (pos &Pos) source() ?&Source {
	return nil_to_none(pos.source)
}

[inline]
pub fn (pos &Pos) begin() int {
	return pos.i
}

[inline]
pub fn (pos &Pos) end() int {
	return pos.i + pos.len
}

pub fn (s &Source) new_pos(p Pos) Pos {
	return pos(Pos{ ...p, source: s })
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

[inline]
pub fn none_pos() Pos {
	return Pos{
		i: -1
		len: -1
	}
}

[inline]
pub fn (p Pos) is_none() bool {
	return p.i < 0 && p.len < 0
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

pub fn (p_orig Pos) includes(p2_orig Pos) bool {
	p, p2 := pos(p_orig), pos(p2_orig)
	source_eq := if isnil(p.source) || isnil(p2.source) {
		isnil(p.source) && isnil(p2.source)
	} else {
		p.source == p2.source
	}
	idx_ok := (p.i >= 0 && p2.i >= 0) && (p.begin() <= p2.begin() && p.end() >= p2.end())
	first_line_ok := p.line < p2.line || (p.line == p2.line && p.col <= p2.col)
	last_line_ok := p.last_line > p2.last_line
		|| (p.last_line == p2.last_line && p.last_col >= p2.last_col)
	return source_eq && (idx_ok || (first_line_ok && last_line_ok))
}

pub fn (p Pos) str() string {
	if p.is_none() {
		return 'none'
	}
	return 'Pos{ i: ${p.i}-${p.i + p.len}, line: ${p.line}-${p.last_line}, col: ${p.col}-${p.last_col} }'
}
