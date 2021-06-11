module tools

import cli { Command, Flag }
import cotowari.context { new_default_context }
import cotowari.parser
import cotowari.checker { new_checker }

const (
	use_checker_flag = Flag{
		flag: .bool
		name: 'use-checker'
		abbrev: 'c'
		default_value: ['true']
	}
	ast_command = Command{
		name: 'ast'
		description: 'print ast'
		flags: [use_checker_flag]
		execute: execute_ast
	}
)

fn execute_ast(cmd Command) ? {
	if cmd.args.len != 1 {
		cmd.execute_help()
		return
	}
	use_checker := cmd.flags.get_bool(tools.use_checker_flag.name) or { panic(err) }
	ctx := new_default_context()
	mut f := parser.parse_file(cmd.args[0], ctx) or {
		eprintln('ERROR')
		return
	}
	if use_checker {
		mut checker := new_checker(ctx)
		checker.check_file(mut f)
		println(f)
		if ctx.errors.len() > 0 {
			eprintln('checker error')
		}
	}
	return
}
