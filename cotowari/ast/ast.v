module ast

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
	$if trace_resolver ? {
		r.trace_begin(@FN)
		defer {
			r.trace_end()
		}
	}

	r.stmts(f.stmts)
}
