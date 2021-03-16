module main

import os
import cli { Command }
import v.vmod
import vash.compiler { new_file_compiler, new_compiler }
import cmd.tools

fn execute_compile(cmd Command) ? {
	if cmd.args.len == 0 {
		cmd.execute_help()
		return none
	}

	is_run := cmd.args[0] == 'run'
	if is_run {
		match cmd.args.len {
			1 {
				c := new_compiler(path: 'stdin', code: os.get_raw_lines_joined())
				c.run() ?
			}
			2 {
				c := new_file_compiler(cmd.args[1]) ?
				c.run() ?
			}
			else {
				cmd.execute_help()
				return none
			}
		}
	} else {
		if cmd.args.len != 1 {
			cmd.execute_help()
			return none
		}
		c := new_file_compiler(cmd.args[0]) ?
		c.compile_to_stdout()
	}
}

fn main() {
	mod := vmod.decode(@VMOD_FILE) or { panic(err) }
	mut app := Command{
		name: mod.name
		description: mod.description
		version: mod.version
		sort_flags: false
		sort_commands: false
		execute: execute_compile
		commands: [tools.command]
	}
	app.setup()
	app.parse(os.args)
}
