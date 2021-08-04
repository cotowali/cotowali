// Copyright (c) 2021 zakuro <z@kuro.red>. All rights reserved.
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
module checker

import cotowali.ast
import cotowali.errors
import cotowali.source { Pos, Source }
import cotowali.context { Context }
import cotowali.debug { Tracer }

pub struct Checker {
mut:
	source     &Source = 0
	current_fn ast.FnDecl
	ctx        &Context

	tracer Tracer [if trace_checker ?]
}

pub fn new_checker(ctx &Context) Checker {
	return Checker{
		ctx: ctx
	}
}

[inline; if trace_checker ?]
fn (mut p Checker) trace_begin(f string, args ...string) {
	p.tracer.begin_fn(f, ...args)
}

[inline; if trace_checker ?]
fn (mut p Checker) trace_end() {
	p.tracer.end_fn()
}

fn (mut c Checker) error(msg string, pos Pos) ? {
	$if trace_checker ? {
		c.trace_begin(@FN, msg, '$pos')
		defer {
			c.trace_end()
		}
	}

	return IError(c.ctx.errors.push_err(
		source: c.source
		msg: msg
		pos: pos
	))
}
