module code

import strings
import cotowali.context { Context }

// magic number to represen tail of file
pub const tail = -0xffff

[flag]
pub enum BuilderFlags {
	dummy
}

pub fn (mut flags BuilderFlags) reset() {
	flags = BuilderFlags(0)
}

pub struct Builder {
	ctx &Context
mut:
	indent_n  int
	tmp_count int
	buf       strings.Builder
	tail_str  string
pub mut:
	flags BuilderFlags
}

pub fn (b Builder) clone() Builder {
	return Builder{
		...b
		buf: b.buf.clone()
	}
}

[inline]
pub fn new_builder(n int, ctx &Context) &Builder {
	return &Builder{
		buf: strings.new_builder(n)
		ctx: ctx
	}
}

pub fn (b &Builder) newline() bool {
	return b.buf.len == 0 || b.buf.byte_at(b.buf.len - 1) == `\n`
}

pub fn (b &Builder) len() int {
	return b.buf.len + b.tail_str.len
}

pub fn (mut b Builder) str() string {
	if b.tail_str.len == 0 {
		return b.buf.str()
	}
	defer {
		b.tail_str = ''
	}
	return b.buf.str() + b.tail_str
}

pub fn (mut b Builder) bytes() []byte {
	return b.str().bytes()
}

pub fn (mut b Builder) pos() int {
	return b.buf.len
}

pub fn (mut b Builder) seek(pos int) ? {
	if pos == code.tail {
		b.buf.write_string(b.tail_str)
		b.tail_str = ''
		return
	}

	if pos < 0 || pos > b.len() {
		return error('seek: out of range')
	}

	if pos < b.buf.len {
		b.tail_str = b.buf.cut_to(pos) + b.tail_str
	} else {
		tail_i := pos - b.buf.len
		b.buf.write_string(b.tail_str[..tail_i])
		b.tail_str = b.tail_str[tail_i..]
	}
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
	return '_cotowali_tmp_$b.tmp_count'
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
