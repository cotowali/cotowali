module code

import strings
import cotowari.util { must_write }
import cotowari.config { Config }

pub struct Builder {
	config &Config
mut:
	indent    int
	newline   bool = true
	tmp_count int
	buf       strings.Builder
}

[inline]
pub fn new_builder(n int, config &Config) Builder {
	return Builder{
		buf: strings.new_builder(n)
		config: config
	}
}

pub fn (mut b Builder) str() string {
	return b.buf.str()
}

pub fn (b Builder) bytes() []byte {
	return b.buf
}

pub fn (mut b Builder) write(s string) {
	if s.len == 0 {
		return
	}
	if b.newline {
		b.write_indent()
	}
	must_write(b.buf, s)
	b.newline = s[s.len - 1] == `\n`
}

pub fn (mut b Builder) writeln(s string) {
	b.write(s + '\n')
}

pub fn (mut b Builder) write_indent() {
	must_write(b.buf, '  '.repeat(b.indent))
}

pub fn (mut b Builder) indent() {
	b.indent++
}

pub fn (mut b Builder) unindent() {
	b.indent--
}

pub fn (mut b Builder) new_tmp_var() string {
	defer {
		b.tmp_count++
	}
	return '_cotowari_tmp_$b.tmp_count'
}
