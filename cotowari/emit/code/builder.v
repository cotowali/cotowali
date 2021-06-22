module code

import strings
import cotowari.context { Context }

pub struct Builder {
	ctx &Context
mut:
	indent_n  int
	tmp_count int
	buf       strings.Builder
}

pub fn (b Builder) clone() Builder {
	return Builder{
		...b
		buf: b.buf.clone()
	}
}

[inline]
pub fn new_builder(n int, ctx &Context) Builder {
	return {
		buf: strings.new_builder(n)
		ctx: ctx
	}
}

pub fn (b &Builder) newline() bool {
	if b.len() > 0 {
		println(b.buf[b.len() - 1])
	}
	return b.len() == 0 || b.buf.byte_at(b.len() - 1) == `\n`
}

pub fn (b &Builder) len() int {
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

	mut n := 0
	if b.newline() {
		n += b.write_indent() ?
	}
	n += b.buf.write(data) ?
	return n
}

pub fn (mut b Builder) write_string(s string) ?int {
	return b.write(s.bytes())
}

pub fn (mut b Builder) writeln(s string) ?int {
	n := b.write_string(s) ?
	b.buf << `\n`
	return n + 1
}

pub fn (mut b Builder) write_indent() ?int {
	s := b.ctx.config.indent.repeat(b.indent_n)
	b.buf.write_string(s)
	return s.len
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
