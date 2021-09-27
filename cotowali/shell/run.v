// Copyright (c) 2021 zakuro <z@kuro.red>. All rights reserved.
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
module shell

import os

fn (shell &Shell) welcome() {
	println('Welcome to shell (Cotowali interactive shell)')
}

pub fn (mut shell Shell) run() ? {
	shell.welcome()

	mut sh := shell.new_sh_process() ?
	sh.run()
	defer {
		sh.close()
	}

	for sh.is_alive() {
		if s := os.input_opt('> ') {
			sh.stdin_write(s + '\n')

			// stdou_read() blocks until found 1 or more output.
			// To avoid this problem, print extra character, then trim it.
			sh.stdin_write('printf ":"\n')
			mut stdout := sh.stdout_read()
			stdout = stdout[..stdout.len - 1]
			if stdout.len > 0 {
				println(stdout)
			}

			// same as stdout
			sh.stdin_write('printf ":" >&2 \n')
			mut stderr := sh.stderr_read()
			stderr = stderr[..stderr.len - 1]
			if stderr.len > 0 {
				println(stderr)
			}
		} else {
			println('')
			break
		}
	}
}
