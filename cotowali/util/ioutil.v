module util

import io

type WritableData = []byte | string

pub fn write(w io.Writer, data WritableData) ?int {
	return w.write(match data {
		string { data.bytes() }
		[]byte { data }
	})
}

pub fn must_write(w io.Writer, data WritableData) int {
	return write(w, data) or { panic(err) }
}
