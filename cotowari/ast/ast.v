module ast

import cotowari.errors
import cotowari.source { Source }

[heap]
pub struct File {
pub:
	source &Source
pub mut:
	stmts []Stmt
}

pub type Node = Expr | File | Stmt
