module errors

import io
import os

pub interface Printer {
	print(io.Writer, Err)
}

pub struct SimplePrinter {}

pub fn (p SimplePrinter) print(w io.Writer, err Err) {
	s := err.source
	file := os.file_name(s.path)
	pos := err.pos
	msg := '$file $pos.line,$pos.col: $err.msg\n'
	w.write(msg.bytes()) or { panic(err) }
}
