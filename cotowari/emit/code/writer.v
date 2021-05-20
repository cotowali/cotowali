module code

import io
import cotowari.util { must_write }
import cotowari.config { Config }

pub struct Writer {
	config &Config
mut:
	indent    int
	newline   bool = true
	tmp_count int
pub:
	out io.Writer
}

[inline]
pub fn new_writer(out io.Writer, config &Config) Writer {
	return Writer{
		out: out
		config: config
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

pub fn (mut w Writer) new_tmp_var() string {
	defer {
		w.tmp_count++
	}
	return '_cotowari_tmp_$w.tmp_count'
}
