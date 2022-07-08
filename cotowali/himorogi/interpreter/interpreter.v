// Copyright (c) 2021 zakuro <z@kuro.red>. All rights reserved.
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
module interpreter

import cotowali.context { Context }
import cotowali.ast { File, FnDecl }
import cotowali.util { li_panic }

[heap]
struct Scope {
	name   string
	parent &Scope = unsafe { 0 }
mut:
	children map[string]&Scope
	vars     map[string]Value
}

fn (s &Scope) parent() ?&Scope {
	if isnil(s.parent) {
		return none
	}
	return s.parent
}

fn (mut s Scope) open_child(name string) &Scope {
	if name in s.children {
		s.children[name] = &Scope{
			name: name
			parent: s
		}
	}
	return s.children[name]
}

fn (s &Scope) lookup_var(name string) Value {
	return s.vars[name] or {
		mut parent := s.parent() or { li_panic(@FN, @FILE, @LINE, 'variable $name not found') }
		parent.lookup_var(name)
	}
}

fn (mut s Scope) set_var(name string, value Value) {
	if name in s.vars {
		s.vars[name] = &value
		return
	}
	mut parent := s.parent() or { li_panic(@FN, @FILE, @LINE, 'variable $name not found') }
	parent.set_var(name, value)
}

fn (mut s Scope) register_var(name string, value Value) {
	if name in s.vars {
		li_panic(@FN, @FILE, @LINE, 'variable $name exists')
	}
	s.vars[name] = &value
}

pub struct Interpreter {
mut:
	ctx        &Context
	current_fn &FnDecl = unsafe { 0 }
	scope      &Scope
}

[inline]
pub fn new_interpreter(ctx &Context) Interpreter {
	return Interpreter{
		ctx: ctx
		scope: &Scope{}
	}
}

fn (mut e Interpreter) open_scope(name string) &Scope {
	s := e.scope.open_child(name)
	e.scope = s
	return s
}

fn (mut e Interpreter) close_scope() &Scope {
	e.scope = e.scope.parent() or { li_panic(@FN, @FILE, @LINE, 'cannot close global scope') }
	return e.scope
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
