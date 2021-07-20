// Copyright (c) 2021 zakuro <z@kuro.red>. All rights reserved.
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
module compiler

import io
import strings
import cotowali.context { Context }
import cotowali.source { Source }
import cotowali.lexer { new_lexer }
import cotowali.parser { new_parser }
import cotowali.checker { new_checker }
import cotowali.ast { new_resolver }
import cotowali.emit.sh

pub struct Compiler {
pub:
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

	if !c.ctx.errors.has_syntax_error() {
		mut resolver := new_resolver(c.ctx)
		resolver.resolve(f)
		mut checker := new_checker(c.ctx)
		checker.check_file(mut f)
	}
	if c.ctx.errors.len() > 0 {
		return error('compile error')
	}

	if config.no_emit {
		return
	}

	mut e := sh.new_emitter(w, c.ctx)
	e.emit(f)
}
