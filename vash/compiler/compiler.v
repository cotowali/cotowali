module compiler

import os
import io
import strings
import vash.source { Source }
import vash.lexer
import vash.parser
import vash.gen

struct Compiler {
mut:
	source Source
}

[inline]
pub fn new_compiler(source Source) Compiler {
	return Compiler{
		source: source
	}
}

[inline]
pub fn new_file_compiler(path string) ?Compiler {
	source := source.read_file(path) ?
	return new_compiler(source)
}

pub fn (c &Compiler) compile_to_file(path string) ? {
	f := os.create(path) ?
	c.compile_to(f) ?
}

struct Buf {
mut:
	out strings.Builder
}

fn (mut buf Buf) write(data []byte) ?int {
	unsafe { buf.out.write_bytes(data.data, data.len) }
	return data.len
}

pub fn (c &Compiler) compile_to_stdout() ? {
	buf := Buf{
		out: strings.new_builder(100)
	}
	c.compile_to(&buf) ?
	println(buf.out)
}

pub fn (c &Compiler) compile_to(w io.Writer) ? {
	mut p := parser.new(lexer.new(c.source))
	parsed_file := p.parse() ?
	mut g := gen.new(w)
	g.gen(parsed_file)
}
