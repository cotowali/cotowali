module osutil

import os

pub fn read_file(path string) ?string {
	return os.read_file(path)
}

pub fn must_read_file(path string) string {
	text := os.read_file(path) or { panic(err) }
	return text
}
