// Copyright (c) 2021 zakuro <z@kuro.red>. All rights reserved.
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
module shell

import strings
import os
import cotowali { compile }
import cotowali.source { Source }
import cotowali.errors { PrettyFormatter }

fn (shell &Shell) welcome() {
	println('Welcome to lish (Cotowali interactive shell)')
}

fn (mut shell Shell) execute_compiled_code(code string) {
	shell.stdin_write(code)
	mut stdout := shell.stdout_read()
	if stdout.len > 0 {
		print(stdout)
	}
	mut stderr := shell.stderr_read()
	if stderr.len > 0 {
		eprint(stderr)
	}
}

pub fn (mut shell Shell) run() {
	shell.welcome()

	shell.start()
	defer {
		shell.close()
	}

	mut sb := strings.new_builder(20)
	source_path := os.join_path(os.getwd(), 'lish')
	for shell.is_alive() {
		prompt := if sb.len == 0 { '>' } else { '...' }
		if input := shell.input('$prompt ') {
			s := input.trim_space()
			sb.writeln(s)
			if !s.ends_with(r'\') {
				source := &Source{
					path: source_path
					code: sb.str()
				}
				compiled_code := compile(source, shell.ctx) or {
					eprint(shell.ctx.errors.format(PrettyFormatter{}))
					shell.ctx.errors.clear()
					continue
				}
				shell.execute_compiled_code(compiled_code)
			}
		} else {
			println('')
			break
		}
	}
}
