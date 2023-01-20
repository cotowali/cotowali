// Copyright (c) 2021 zakuro <z@kuro.red>. All rights reserved.
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
module sh

import io
import cotowali.context { Context }
import cotowali.emit.code
import cotowali.ast { FnDecl }
import cotowali.util { li_panic }

enum CodeKind {
	builtin
	main
}

const ordered_code_kinds = [
	CodeKind.builtin,
	.main,
]

pub struct Emitter {
	ident_to_discard string = '__cotowali_dummy'
mut:
	cur_fn        FnDecl
	ctx           &Context
	inside_fn     bool
	tmp_count     int
	out           io.Writer
	codes         map[CodeKind]&code.Builder
	cur_kind      CodeKind = .main
	stmt_head_pos map[CodeKind][]int
}

[inline]
pub fn new_emitter(out io.Writer, ctx &Context) Emitter {
	language_config := code.LanguageConfig{}
	return Emitter{
		ctx: ctx
		out: out
		codes: {
			CodeKind.builtin: code.new_builder(100, ctx, language_config)
			CodeKind.main:    code.new_builder(100, ctx, language_config)
		}
	}
}

fn (e &Emitter) cur_fn() ?FnDecl {
	if !e.inside_fn {
		return none
	}
	return e.cur_fn
}

[inline]
fn (mut e Emitter) code() &code.Builder {
	return e.codes[e.cur_kind] or { li_panic(@FN, @FILE, @LINE, '') }
}

[inline]
fn (mut e Emitter) stmt_head_pos() int {
	return e.stmt_head_pos[e.cur_kind].last()
}

[inline]
fn (mut e Emitter) indent() {
	mut code := e.code()
	code.indent()
}

[inline]
fn (mut e Emitter) unindent() {
	mut code := e.code()
	code.unindent()
}

fn (mut e Emitter) new_tmp_ident() string {
	defer {
		e.tmp_count++
	}
	return '_cotowali_tmp_${e.tmp_count}'
}

[inline]
fn (mut e Emitter) seek(pos int) ! {
	mut code := e.code()
	return code.seek(pos)
}

fn (mut e Emitter) insert_at[T](pos int, f fn (mut Emitter, T), v T) {
	pos_save := e.code().pos()
	e.seek(pos) or { li_panic(@FN, @FILE, @LINE, err) }
	f(mut e, v)
	n := e.code().pos() - pos
	e.seek(pos_save + n) or { li_panic(@FN, @FILE, @LINE, err) }
}

fn (mut e Emitter) lock_cursor() {
	mut code := e.code()
	code.lock_cursor()
}

[inline]
fn (mut e Emitter) unlock_cursor() {
	mut code := e.code()
	code.unlock_cursor()
}

fn (mut e Emitter) with_lock_cursor[T](f fn (mut Emitter, T), v T) {
	distance_from_tail := e.code().len() - e.code().pos()
	defer {
		e.seek(e.code().len() - distance_from_tail) or { li_panic(@FN, @FILE, @LINE, err) }
	}

	e.lock_cursor()
	f(mut e, v)
	e.unlock_cursor()
}

// --

[inline]
fn (mut e Emitter) writeln(s string) {
	mut code := e.code()
	code.writeln(s) or { li_panic(@FN, @FILE, @LINE, err) }
}

[inline]
fn (mut e Emitter) write(s string) {
	mut code := e.code()
	code.write_string(s) or { li_panic(@FN, @FILE, @LINE, err) }
}

fn (mut e Emitter) write_if(cond bool, s string) {
	if cond {
		e.write(s)
	}
	// return cond
}

fn (mut e Emitter) writeln_if(cond bool, s string) {
	if cond {
		e.writeln(s)
	}
	// return cond
}
