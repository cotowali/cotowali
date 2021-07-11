module sh

import io
import cotowali.context { Context }
import cotowali.emit.code
import cotowali.ast { File, FnDecl }

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
	codes     map[CodeKind]&code.Builder
	cur_kind  CodeKind = .main
}

[inline]
pub fn new_emitter(out io.Writer, ctx &Context) Emitter {
	return Emitter{
		out: out
		codes: map{
			CodeKind.builtin: code.new_builder(100, ctx)
			CodeKind.literal: code.new_builder(100, ctx)
			CodeKind.main:    code.new_builder(100, ctx)
		}
	}
}

[inline]
fn (mut e Emitter) code() &code.Builder {
	return e.codes[e.cur_kind]
}

[inline]
fn (mut e Emitter) indent() {
	e.code().indent()
}

[inline]
fn (mut e Emitter) unindent() {
	e.code().unindent()
}

// --

[inline]
fn (mut e Emitter) writeln(s string) {
	e.code().writeln(s) or { panic(err) }
}

[inline]
fn (mut e Emitter) write(s string) {
	e.code().write_string(s) or { panic(err) }
}

fn (mut e Emitter) write_block<T>(opt code.WriteBlockOpt, f fn (mut Emitter, T), v T) {
	e.writeln(opt.open)
	e.indent()
	defer {
		e.unindent()
		e.writeln(opt.close)
	}

	f(mut e, v)
}

fn (mut e Emitter) write_inline_block<T>(opt code.WriteInlineBlockOpt, f fn (mut Emitter, T), v T) {
	e.write(opt.open)
	defer {
		e.write(opt.close)
		if opt.writeln {
			e.writeln('')
		}
	}

	f(mut e, v)
}

[inline]
fn (mut e Emitter) new_tmp_var() string {
	return e.code().new_tmp_var()
}
