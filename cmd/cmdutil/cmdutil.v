// Copyright (c) 2021-2023 zakuro <z@kuro.red>
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
module cmdutil

import os
import cli { Command, Flag }
import cotowali.config { Backend, Config, backend_from_str, default_feature }
import cotowali.context { Context, new_context }
import cotowali.source { Source }
import cotowali.util { li_panic }

pub const (
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

pub type Flags = []Flag

pub fn (flags Flags) array() []Flag {
	return flags
}

pub fn (flags Flags) extends(extra_flags ...Flag) Flags {
	mut res := flags
	res << extra_flags
	return res
}

pub fn (flags Flags) excepts(excepts ...FlagKind) Flags {
	except_names := excepts.map(cmdutil.flags_map[it].name)
	return flags.array().filter(it.name !in except_names)
}

[flag]
pub enum FlagKind {
	backend
	no_builtin
	define
}

const (
	flags_map = {
		FlagKind.backend:    Flag{
			flag: .string
			name: 'backend'
			abbrev: 'b'
			default_value: ['sh']
			global: true
		}
		FlagKind.no_builtin: Flag{
			flag: .bool
			name: 'no-builtin'
			global: true
		}
		FlagKind.define:     Flag{
			flag: .string_array
			name: 'define'
			abbrev: 'd'
			description: '<name>=[<value>] define compiler variable'
			global: true
		}
	}
)

pub const (
	flags = Flags(flags_map.keys().map(flags_map[it]))
)

pub fn parse_args(args []string) !(&Source, []string) {
	if args.len == 0 {
		return &Source{
			path: 'stdin'
			code: os.get_raw_lines_joined()
		}, []string{}
	}
	s := source.read_file(args[0])!
	return s, args[1..]
}

pub fn new_source_from_args(args []string) !&Source {
	s, rest := parse_args(args)!
	if rest.len > 0 {
		return error('too many source files')
	}
	return s
}

pub fn process_define_flag(cmd Command, mut ctx Context) {
	defines := cmd.flags.get_strings(cmdutil.flags_map[.define].name) or { return }
	for define in defines {
		parts := define.split_nth('=', 2)
		match parts.len {
			1 { ctx.compiler_symbols.define(parts[0]) }
			2 { ctx.compiler_symbols.define_with_value(parts[0], parts[1]) }
			else { li_panic(@FN, @FILE, @LINE, '') }
		}
	}
}

pub fn get_backend(cmd Command) ?Backend {
	backend_str := cmd.flags.get_string(cmdutil.flags_map[.backend].name) or { return none }
	backend := backend_from_str(backend_str) or {
		eprintln(err)
		exit(1)
	}
	return backend
}

pub fn get_no_builtin(cmd Command) bool {
	return cmd.flags.get_bool(cmdutil.flags_map[.no_builtin].name) or { return false }
}

pub fn new_ctx_from_cmd(cmd Command, default_config Config) &Context {
	mut config := Config{
		...default_config
		no_builtin: get_no_builtin(cmd)
		feature: default_feature()
	}
	if backend := get_backend(cmd) {
		config.backend = backend
	}
	mut ctx := new_context(config)
	process_define_flag(cmd, mut ctx)
	return ctx
}
