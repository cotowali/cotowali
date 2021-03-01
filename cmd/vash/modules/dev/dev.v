module dev

import cli { Command }

pub const (
	command = Command {
		name: 'dev'
		description: 'development tools'
		execute: fn (cmd Command) ? {
			cmd.execute_help()
			return
		}
	}
)
