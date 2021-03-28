module errors

import cotowari.pos { Pos }
import cotowari.source { Source }

pub struct Error {
pub:
	source Source
	pos    Pos
	// Implements IError
	msg  string
	code int
}
