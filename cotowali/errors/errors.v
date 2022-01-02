// Copyright (c) 2021 zakuro <z@kuro.red>. All rights reserved.
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
module errors

import cotowali.source { Pos, Source }
import cotowali.token { Token }
import cotowali.util { li_panic }

pub type ErrOrWarn = Err | Warn

pub fn (e ErrOrWarn) label() string {
	return match e {
		Err { 'error' }
		Warn { 'warning' }
	}
}

pub fn (e ErrOrWarn) source() &Source {
	return e.pos.source() or { li_panic(@FN, @FILE, @LINE, 'source is nil') }
}

// Err represents cotowali compile error
pub struct Err {
pub:
	pos             Pos
	is_syntax_error bool
	// Implements IError
	msg  string
	code int
}

pub fn (e &Err) source() &Source {
	return ErrOrWarn(e).source()
}

pub fn (lhs Err) < (rhs Err) bool {
	lhs_path, rhs_path := lhs.source().path, rhs.source().path
	return lhs_path < rhs_path || (lhs_path == rhs_path && lhs.pos.i < rhs.pos.i)
}

// Warn represents cotowali compile warning
pub struct Warn {
pub:
	pos Pos
	// Implements IError
	msg  string
	code int
}

pub fn (e &Warn) source() &Source {
	return ErrOrWarn(e).source()
}

pub fn (lhs Warn) < (rhs Warn) bool {
	lhs_path, rhs_path := lhs.source().path, rhs.source().path
	return lhs_path < rhs_path || (lhs_path == rhs_path && lhs.pos.i < rhs.pos.i)
}

pub struct LexerErr {
pub:
	token Token
	// Implements IError
	msg  string
	code int
}

pub struct LexerWarn {
pub:
	token Token
	// Implements IError
	msg  string
	code int
}

pub fn (err LexerErr) to_err() Err {
	return Err{
		pos: err.token.pos
		msg: err.msg
		code: err.code
	}
}

pub struct ErrorWithPos {
pub:
	pos  Pos
	msg  string
	code int
}
