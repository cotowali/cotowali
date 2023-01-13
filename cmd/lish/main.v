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
import cotowali.context { Context }
import cotowali.shell { new_shell }
import cotowali.util { li_panic }

const (
	sh_flag = Flag{
		flag: .string
		name: 'sh'
		default_value: ['sh']
		global: true
	}
	flags = cmdutil.flags.extends(sh_flag)
)

fn new_ctx_from_cmd(cmd Command) &Context {
	mut ctx := cmdutil.new_ctx_from_cmd(cmd)
	ctx.config.feature.set(.interactive)
	return ctx
}

fn execute(cmd Command) ! {
	sh := cmd.flags.get_string(sh_flag.name) or { li_panic(@FN, @FILE, @LINE, '') }
	mut lish := new_shell(sh, new_ctx_from_cmd(cmd)) or {
		eprintln(err.msg())
		exit(1)
	}
	lish.run()
	exit(lish.exit_code())
}

fn main() {
	mod := vmod.decode(@VMOD_FILE) or { panic(err) }
	mut app := Command{
		name: 'lish'
		description: 'Cotowali interactive shell'
		version: mod.version
		execute: execute
		flags: flags
	}
	app.setup()
	app.parse(os.args)
}
