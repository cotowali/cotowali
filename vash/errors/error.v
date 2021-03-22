module errors

import vash.pos { Pos }
import vash.source { Source }

pub struct Error {
pub:
	source Source
	pos    Pos
	// Implements IError
	msg  string
	code int
}
