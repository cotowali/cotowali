// Copyright (c) 2021 zakuro <z@kuro.red>. All rights reserved.
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
module errors

pub struct ErrorManager {
mut:
	list map[string][]ErrOrWarn

	has_syntax_error bool
}

pub fn (mut e ErrorManager) clear() {
	e.list = {}
	e.has_syntax_error = false
}

pub fn (mut e ErrorManager) push(err ErrOrWarn) ErrOrWarn {
	return match err {
		Err { e.push_err(err) }
		Warn { e.push_warn(err) }
	}
}

pub fn (mut e ErrorManager) push_err(err Err) Err {
	if err.is_syntax_error {
		e.has_syntax_error = true
	}
	e.list[err.source().path] << err
	return err
}

[inline]
pub fn (mut e ErrorManager) push_warn(warn Warn) Warn {
	e.list[warn.source().path] << warn
	return warn
}

pub fn (mut e ErrorManager) push_many(errs []ErrOrWarn) []ErrOrWarn {
	for err in errs {
		e.push(err)
	}
	return errs
}

[inline]
pub fn (e ErrorManager) has_syntax_error() bool {
	return e.has_syntax_error
}

pub fn (mut e ErrorManager) sort() {
	for _, mut list in e.list {
		list.sort(a.pos.i < b.pos.i)
	}
}

pub fn (mut e ErrorManager) all() []ErrOrWarn {
	e.sort()
	mut keys := e.list.keys()
	keys.sort()

	mut ret := []ErrOrWarn{cap: e.list.len * 2}
	for key in keys {
		ret << e.list[key]
	}
	return ret
}

pub fn (mut e ErrorManager) errors() []Err {
	return e.all().filter(it is Err).map(it as Err)
}

pub fn (mut e ErrorManager) warnings() []Warn {
	return e.all().filter(it is Warn).map(it as Warn)
}

[inline]
pub fn (e ErrorManager) len() int {
	return e.list.len
}
