module main

import os
import cli { Command }
import v.vmod
import vash.compiler { new_file_compiler }
import devtools

fn execute_compile(cmd Command) ? {
	for f in cmd.args {
		c := new_file_compiler(f) ?
		c.compile_to_stdout() ?
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
		required_args: 1
		execute: execute_compile
		commands: [devtools.command]
	}
	app.setup()
	app.parse(os.args)
}
