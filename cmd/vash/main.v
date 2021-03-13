module main

import os
import cli { Command }
import v.vmod
import vash.compiler { new_file_compiler }
import cmd.dev

fn execute_compile(cmd Command) ? {
	if cmd.args.len == 0 {
		cmd.execute_help()
		return none
	}

	is_run := cmd.args[0] == 'run'
	if is_run {
		if cmd.args.len != 2 {
			cmd.execute_help()
			return none
		}
		c := new_file_compiler(cmd.args[1]) ?
		c.run() ?
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
		commands: [dev.command]
	}
	app.setup()
	app.parse(os.args)
}
