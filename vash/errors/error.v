module errors

import vash.pos { Pos }
import vash.source { Source }
import vash.token { Token }

pub struct Error {
pub:
	source Source
	pos		 Pos
	// Implements IError
	msg  string
	code int
}
