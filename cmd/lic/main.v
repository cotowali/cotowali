// Copyright (c) 2021 zakuro <z@kuro.red>. All rights reserved.
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
module main

import os
import cli { Command, Flag }
import v.vmod
import cmd.cmdutil
import cotowali { compile }
import cotowali.config { Config }
import cotowali.context { Context }
import cotowali.errors { PrettyFormatter }
import cotowali.util { li_panic }
import cmd.tools

const (
	no_emit_flag = Flag{
		flag: .bool
		name: 'no-emit'
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
	flags = cmdutil.flags.extends(no_emit_flag, test_flag, no_shebang_flag, warn_flag)
)

fn new_ctx_from_cmd(cmd Command) &Context {
	mut ctx := cmdutil.new_ctx_from_cmd(cmd)

	no_emit := cmd.flags.get_bool(no_emit_flag.name) or { li_panic(@FN, @FILE, @LINE, '') }
	is_test := cmd.name == 'test' || cmd.flags.get_bool(test_flag.name) or {
		li_panic(@FN, @FILE, @LINE, '')
	}

	no_shebang := cmd.flags.get_bool(no_shebang_flag.name) or {
		li_panic(@FN, @FILE, @LINE, '') //
	}
	if no_shebang {
		ctx.config.feature.clear(.shebang)
	}

	warns := cmd.flags.get_strings(warn_flag.name) or { li_panic(@FN, @FILE, @LINE, '') }
	for warn_str in warns {
		ctx.config.feature.set_by_str('warn_${warn_str}') or {
			eprintln(err)
			exit(1)
		}
	}

	ctx.config = Config{
		...ctx.config
		no_emit: no_emit
		is_test: is_test
	}
	return ctx
}

fn execute_run_or_test(cmd Command) ? {
	ctx := new_ctx_from_cmd(cmd)
	s, args := cmdutil.parse_args(cmd.args) or {
		eprintln(err)
		exit(1)
	}
	code := cotowali.run(s, args, ctx) or {
		eprint(ctx.errors.format(PrettyFormatter{}))
		exit(1)
	}
	exit(code)
}

fn execute_compile(cmd Command) ? {
	ctx := new_ctx_from_cmd(cmd)
	s := cmdutil.new_source_from_args(cmd.args) or {
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
