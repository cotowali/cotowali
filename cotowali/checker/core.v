// Copyright (c) 2021 zakuro <z@kuro.red>. All rights reserved.
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
module checker

import cotowali.ast
import cotowali.errors
import cotowali.source { Pos }
import cotowali.context { Context }

pub struct Checker {
mut:
	current_fn  &ast.FnDecl = unsafe { 0 }
	inside_loop bool
	ctx         &Context
}

pub fn new_checker(ctx &Context) Checker {
	return Checker{
		ctx: ctx
	}
}

fn (mut c Checker) error(msg string, pos Pos) IError {
	$if trace_checker ? {
		c.trace_begin(@FN, msg, '${pos}')
		defer {
			c.trace_end()
		}
	}

	return c.ctx.errors.push_err(
		msg: msg
		pos: pos
	)
}

fn (mut c Checker) warn(msg string, pos Pos) IError {
	return c.ctx.errors.push_warn(
		msg: msg
		pos: pos
	)
}
