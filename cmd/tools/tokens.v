// Copyright (c) 2021 zakuro <z@kuro.red>. All rights reserved.
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
module tools

import cli { Command }
import strings
import cotowali.context { new_default_context }
import cotowali.lexer { new_lexer }
import cotowali.source

const (
	tokens_command = Command{
		name: 'tokens'
		description: 'print tokens'
		execute: fn (cmd Command) ? {
			if cmd.args.len == 0 {
				cmd.execute_help()
				return
			}
			print_files_tokens(cmd.args)
			return
		}
	}
)

fn print_files_tokens(paths []string) {
	mut sb := strings.new_builder(100)
	sb.writeln('[')
	for path in paths {
		sb.writeln(path)
		s := source.read_file(path) or {
			sb.writeln('    ERROR')
			continue
		}
		for token in new_lexer(s, new_default_context()) {
			sb.writeln('    ${token.short_str()}')
		}
	}
	sb.writeln(']')
	println(sb.str())
}
