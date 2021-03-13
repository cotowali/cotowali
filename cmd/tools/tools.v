module tools

import cli { Command }
import strings
import vash.parser
import vash.lexer
import vash.source

pub const (
	command = Command{
		name: 'tools'
		description: 'tools'
		execute: fn (cmd Command) ? {
			cmd.execute_help()
			return
		}
		commands: [tokens_command, ast_command]
	}
)
