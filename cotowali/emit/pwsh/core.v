// Copyright (c) 2021-2023 zakuro <z@kuro.red>
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
module pwsh

import io
import cotowali.context { Context }
import cotowali.ast { FnDecl }
import cotowali.emit.code

pub struct Emitter {
mut:
	out        io.Writer
	ctx        &Context
	code       code.Builder
	tmp_count  int
	current_fn &FnDecl = unsafe { 0 }
}

[inline]
pub fn new_emitter(out io.Writer, ctx &Context) Emitter {
	language_config := code.LanguageConfig{}
	return Emitter{
		ctx: ctx
		out: out
		code: code.new_builder(100, ctx, language_config)
	}
}

fn (e &Emitter) current_fn() ?&FnDecl {
	if isnil(e.current_fn) {
		return none
	}
	return e.current_fn
}

[inline]
fn (mut e Emitter) indent() {
	e.code.indent()
}

[inline]
fn (mut e Emitter) unindent() {
	e.code.unindent()
}

fn (mut e Emitter) new_tmp_ident() string {
	defer {
		e.tmp_count++
	}
	return '_cotowali_tmp_${e.tmp_count}'
}

[inline]
fn (mut e Emitter) seek(pos int) ! {
	return e.code.seek(pos)
}

fn (mut e Emitter) insert_at[T](pos int, f fn (mut Emitter, T), v T) {
	pos_save := e.code.pos()
	e.seek(pos) or { panic(err) }
	f(mut e, v)
	n := e.code.pos() - pos
	e.seek(pos_save + n) or { panic(err) }
}

// --

[inline]
fn (mut e Emitter) writeln(s string) {
	e.code.writeln(s) or { panic(err) }
}

[inline]
fn (mut e Emitter) write(s string) {
	e.code.write_string(s) or { panic(err) }
}
