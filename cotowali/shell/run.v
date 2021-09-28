// Copyright (c) 2021 zakuro <z@kuro.red>. All rights reserved.
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
module shell

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

	for shell.is_alive() {
		if s := shell.input('> ') {
			shell.execute_compiled_code(s)
		} else {
			println('')
			break
		}
	}
}
