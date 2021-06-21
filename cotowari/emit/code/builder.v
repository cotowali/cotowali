module code

import strings
import cotowari.util { must_write }
import cotowari.context { Context }

pub struct Builder {
	ctx &Context
mut:
	indent_n  int
	newline   bool = true
	tmp_count int
	buf       strings.Builder
}

[inline]
pub fn new_builder(n int, ctx &Context) Builder {
	return {
		buf: strings.new_builder(n)
		ctx: ctx
	}
}

pub fn (mut b Builder) len() int {
	return b.buf.len
}

pub fn (mut b Builder) str() string {
	return b.buf.str()
}

pub fn (b Builder) bytes() []byte {
	return b.buf
}

pub fn (mut b Builder) write(data []byte) ?int {
	if data.len == 0 {
		return 0
	}
	orig_len := b.len()
	if b.newline {
		b.write_indent()
	}
	defer {
		b.newline = data[data.len - 1] == `\n`
	}
	b.buf.write(data) ?
	return b.len() - orig_len
}

pub fn (mut b Builder) write_string(s string) {
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
	b.write_string(s + '\n')
}

pub fn (mut b Builder) write_indent() {
	must_write(b.buf, b.ctx.config.indent.repeat(b.indent_n))
}

pub fn (mut b Builder) indent() {
	b.indent_n++
}

pub fn (mut b Builder) unindent() {
	b.indent_n--
}

pub fn (mut b Builder) new_tmp_var() string {
	defer {
		b.tmp_count++
	}
	return '_cotowari_tmp_$b.tmp_count'
}

pub struct WriteBlockOpt {
pub:
	open  string [required]
	close string [required]
}

pub struct WriteInlineBlockOpt {
pub:
	open    string [required]
	close   string [required]
	writeln bool
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
}*/
