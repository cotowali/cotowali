// Copyright (c) 2021 zakuro <z@kuro.red>. All rights reserved.
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
module ast

import cotowali.source { Pos, Source }
import cotowali.context { Context }
import cotowali.debug { Tracer }

pub struct Resolver {
mut:
	ctx    &Context
	source &Source = 0

	tracer Tracer [if trace_resolver ?]
}

pub fn new_resolver(ctx &Context) Resolver {
	return Resolver{
		ctx: ctx
	}
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

[inline; if trace_resolver ?]
fn (mut r Resolver) trace_begin(f string, args ...string) {
	r.tracer.begin_fn(f, ...args)
}

[inline; if trace_resolver ?]
fn (mut r Resolver) trace_end() {
	r.tracer.end_fn()
}

fn (mut r Resolver) error(msg string, pos Pos) IError {
	$if trace_resolver ? {
		r.trace_begin(@FN, msg, '$pos')
		defer {
			r.trace_end()
		}
	}

	return r.ctx.errors.push_err(
		source: r.source
		msg: msg
		pos: pos
	)
}

fn (mut r Resolver) duplicated_error(name string, pos Pos) IError {
	return r.error('`$name` is duplicated', pos)
}
