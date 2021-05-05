module errors

import cotowari.source { Pos, Source }

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

pub struct ErrorWithPos {
pub:
	pos  Pos
	msg  string
	code int
}
