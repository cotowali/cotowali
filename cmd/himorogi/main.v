// Copyright (c) 2021 zakuro <z@kuro.red>. All rights reserved.
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
module main

import os
import cli { Command }
import v.vmod
import cmd.cmdutil
import cotowali.errors { PrettyFormatter }
import cotowali.himorogi

const (
	flags = cmdutil.flags.excepts(.backend)
)

fn execute(cmd Command) ? {
	mut ctx := cmdutil.new_ctx_from_cmd(cmd, backend: .himorogi)
	ctx.config.no_builtin = true
	s, args := cmdutil.parse_args(cmd.args) or {
		eprintln(err)
		exit(1)
	}
	code := himorogi.run(s, args, ctx) or {
		eprint(ctx.errors.format(PrettyFormatter{}))
		exit(1)
	}
	exit(code)
}

fn main() {
	mod := vmod.decode(@VMOD_FILE) or { panic(err) }
	mut app := Command{
		name: 'himorogi'
		description: 'Yet another cotowali interpreter'
		version: mod.version
		execute: execute
		flags: flags
	}
	app.setup()
	app.parse(os.args)
}
