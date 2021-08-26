// Copyright (c) 2021 zakuro <z@kuro.red>. All rights reserved.
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
module tools

import cli { Command }
import cotowali.context { new_default_context }
import cotowali.parser
import cotowali.checker { new_checker }
import cotowali.ast

const (
	ast_command = Command{
		name: 'ast'
		description: 'print ast'
		execute: execute_ast
	}
)

fn execute_ast(cmd Command) ? {
	if cmd.args.len != 1 {
		cmd.execute_help()
		return
	}
	ctx := new_default_context()
	mut f := parser.parse_file(cmd.args[0], ctx) or {
		eprintln('ERROR')
		return
	}
	if ctx.errors.has_syntax_error() {
		println(f)
		eprintln('syntax error')
	} else {
		ast.resolve(mut f, ctx)
		mut checker := new_checker(ctx)
		checker.check(mut f)
		println(f)
		if ctx.errors.len() > 0 {
			eprintln('checker or resolver error')
		}
	}
	return
}
