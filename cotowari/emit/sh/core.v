module sh

import io
import cotowari.config { Config }
import cotowari.emit.code
import cotowari.ast { File, FnDecl }

enum CodeKind {
	builtin
	main
	literal
}

const ordered_code_kinds = [
	CodeKind.builtin,
	.literal,
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
			CodeKind.literal: code.new_builder(100, config)
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

fn (mut e Emitter) write_block<T>(opt code.WriteBlockOpt, f fn (mut Emitter, T), v T) {
	if opt.inline {
		e.code[e.cur_kind].write(opt.open)
		defer {
			e.code[e.cur_kind].write(opt.close)
		}
	} else {
		e.code[e.cur_kind].writeln(opt.open)
		e.indent()
		defer {
			e.unindent()
			e.code[e.cur_kind].writeln(opt.close)
		}
	}

	f(mut e, v)
}

fn (mut e Emitter) with_line_terminator<T>(s string, f fn (mut Emitter, T), v T) {
	old := e.code[e.cur_kind].line_terminator
	defer {
		e.code[e.cur_kind].line_terminator = old
	}
	e.code[e.cur_kind].line_terminator = s
	f(mut e, v)
}

[inline]
fn (mut e Emitter) new_tmp_var() string {
	return e.code[e.cur_kind].new_tmp_var()
}
