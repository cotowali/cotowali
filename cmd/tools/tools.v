module tools

import cli { Command }

pub const (
	command = Command{
		name: 'tools'
		description: 'tools'
		execute: fn (cmd Command) ? {
			cmd.execute_help()
			return
		}
		commands: [tokens_command, ast_command, scope_command]
	}
)
