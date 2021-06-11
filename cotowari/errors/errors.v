module errors

import cotowari.source { Pos, Source }
import cotowari.token { Token }

pub const (
	unreachable = 'unreachable - This is a compiler bug.'
)

// Err represents cotowari compile error
pub struct Err {
pub:
	source          &Source
	pos             Pos
	is_syntax_error bool
	// Implements IError
	msg  string
	code int
}

pub fn (lhs Err) < (rhs Err) bool {
	lhs_path, rhs_path := lhs.source.path, rhs.source.path
	return lhs_path < rhs_path || (lhs_path == rhs_path && lhs.pos.i < rhs.pos.i)
}

pub struct ErrWithToken {
pub:
	source &Source
	token  Token
	// Implements IError
	msg  string
	code int
}

pub fn (err ErrWithToken) to_err() Err {
	return {
		source: err.source
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

pub struct Errors {
mut:
	i    int // for iter
	list []Err

	has_syntax_error bool
}

pub fn (mut e Errors) push(err Err) Err {
	if err.is_syntax_error {
		e.has_syntax_error = true
	}
	e.list << err
	return err
}

[inline]
pub fn (e Errors) has_syntax_error() bool {
	return e.has_syntax_error
}

pub fn (mut e Errors) sort() {
	e.list.sort()
}

pub fn (mut e Errors) list() []Err {
	e.sort()
	return e.list
}

[inline]
pub fn (e Errors) len() int {
	return e.list.len
}

pub fn (mut e Errors) next() ?Err {
	if e.i == 0 {
		e.sort()
	}
	if e.i >= e.list.len {
		e.i = 0
		return none
	}
	err := e.list[e.i]
	e.i++
	return err
}
