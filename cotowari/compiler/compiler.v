module compiler

import io
import strings
import cotowari.context { Context }
import cotowari.source { Source }
import cotowari.lexer { new_lexer }
import cotowari.parser { new_parser }
import cotowari.checker { new_checker }
import cotowari.emit.sh
import cotowari.ast
import cotowari.errors { Err }

pub struct Compiler {
pub:
	ctx &Context
mut:
	source Source
}

pub struct CompileError {
pub:
	errors []Err
	code   int
	msg    string
}

fn check_compile_error(file ast.File) ? {
	if file.errors.len > 0 {
		return IError(&CompileError{
			errors: file.errors
			code: file.errors.len
			msg: 'compile error: $file.errors.len errors'
		})
	}
}

[inline]
pub fn new_compiler(source Source, ctx &Context) Compiler {
	return Compiler{
		source: source
		ctx: ctx
	}
}

pub fn (c &Compiler) compile() ?string {
	mut sb := strings.new_builder(100)
	c.compile_to(sb) ?
	return sb.str()
}

pub fn (c &Compiler) compile_to(w io.Writer) ? {
	config := c.ctx.config
	if config.backend != .sh {
		return error('$config.backend backend is not yet implemented.')
	}
	mut p := new_parser(new_lexer(c.source, c.ctx))
	mut f := p.parse()

	if !f.has_syntax_error {
		mut checker := new_checker()
		checker.check_file(mut f)
	}
	check_compile_error(f) ?

	if config.no_emit {
		return
	}

	mut e := sh.new_emitter(w, c.ctx)
	e.emit(f)
}
