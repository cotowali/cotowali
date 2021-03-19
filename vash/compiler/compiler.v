module compiler

import os
import io
import rand { ulid }
import strings
import vash.source { Source }
import vash.lexer
import vash.parser
import vash.gen
import vash.ast

pub struct Compiler {
mut:
	source Source
}

pub struct CompileError {
	errors []ast.ErrorNode
	code int
	msg string
}

fn check_compile_error(file ast.File) ? {
	if file.errors.len > 0 {
		return IError(CompileError{
			errors: file.errors
			code: file.errors.len
			msg: 'compile error: $file.errors.len errors'
		})
	}
}

[inline]
pub fn new_compiler(source Source) Compiler {
	return Compiler{
		source: source
	}
}

pub fn (c &Compiler) compile() ?string {
	mut sb := strings.new_builder(100)
	c.compile_to(sb) ?
	return sb.str()
}

pub fn (c &Compiler) compile_to(w io.Writer) ? {
	mut p := parser.new(lexer.new(c.source))
	parsed_file := p.parse()
	check_compile_error(parsed_file) ?
	mut g := gen.new(w)
	g.gen(parsed_file)
}

fn (c &Compiler) compile_to_temp_file() ?string {
	temp_path := os.join_path(os.temp_dir(), '${os.file_name(c.source.path)}_${ulid()}.sh')
	mut f := os.create(temp_path) or { panic(err) }
	c.compile_to(f) ?
	defer {
		f.close()
	}
	return temp_path
}

pub fn (c &Compiler) run() ?int {
	temp_file := c.compile_to_temp_file() ?
	defer {
		os.rm(temp_file) or { panic(err) }
	}
	code := os.system('sh "$temp_file"')
	return code
}
