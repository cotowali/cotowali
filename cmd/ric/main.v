module main

import os
import cli { Command, Flag }
import v.vmod
import cotowari { compile, format_error }
import cotowari.config { Config, backend_from_str, new_config }
import cotowari.source { Source }
import cotowari.errors { unreachable }
import cmd.tools

const backend_flag = Flag{
	flag: .string
	name: 'backend'
	abbrev: 'b'
	default_value: ['sh']
}

fn new_source_to_run(args []string) ?Source {
	if args.len == 0 {
		return Source{
			path: 'stdin'
			code: os.get_raw_lines_joined()
		}
	} else {
		return source.read_file(args[0])
	}
}

fn new_config_from_cmd(cmd Command) &Config {
	mut config := new_config()
	backend_str := cmd.flags.get_string(backend_flag.name) or { panic(unreachable) }
	config.backend = backend_from_str(backend_str) or {
		eprintln(err)
		exit(1)
	}
	return config
}

fn execute_run(cmd Command) ? {
	if cmd.args.len > 1 {
		eprintln('too many source files')
		exit(1)
	}
	s := new_source_to_run(cmd.args) or {
		eprintln(err)
		exit(1)
	}
	config := new_config_from_cmd(cmd)
	cotowari.run(s, config) or {
		eprintln(err)
		exit(1)
	}
}

fn execute_compile(cmd Command) ? {
	if cmd.args.len == 0 {
		eprintln('no source files are passed')
		exit(1)
	} else if cmd.args.len > 1 {
		eprintln('too many source files')
		exit(1)
	}
	s := source.read_file(cmd.args[0]) ?
	config := new_config_from_cmd(cmd)
	out := compile(s, config) or {
		eprint(format_error(err, errors.PrettyFormatter{}))
		exit(1)
	}
	println(out)
}

fn main() {
	mod := vmod.decode(@VMOD_FILE) or { panic(err) }
	mut app := Command{
		name: 'ric'
		description: mod.description
		version: mod.version
		execute: execute_compile
		flags: [backend_flag]
		commands: [
			Command{
				name: 'run'
				description: 'run script'
				execute: execute_run
			},
			tools.command,
		]
	}
	app.setup()
	app.parse(os.args)
}
