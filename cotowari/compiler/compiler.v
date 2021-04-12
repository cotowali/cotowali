module compiler

import io
import strings
import cotowari.source { Source }
import cotowari.lexer { new_lexer }
import cotowari.parser { new_parser }
import cotowari.checker { new_checker }
import cotowari.emit { new_emitter }
import cotowari.ast
import cotowari.errors

pub struct Compiler {
mut:
	source Source
}

pub struct CompileError {
pub:
	errors []errors.Error
	code   int
	msg    string
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
	mut p := new_parser(new_lexer(c.source))
	mut f := p.parse()
	check_compile_error(f) ?

	checker := new_checker()
	checker.check_file(mut f)
	check_compile_error(f) ?

	mut e := new_emitter(w)
	e.emit(f)
}
