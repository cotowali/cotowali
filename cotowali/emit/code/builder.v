// Copyright (c) 2021 zakuro <z@kuro.red>. All rights reserved.
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
module code

import strings
import cotowali.context { Context }
import cotowali.util { li_panic }

// magic number to represen tail of file
pub const tail = -0xffff

[flag]
pub enum BuilderFlags {
	lock_cursor
}

pub fn (mut flags BuilderFlags) reset() {
	flags = BuilderFlags(0)
}

[params]
pub struct LanguageConfig {
	comment_start string = '#'
}

pub struct Builder {
	ctx      &Context
	language LanguageConfig
mut:
	indent_n  int
	tmp_count int
	buf       strings.Builder
	tail_str  string
	flags     BuilderFlags
}

[inline]
pub fn new_builder(n int, ctx &Context, language LanguageConfig) &Builder {
	return &Builder{
		buf: strings.new_builder(n)
		ctx: ctx
		language: language
	}
}

pub fn (b Builder) clone() Builder {
	return Builder{
		...b
		buf: b.buf.clone()
	}
}

// --

pub fn (b &Builder) pos() int {
	return b.buf.len
}

pub fn (b &Builder) len() int {
	return b.buf.len + b.tail_str.len
}

pub fn (b &Builder) newline() bool {
	return b.buf.len == 0 || b.buf.byte_at(b.buf.len - 1) == `\n`
}

// --

pub fn (mut b Builder) str() string {
	if b.tail_str.len == 0 {
		return b.buf.str()
	}
	defer {
		b.tail_str = ''
	}
	return b.buf.str() + b.tail_str
}

pub fn (mut b Builder) bytes() []u8 {
	return b.str().bytes()
}

// --

pub fn (mut b Builder) lock_cursor() {
	b.flags.set(.lock_cursor)
}

pub fn (mut b Builder) unlock_cursor() {
	b.flags.clear(.lock_cursor)
}

// --

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

// --

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

// --

pub fn (mut b Builder) write(data []byte) ?int {
	if data.len == 0 {
		return 0
	}

	mut n := 0
	if b.newline() {
		n += b.write_indent()?
	}
	if b.flags.has(.lock_cursor) {
		pos := b.pos()
		defer {
			b.seek(pos) or { li_panic(@FN, @FILE, @LINE, err) }
		}
	}
	n += b.buf.write(data)?
	return n
}

pub fn (mut b Builder) write_string(s string) ?int {
	return b.write(s.bytes())
}

pub fn (mut b Builder) writeln(s string) ?int {
	n := b.write_string(s)?
	b.buf << `\n`
	return n + 1
}

pub fn (mut b Builder) writeln_comment(s string) ?int {
	mut text := if b.buf.len > 0 && b.buf.last() !in [` `, `\n`] { ' ' } else { '' }
	text += s.split_into_lines().map('${b.language.comment_start} ${it}').join('\n')
	n := b.write_string(text)?
	b.buf << `\n`
	return n + 1
}
