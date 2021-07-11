// Copyright (c) 2021 The Cotowali Authors. All rights reserved.
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
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

fn (mut c Checker) error(msg string, pos Pos) ? {
	return IError(c.ctx.errors.push(
		source: c.source
		msg: msg
		pos: pos
	))
}
