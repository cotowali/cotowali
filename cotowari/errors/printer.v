module errors

import io

pub interface Printer {
	print(io.Writer, Err)
}
