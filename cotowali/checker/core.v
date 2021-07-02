module checker

import cotowali.ast
import cotowali.errors
import cotowali.source { Pos, Source }
import cotowali.context { Context }

pub struct Checker {
mut:
	source     &Source = 0
	current_fn ast.FnDecl
	ctx        &Context
}

pub fn new_checker(ctx &Context) Checker {
	return Checker{
		ctx: ctx
	}
}

fn (mut c Checker) error(msg string, pos Pos) {
	c.ctx.errors.push(
		source: c.source
		msg: msg
		pos: pos
	)
}
