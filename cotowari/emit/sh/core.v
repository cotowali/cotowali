module sh

import io
import cotowari.config { Config }
import cotowari.emit.code
import cotowari.ast { File, FnDecl }

pub struct Emitter {
mut:
	cur_file  &File = 0
	cur_fn    FnDecl
	inside_fn bool
	out       io.Writer
	code      code.Builder
}

[inline]
pub fn new_emitter(out io.Writer, config &Config) Emitter {
	return Emitter{
		out: out
		code: code.new_builder(100, config)
	}
}

[inline]
fn (mut e Emitter) writeln(s string) {
	e.code.writeln(s)
}

[inline]
fn (mut e Emitter) write(s string) {
	e.code.write(s)
}

[inline]
fn (mut e Emitter) indent() {
	e.code.indent()
}

[inline]
fn (mut e Emitter) unindent() {
	e.code.unindent()
}

fn (mut e Emitter) write_block<T>(begin string, end string, f fn (mut Emitter, T), v T) {
	e.code.writeln(begin)
	e.indent()
	f(mut e, v)
	e.unindent()
	e.code.writeln(end)
}

[inline]
fn (mut e Emitter) new_tmp_var() string {
	return e.code.new_tmp_var()
}
