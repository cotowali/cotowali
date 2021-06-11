module ast

import cotowari.context { Context }

pub struct Resolver {
	ctx &Context
}

pub fn new_resolver(ctx &Context) Resolver {
	return Resolver{ctx}
}

pub fn resolve(ctx &Context, node Node) {
	mut r := new_resolver(ctx)
	r.resolve(node)
}

pub fn (mut r Resolver) resolve(node Node) {
	match node {
		File { r.file(node) }
		Stmt { r.stmt(node) }
		Expr { r.expr(node) }
	}
}
