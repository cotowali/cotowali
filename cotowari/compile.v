module cotowari

import os
import io
import strings
import rand { ulid }
import cotowari.config { Config }
import cotowari.source { Source }
import cotowari.compiler { new_compiler }
import cotowari.errors

pub fn compile(s Source, config &Config) ?string {
	c := new_compiler(s, config)
	$if debug {
		// workaround for avoid V's bug. unknnown enum error will be showed without this only debug mode
		_ := c.config.backend
	}
	return c.compile()
}

pub fn compile_to(w io.Writer, s Source, config &Config) ? {
	c := new_compiler(s, config)
	return c.compile_to(w)
}

fn compile_to_temp_file(s Source, config &Config) ?string {
	c := new_compiler(s, config)
	temp_path := os.join_path(os.temp_dir(), '${os.file_name(s.path)}_${ulid()}.sh')
	mut f := os.create(temp_path) or { panic(err) }
	c.compile_to(f) ?
	defer {
		f.close()
	}
	return temp_path
}

pub fn run(s Source, config &Config) ?int {
	temp_file := compile_to_temp_file(s, config) ?
	defer {
		os.rm(temp_file) or { panic(err) }
	}
	code := os.system('sh "$temp_file"')
	return code
}

pub fn format_error(err IError, f errors.Formatter) string {
	if err is compiler.CompileError {
		mut sb := strings.new_builder(10)
		for e in err.errors {
			sb.write_string(f.format(e))
		}
		return sb.str()
	}
	return err.msg + '\n'
}
