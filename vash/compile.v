module vash

import os
import io
import rand { ulid }
import vash.source { Source }
import vash.compiler { new_compiler }

pub fn compile(s Source) ?string {
	c := new_compiler(s)
	return c.compile()
}

pub fn compile_to(w io.Writer, s Source) ? {
	c := new_compiler(s)
	return c.compile_to(w)
}

fn compile_to_temp_file(s Source) ?string {
	c := new_compiler(s)
	temp_path := os.join_path(os.temp_dir(), '${os.file_name(s.path)}_${ulid()}.sh')
	mut f := os.create(temp_path) or { panic(err) }
	c.compile_to(f) ?
	defer {
		f.close()
	}
	return temp_path
}

pub fn run(s Source) ?int {
	temp_file := compile_to_temp_file(s) ?
	defer {
		os.rm(temp_file) or { panic(err) }
	}
	code := os.system('sh "$temp_file"')
	return code
}
