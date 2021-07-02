module checker

import cotowali.ast

pub fn (mut c Checker) check_file(mut f ast.File) {
	old_source := c.source
	defer {
		c.source = old_source
	}
	c.source = f.source
	c.stmts(f.stmts)
}
