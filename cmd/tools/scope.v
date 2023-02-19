// Copyright (c) 2021-2023 zakuro <z@kuro.red>. All rights reserved.
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
module tools

import cli { Command }
import cotowali.context { new_default_context }
import cotowali.parser

const (
	scope_command = Command{
		name: 'scope'
		description: 'print scope'
		execute: fn (cmd Command) ! {
			if cmd.args.len != 1 {
				cmd.execute_help()
				return
			}
			ctx := new_default_context()
			if _ := parser.parse_file(cmd.args[0], ctx) {
				println(ctx.global_scope.debug_str())
			} else {
				println('ERROR')
			}
			return
		}
	}
)
