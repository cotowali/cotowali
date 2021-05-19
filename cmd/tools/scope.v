module tools

import cli { Command }
import cotowari.config { new_config }
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
			config := new_config()
			if f := parser.parse_file(cmd.args[0], config) {
				println(f.scope.debug_str())
			} else {
				println('ERROR')
			}
			return
		}
	}
)
