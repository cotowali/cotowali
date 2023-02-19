// Copyright (c) 2021-2023 zakuro <z@kuro.red>
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
module compiler

import io
import strings
import cotowali.config { Config }
import cotowali.context { Context, new_context }
import cotowali.source { Source, new_source }
import cotowali.parser
import cotowali.checker
import cotowali.ast
import cotowali.emit
import cotowali.emit.ush

pub struct Compiler {
pub mut:
	ctx &Context
mut:
	source Source
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
	c.compile_to(sb)?
	return sb.str()
}

pub fn parse_and_check(s &Source, ctx &Context) ?&ast.File {
	mut f := parser.parse(s, ctx)

	if ctx.errors.has_syntax_error() {
		return error('syntax error')
	}

	if ctx.config.is_test {
		f.stmts << parser.parse(new_source('finish_test', 'testing::finish()'), ctx).stmts
	}
	ast.resolve(mut f, ctx)
	checker.check(mut f, ctx)

	if ctx.errors.len() > 0 {
		return error('checker error')
	}
	return f
}

fn (c &Compiler) ush_compile_to(w io.Writer) ? {
	mut ctx := c.ctx
	config := ctx.config

	mut sh_ctx := new_context(Config{ ...config, backend: .sh })
	mut pwsh_ctx := new_context(Config{ ...config, backend: .pwsh })

	sh_compiler := new_compiler(c.source, sh_ctx)
	pwsh_compiler := new_compiler(c.source, pwsh_ctx)

	sh_code := sh_compiler.compile() or {
		ctx.errors.push_many(sh_ctx.errors.all())
		return err
	}
	pwsh_code := pwsh_compiler.compile() or {
		ctx.errors.push_many(sh_ctx.errors.all())
		return err
	}

	if config.no_emit {
		return
	}

	mut e := ush.new_emitter(w)
	e.emit(sh: sh_code, pwsh: pwsh_code)
}

pub fn (c &Compiler) compile_to(w io.Writer) ? {
	ctx := c.ctx

	if ctx.config.backend == .ush {
		c.ush_compile_to(w)?
		return
	}

	if ctx.config.backend !in [.sh, .pwsh] {
		return error('${ctx.config.backend} backend is not yet implemented.')
	}

	f := parse_and_check(c.source, ctx)?

	if ctx.config.no_emit {
		return
	}

	mut e := emit.new_emitter(w, ctx)
	e.emit(f)
}
