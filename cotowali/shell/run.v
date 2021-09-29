// Copyright (c) 2021 zakuro <z@kuro.red>. All rights reserved.
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
module shell

import strings

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
	for shell.is_alive() {
		prompt := if sb.len == 0 { '>' } else { '...' }
		if input := shell.input('$prompt ') {
			s := input.trim_space()
			sb.writeln(s)
			if !s.ends_with(r'\') {
				shell.execute_compiled_code(sb.str())
			}
		} else {
			println('')
			break
		}
	}
}
