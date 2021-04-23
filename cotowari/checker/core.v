module checker

import cotowari.ast
import cotowari.errors { Err }
import cotowari.source { Pos }

pub struct Checker {
mut:
	cur_file &ast.File = 0
}

pub fn new_checker() Checker {
	return Checker{}
}

fn (mut c Checker) error(msg string, pos Pos) {
	c.cur_file.errors << Err{
		source: c.cur_file.source
		msg: msg
		pos: pos
	}
}
