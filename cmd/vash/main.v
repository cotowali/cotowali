module main

import os
import cli { Command }
import v.vmod
import vash.compiler { new_compiler }
import vash.source
import cmd.tools

fn execute(cmd Command) ? {
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
				s := source.read_file(cmd.args[1]) ?
				c := new_compiler(s)
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
		s := source.read_file(cmd.args[0]) ?
		c := new_compiler(s)
		println(c.compile())
	}
}

fn main() {
	mod := vmod.decode(@VMOD_FILE) or { panic(err) }
	mut app := Command{
		name: mod.name
		description: mod.description
		version: mod.version
		execute: execute
		commands: [tools.command]
	}
	app.setup()
	app.parse(os.args)
}
