module checker

import cotowari.ast

pub fn (mut c Checker) check_file(mut f ast.File) {
	old_f := c.cur_file
	defer {
		c.cur_file = old_f
	}
	c.cur_file = f
	c.stmts(f.stmts)
}
