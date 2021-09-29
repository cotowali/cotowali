// Copyright (c) 2021 zakuro <z@kuro.red>. All rights reserved.
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
module main

import os
import cli { Command, Flag }
import v.vmod
import cotowali.config { backend_from_str, default_feature }
import cotowali.context { Context, new_context }
import cotowali.errors { unreachable }
import cotowali.shell { new_shell }

const (
	backend_flag = Flag{
		flag: .string
		name: 'backend'
		abbrev: 'b'
		default_value: ['sh']
		global: true
	}
	sh_flag = Flag{
		flag: .string
		name: 'sh'
		default_value: ['sh']
		global: true
	}
	flags = [backend_flag, sh_flag]
)

fn new_ctx_from_cmd(cmd Command) &Context {
	backend_str := cmd.flags.get_string(backend_flag.name) or { panic(unreachable('')) }
	backend := backend_from_str(backend_str) or {
		eprintln(err)
		exit(1)
	}

	mut feature := default_feature()
	feature.set(.interactive)
	return new_context(backend: backend, feature: feature)
}

fn execute(cmd Command) ? {
	sh := cmd.flags.get_string(sh_flag.name) or { panic(unreachable('')) }
	mut lish := new_shell(sh, new_ctx_from_cmd(cmd)) or {
		eprintln(err.msg)
		exit(1)
	}
	lish.run()
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
