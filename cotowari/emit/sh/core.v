module sh

import io
import cotowari.config { Config }
import cotowari.emit.code
import cotowari.ast { File, FnDecl }

enum CodeKind {
	builtin
	main
}

const ordered_code_kinds = [
	CodeKind.builtin,
	.main,
]

pub struct Emitter {
mut:
	cur_file  &File = 0
	cur_fn    FnDecl
	inside_fn bool
	out       io.Writer
	code      map[CodeKind]code.Builder
	cur_kind  CodeKind = .main
}

[inline]
pub fn new_emitter(out io.Writer, config &Config) Emitter {
	return Emitter{
		out: out
		code: map{
			CodeKind.builtin: code.new_builder(100, config)
			CodeKind.main:    code.new_builder(100, config)
		}
	}
}

[inline]
fn (mut e Emitter) writeln(s string) {
	e.code[e.cur_kind].writeln(s)
}

[inline]
fn (mut e Emitter) write(s string) {
	e.code[e.cur_kind].write(s)
}

[inline]
fn (mut e Emitter) indent() {
	e.code[e.cur_kind].indent()
}

[inline]
fn (mut e Emitter) unindent() {
	e.code[e.cur_kind].unindent()
}

fn (mut e Emitter) write_block<T>(begin string, end string, f fn (mut Emitter, T), v T) {
	e.code[e.cur_kind].writeln(begin)
	e.indent()
	f(mut e, v)
	e.unindent()
	e.code[e.cur_kind].writeln(end)
}

[inline]
fn (mut e Emitter) new_tmp_var() string {
	return e.code[e.cur_kind].new_tmp_var()
}
