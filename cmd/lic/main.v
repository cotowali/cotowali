// Copyright (c) 2021 zakuro <z@kuro.red>. All rights reserved.
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
module main

import os
import cli { Command, Flag }
import v.vmod
import cotowali { compile }
import cotowali.config { backend_from_str, default_feature }
import cotowali.context { Context, new_context }
import cotowali.source { Source }
import cotowali.messages { unreachable }
import cotowali.errors { PrettyFormatter }
import cmd.tools

const (
	backend_flag = Flag{
		flag: .string
		name: 'backend'
		abbrev: 'b'
		default_value: ['sh']
		global: true
	}
	no_emit_flag = Flag{
		flag: .bool
		name: 'no-emit'
		global: true
	}
	no_std_flag = Flag{
		flag: .bool
		name: 'no-std'
		global: true
	}
	no_shebang_flag = Flag{
		flag: .bool
		name: 'no-shebang'
		global: true
	}
	warn_flag = Flag{
		flag: .string_array
		name: 'warn'
		abbrev: 'W'
		global: true
	}
	flags = [backend_flag, no_emit_flag, no_std_flag, no_shebang_flag, warn_flag]
)

fn new_source_from_args(args []string) ?&Source {
	match args.len {
		0 {
			return &Source{
				path: 'stdin'
				code: os.get_raw_lines_joined()
			}
		}
		1 {
			return source.read_file(args[0])
		}
		else {
			return error('too many source files')
		}
	}
}

fn new_ctx_from_cmd(cmd Command) &Context {
	no_emit := cmd.flags.get_bool(no_emit_flag.name) or { panic(unreachable('')) }
	no_std := cmd.flags.get_bool(no_std_flag.name) or { panic(unreachable('')) }

	backend_str := cmd.flags.get_string(backend_flag.name) or { panic(unreachable('')) }
	backend := backend_from_str(backend_str) or {
		eprintln(err)
		exit(1)
	}

	mut feature := default_feature()
	no_shebang := cmd.flags.get_bool(no_shebang_flag.name) or { panic(unreachable('')) }
	if no_shebang {
		feature.clear(.shebang)
	}
	warns := cmd.flags.get_strings(warn_flag.name) or { panic(unreachable('')) }
	for warn_str in warns {
		feature.set_by_str('warn_$warn_str') or {
			eprintln(err)
			exit(1)
		}
	}

	return new_context(no_emit: no_emit, no_std: no_std, backend: backend, feature: feature)
}

fn execute_run(cmd Command) ? {
	mut ctx := new_ctx_from_cmd(cmd)
	s := new_source_from_args(cmd.args) or {
		eprintln(err)
		exit(1)
	}
	cotowali.run(s, ctx) or {
		eprint(ctx.errors.format(PrettyFormatter{}))
		exit(1)
	}
}

fn execute_compile(cmd Command) ? {
	mut ctx := new_ctx_from_cmd(cmd)
	s := new_source_from_args(cmd.args) or {
		eprintln(err)
		exit(1)
	}
	out := compile(s, ctx) or {
		eprint(ctx.errors.format(PrettyFormatter{}))
		exit(1)
	}
	print(out)
}

fn main() {
	mod := vmod.decode(@VMOD_FILE) or { panic(err) }
	mut app := Command{
		name: 'lic'
		description: mod.description
		version: mod.version
		execute: execute_compile
		flags: flags
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
