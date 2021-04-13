module util

import io

type WritableData = []byte | string

pub fn write(w io.Writer, data WritableData) ?int {
	return w.write(match data {
		string { data.bytes() }
		[]byte { data }
	})
}
