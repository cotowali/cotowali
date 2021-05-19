module code

import io
import cotowari.util { must_write }

pub struct Writer {
mut:
	indent  int
	newline bool = true
pub:
	out io.Writer
}

[inline]
pub fn new_writer(out io.Writer) Writer {
	return Writer{
		out: out
	}
}

pub fn (mut w Writer) write(s string) {
	$if !prod {
		if s == '' {
			panic('writing empty')
		}
	}
	if w.newline {
		w.write_indent()
	}
	must_write(w.out, s)
	w.newline = s[s.len - 1] == `\n`
}

pub fn (mut w Writer) writeln(s string) {
	w.write(s + '\n')
}

pub fn (mut w Writer) write_indent() {
	must_write(w.out, '  '.repeat(w.indent))
}

pub fn (mut w Writer) indent() {
	w.indent++
}

pub fn (mut w Writer) unindent() {
	w.indent--
}
