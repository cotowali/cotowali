// Copyright (c) 2021 zakuro <z@kuro.red>. All rights reserved.
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
module ast

import cotowali.source { Pos }
import cotowali.context { Context }

pub struct Resolver {
mut:
	ctx &Context
}

pub fn new_resolver(ctx &Context) Resolver {
	return Resolver{
		ctx: ctx
	}
}

pub fn resolve(mut node Node, ctx &Context) {
	mut r := new_resolver(ctx)
	r.resolve(mut node)
}

pub fn (mut r Resolver) resolve(mut node Node) {
	match mut node {
		File { r.file(mut node) }
		Stmt { r.stmt(mut node) }
		Expr { r.expr(mut node) }
		FnParam { r.fn_param(mut node) }
		Ident {}
	}
}

fn (mut r Resolver) error(msg string, pos Pos) IError {
	return r.ctx.errors.push_err(
		msg: msg
		pos: pos
	)
}
