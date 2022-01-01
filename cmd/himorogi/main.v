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
import cotowali.errors { PrettyFormatter }
import cotowali.context { new_context }
import cotowali.himorogi

const (
	flags = []Flag{}
)

fn execute(cmd Command) ? {
	ctx := new_context(backend: .himorogi)
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
