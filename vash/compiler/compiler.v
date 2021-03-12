module compiler

import os
import io
import rand { ulid }
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

pub fn (c &Compiler) compile_to_temp_file() ?string {
	temp_path := os.join_path(os.temp_dir(), '${os.file_name(c.source.path)}_${ulid()}.sh')
	mut f := os.create(temp_path) or { panic(err) }
	c.compile_to(f) ?
	defer { f.close() }
	return temp_path
}

pub fn (c &Compiler) run() ?int {
	temp_file := c.compile_to_temp_file() ?
	defer { os.rm(temp_file) or { panic(err) } }
	code := os.system('sh "$temp_file"')
	return code
}
