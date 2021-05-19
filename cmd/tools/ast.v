module tools

import cli { Command }
import cotowari.config { new_config }
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
			config := new_config()
			if f := parser.parse_file(cmd.args[0], config) { println(f) } else { println('ERROR') }
			return
		}
	}
)
