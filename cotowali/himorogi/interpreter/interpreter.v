// Copyright (c) 2021 zakuro <z@kuro.red>. All rights reserved.
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
module interpreter

import cotowali.context { Context }
import cotowali.ast { File, FnDecl }

pub struct Interpreter {
mut:
	ctx        &Context
	current_fn &FnDecl = 0
}

[inline]
pub fn new_interpreter(ctx &Context) Interpreter {
	return Interpreter{
		ctx: ctx
	}
}

fn (e &Interpreter) current_fn() ?&FnDecl {
	if isnil(e.current_fn) {
		return none
	}
	return e.current_fn
}

fn (e &Interpreter) print<T>(s T) {
	print(s.str())
}

fn (e &Interpreter) println<T>(s T) {
	println(s.str())
}

fn (e &Interpreter) eprint<T>(s T) {
	eprint(s.str())
}

fn (e &Interpreter) eprintln<T>(s T) {
	eprintln(s.str())
}

pub fn (mut e Interpreter) run(f &File) int {
	e.file(f)
	return 0
}

pub fn (mut e Interpreter) file(f &File) {
	e.stmts(f.stmts)
}
