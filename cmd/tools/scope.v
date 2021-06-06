module tools

import cli { Command }
import cotowari.context { new_default_context }
import cotowari.parser

const (
	scope_command = Command{
		name: 'scope'
		description: 'print scope'
		execute: fn (cmd Command) ? {
			if cmd.args.len != 1 {
				cmd.execute_help()
				return
			}
			if f := parser.parse_file(cmd.args[0], new_default_context()) {
				println(f.scope.debug_str())
			} else {
				println('ERROR')
			}
			return
		}
	}
)
