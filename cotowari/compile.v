module cotowari

import os
import io
import rand { ulid }
import cotowari.context { Context }
import cotowari.source { Source }
import cotowari.compiler { new_compiler }
import cotowari.errors

pub fn compile(s Source, ctx &Context) ?string {
	c := new_compiler(s, ctx)
	return c.compile()
}

pub fn compile_to(w io.Writer, s Source, ctx &Context) ? {
	c := new_compiler(s, ctx)
	return c.compile_to(w)
}

fn compile_to_temp_file(s Source, ctx &Context) ?string {
	c := new_compiler(s, ctx)
	temp_path := os.join_path(os.temp_dir(), '${os.file_name(s.path)}_${ulid()}.sh')
	mut f := os.create(temp_path) or { panic(err) }
	c.compile_to(f) ?
	defer {
		f.close()
	}
	return temp_path
}

pub fn run(s Source, ctx &Context) ?int {
	temp_file := compile_to_temp_file(s, ctx) ?
	defer {
		os.rm(temp_file) or { panic(err) }
	}
	code := os.system('sh "$temp_file"')
	return code
}

pub fn format_error(err IError, f errors.Formatter) string {
	return if err is compiler.CompileError { err.errors.format(f) } else { err.msg + '\n' }
}
