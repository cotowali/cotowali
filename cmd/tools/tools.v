// Copyright (c) 2021 zakuro <z@kuro.red>. All rights reserved.
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
module tools

import cli { Command }

pub const (
	command = Command{
		name: 'tools'
		description: 'tools'
		execute: fn (cmd Command) ? {
			cmd.execute_help()
			return
		}
		commands: [tokens_command, ast_command, scope_command]
	}
)
