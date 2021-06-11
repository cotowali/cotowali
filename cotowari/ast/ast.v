module ast

import cotowari.errors
import cotowari.source { Source }

pub type Node = Expr | File | Stmt

[heap]
pub struct File {
pub:
	source &Source
pub mut:
	stmts []Stmt
}

fn (mut r Resolver) file(f &File) {
}
