module checker

import cotowari.ast

pub struct Checker {
mut:
	cur_file &ast.File = 0
}

pub fn new_checker() Checker {
	return Checker{}
}
