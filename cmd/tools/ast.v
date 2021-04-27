module tools

import cli { Command }
import cotowari.parser

const (
	ast_command = Command{
		name: 'ast'
		description: 'print ast'
		execute: fn (cmd Command) ? {
			if cmd.args.len != 1 {
				cmd.execute_help()
				return
			}
			if f := parser.parse_file(cmd.args[0]) { println(f) } else { println('ERROR') }
			return
		}
	}
)
