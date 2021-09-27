// Copyright (c) 2021 zakuro <z@kuro.red>. All rights reserved.
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
module main

import os
import cotowali.context { Context }

struct Lish {
	ctx &Context
	sh  string
}

fn new_lish(sh string, ctx &Context) Lish {
	return Lish{
		ctx: ctx
		sh: sh
	}
}

fn (lish &Lish) welcome() {
	println('Welcome to lish (Cotowali interactive shell)')
}

fn (lish &Lish) new_sh_process() ?&os.Process {
	mut sh := os.new_process(os.find_abs_path_of_executable(lish.sh) or {
		return error('command not found: $lish.sh')
	})

	sh.set_redirect_stdio()
	return sh
}

fn (mut lish Lish) run() ? {
	lish.welcome()

	mut sh := lish.new_sh_process() ?
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
