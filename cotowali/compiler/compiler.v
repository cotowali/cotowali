// Copyright (c) 2021 zakuro <z@kuro.red>. All rights reserved.
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
module compiler

import io
import strings
import cotowali.context { Context }
import cotowali.source { Source, new_source }
import cotowali.parser
import cotowali.checker
import cotowali.ast
import cotowali.emit

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
	ctx := c.ctx
	config := ctx.config
	if config.backend != .sh {
		return error('$config.backend backend is not yet implemented.')
	}
	mut f := parser.parse(c.source, ctx)

	if !ctx.errors.has_syntax_error() {
		if config.is_test {
			f.stmts << parser.parse(new_source('finish_test', 'testing::finish()'), ctx).stmts
		}
		/*
		f.stmts << ast.Expr(ast.CallExpr(
				func: ast.NamespaceItem{
					scope: ctx.global_scope
					namespace: ast.Ident{
						scope: ctx.global_scope
						text: 'testing'
					}
					func: ast.Var{
						ident: ast.Ident{
							scope: ctx.global_scope
							text: 'finish'
						}
					}
				}
			})
		*/

		ast.resolve(mut f, ctx)
		checker.check(mut f, ctx)
	}
	if ctx.errors.len() > 0 {
		return error('compile error')
	}

	if config.no_emit {
		return
	}

	mut e := emit.new_emitter(w, ctx)
	e.emit(f)
}
