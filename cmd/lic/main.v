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
import cotowali.errors { PrettyFormatter }
import cotowali.util { li_panic }
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
	no_builtin_flag = Flag{
		flag: .bool
		name: 'no-builtin'
		global: true
	}
	test_flag = Flag{
		flag: .bool
		name: 'test'
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
	define_flag = Flag{
		flag: .string_array
		name: 'define'
		abbrev: 'd'
		description: '<name>=[<value>] define compiler variable'
		global: true
	}
	flags = [
		backend_flag,
		no_emit_flag,
		no_builtin_flag,
		test_flag,
		no_shebang_flag,
		warn_flag,
		define_flag,
	]
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
	no_emit := cmd.flags.get_bool(no_emit_flag.name) or { li_panic(@FILE, @LINE, '') }
	no_builtin := cmd.flags.get_bool(no_builtin_flag.name) or { li_panic(@FILE, @LINE, '') }
	is_test := cmd.name == 'test' || cmd.flags.get_bool(test_flag.name) or {
		li_panic(@FILE, @LINE, '')
	}

	backend_str := cmd.flags.get_string(backend_flag.name) or { li_panic(@FILE, @LINE, '') }
	backend := backend_from_str(backend_str) or {
		eprintln(err)
		exit(1)
	}

	mut feature := default_feature()
	no_shebang := cmd.flags.get_bool(no_shebang_flag.name) or { li_panic(@FILE, @LINE, '') }
	if no_shebang {
		feature.clear(.shebang)
	}
	warns := cmd.flags.get_strings(warn_flag.name) or { li_panic(@FILE, @LINE, '') }
	for warn_str in warns {
		feature.set_by_str('warn_$warn_str') or {
			eprintln(err)
			exit(1)
		}
	}

	mut ctx := new_context(
		no_emit: no_emit
		no_builtin: no_builtin
		is_test: is_test
		backend: backend
		feature: feature
	)
	defines := cmd.flags.get_strings(define_flag.name) or { li_panic(@FILE, @LINE, '') }
	for define in defines {
		parts := define.split_nth('=', 2)
		match parts.len {
			1 { ctx.compiler_symbols.define(parts[0]) }
			2 { ctx.compiler_symbols.define_with_value(parts[0], parts[1]) }
			else { li_panic(@FILE, @LINE, '') }
		}
	}

	return ctx
}

fn execute_run_or_test(cmd Command) ? {
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
				execute: execute_run_or_test
			},
			Command{
				name: 'test'
				description: 'execute tests'
				execute: execute_run_or_test
			},
			tools.command,
		]
	}
	app.setup()
	app.parse(os.args)
}
