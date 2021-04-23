module checker

import cotowari.ast

pub fn (mut c Checker) check_file(mut f ast.File) {
	c.cur_file = f
}
