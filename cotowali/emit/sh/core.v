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
	cur_file      &File = 0
	cur_fn        FnDecl
	inside_fn     bool
	tmp_count     int
	out           io.Writer
	codes         map[CodeKind]&code.Builder
	cur_kind      CodeKind = .main
	stmt_head_pos map[CodeKind]int
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
fn (mut e Emitter) stmt_head_pos() int {
	return e.stmt_head_pos[e.cur_kind]
}

[inline]
fn (mut e Emitter) indent() {
	e.code().indent()
}

[inline]
fn (mut e Emitter) unindent() {
	e.code().unindent()
}

fn (mut e Emitter) new_tmp_ident() string {
	defer {
		e.tmp_count++
	}
	return '_cotowali_tmp_$e.tmp_count'
}

[inline]
fn (mut e Emitter) seek(pos int) ? {
	return e.code().seek(pos)
}

fn (mut e Emitter) insert_at<T>(pos int, f fn (mut Emitter, T), v T) {
	pos_save := e.code().pos()
	e.seek(pos) or { panic(err) }
	f(mut e, v)
	n := e.code().pos() - pos
	e.seek(pos_save + n) or { panic(err) }
}

fn (mut e Emitter) lock_cursor() {
	e.code().lock_cursor()
}

[inline]
fn (mut e Emitter) unlock_cursor() {
	e.code().unlock_cursor()
}

fn (mut e Emitter) with_lock_cursor<T>(f fn (mut Emitter, T), v T) {
	distance_from_tail := e.code().len() - e.code().pos()
	defer {
		e.seek(e.code().len() - distance_from_tail) or { panic(err) }
	}

	e.lock_cursor()
	f(mut e, v)
	e.unlock_cursor()
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
