module ast

import cotowari.context { Context }

struct Resolver {
	ctx &Context
}

pub fn resolve(ctx &Context, node Node) {
	mut r := Resolver{ctx}
	r.resolve(node)
}

fn (mut r Resolver) resolve(node Node) {
	match node {
		File { r.file(node) }
		Stmt { r.stmt(node) }
		Expr { r.expr(node) }
	}
}
