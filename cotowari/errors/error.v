module errors

import cotowari.source { Pos, Source }
import cotowari.token { Token }

pub const (
	unreachable = 'unreachable - This is a compiler bug.'
)

// Err represents cotowari compile error
pub struct Err {
pub:
	source Source
	pos    Pos
	// Implements IError
	msg  string
	code int
}

pub struct ErrWithToken {
pub:
	source Source
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
