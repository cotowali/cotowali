module devtools

import cli { Command }

pub const (
	command = Command {
		name: 'devtools'
		description: 'development tools'
		execute: fn (cmd Command) ? {
			cmd.execute_help()
			return
		}
	}
)
