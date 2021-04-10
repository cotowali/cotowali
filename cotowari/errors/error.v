module errors

import cotowari.source { Pos, Source }

pub const (
	unreachable = 'unreachable - This is a compiler bug.'
)

pub struct Error {
pub:
	source Source
	pos    Pos
	// Implements IError
	msg  string
	code int
}
