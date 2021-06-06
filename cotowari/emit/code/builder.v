module code

import strings
import cotowari.util { must_write }
import cotowari.config { Config }

const (
	default_line_terminator = '\n'
)

pub struct Builder {
	config &Config
mut:
	indent    int
	newline   bool = true
	tmp_count int
	buf       strings.Builder
pub mut:
	line_terminator string = code.default_line_terminator
}

[inline]
pub fn new_builder(n int, config &Config) Builder {
	return {
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

pub fn (mut b Builder) reset_line_terminator() {
	b.line_terminator = code.default_line_terminator
}

pub fn (mut b Builder) writeln(s string) {
	b.write(s + b.line_terminator)
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

pub struct WriteBlockOpt {
pub:
	open   string [required]
	close  string [required]
	inline bool
}

/*
TODO: wait to fix v bug
pub fn (mut b Builder) write_block<R, V>(opt WriteBlockOpt, f fn (mut R, V), mut receiver R, v V) {
	if opt.inline {
		b.write(opt.open)
		defer {
			b.write(opt.close)
		}
	} else {
		b.writeln(opt.open)
		b.indent()
		defer {
			b.unindent()
			b.writeln(opt.close)
		}
	}

	f(mut receiver, v)
}

fn (mut e Emitter) with_line_terminator<T>(s string, f fn (mut R, T), mut receiver R, v T) {
	old := e.line_terminator
	defer {
		e.line_treminator = old
	}
	e.line_terminator = s
	f(mut e, v)
}
*/
