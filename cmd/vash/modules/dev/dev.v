module dev

import cli { Command }

const (
	tokens = Command {
		name: 'tokens'
		description: 'print tokens'
		execute: fn (cmd Command) ? {
			cmd.execute_help()
			return
		}
	}
)

pub const (
	command = Command {
		name: 'dev'
		description: 'development tools'
		execute: fn (cmd Command) ? {
			cmd.execute_help()
			return
		}
		commands: [tokens]
	}
)
