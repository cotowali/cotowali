// Copyright (c) 2021 zakuro <z@kuro.red>. All rights reserved.
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
module cmdutil

import os
import cli { Command, Flag }
import cotowali.config { backend_from_str, default_feature }
import cotowali.context { Context, new_context }
import cotowali.source { Source }
import cotowali.util { li_panic }

const (
	backend_flag = Flag{
		flag: .string
		name: 'backend'
		abbrev: 'b'
		default_value: ['sh']
		global: true
	}
	no_builtin_flag = Flag{
		flag: .bool
		name: 'no-builtin'
		global: true
	}
	define_flag = Flag{
		flag: .string_array
		name: 'define'
		abbrev: 'd'
		description: '<name>=[<value>] define compiler variable'
		global: true
	}
)

pub const common_flags = [
	backend_flag,
	no_builtin_flag,
	define_flag,
]

pub fn parse_args(args []string) ?(&Source, []string) {
	if args.len == 0 {
		return &Source{
			path: 'stdin'
			code: os.get_raw_lines_joined()
		}, []string{}
	}
	s := source.read_file(args[0]) ?
	return s, args[1..]
}

pub fn new_source_from_args(args []string) ?&Source {
	s, rest := parse_args(args) ?
	if rest.len > 0 {
		return error('too many source files')
	}
	return s
}

pub fn new_ctx_from_cmd(cmd Command) &Context {
	no_builtin := cmd.flags.get_bool(cmdutil.no_builtin_flag.name) or {
		li_panic(@FN, @FILE, @LINE, '')
	}
	backend_str := cmd.flags.get_string(cmdutil.backend_flag.name) or {
		li_panic(@FN, @FILE, @LINE, '')
	}
	backend := backend_from_str(backend_str) or {
		eprintln(err)
		exit(1)
	}

	mut ctx := new_context(
		no_builtin: no_builtin
		backend: backend
		feature: default_feature()
	)
	defines := cmd.flags.get_strings(cmdutil.define_flag.name) or {
		li_panic(@FN, @FILE, @LINE, '')
	}
	for define in defines {
		parts := define.split_nth('=', 2)
		match parts.len {
			1 { ctx.compiler_symbols.define(parts[0]) }
			2 { ctx.compiler_symbols.define_with_value(parts[0], parts[1]) }
			else { li_panic(@FN, @FILE, @LINE, '') }
		}
	}

	return ctx
}
