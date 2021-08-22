// Copyright (c) 2021 zakuro <z@kuro.red>. All rights reserved.
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
import os
import cli { Command }
import v.vmod
import kuqi

fn execute(cmd Command) ? {
	mut qi := kuqi.new(&Stdio{})
	qi.serve()
	return
}

fn main() {
	mod := vmod.decode(@VMOD_FILE) or { panic(err) }

	mut app := Command{
		name: 'Kuqi'
		description: 'Kuqi - language server for cotowali'
		version: mod.version
		execute: execute
	}
	app.setup()
	app.parse(os.args)
}
