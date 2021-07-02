module tools

import cli { Command }
import cotowali.context { new_default_context }
import cotowali.parser
import cotowali.checker { new_checker }
import cotowali.ast { new_resolver }

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
		mut resolver := new_resolver(ctx)
		resolver.resolve(f)
		mut checker := new_checker(ctx)
		checker.check_file(mut f)
		println(f)
		if ctx.errors.len() > 0 {
			eprintln('checker or resolver error')
		}
	}
	return
}
