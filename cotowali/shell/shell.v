// Copyright (c) 2021 zakuro <z@kuro.red>. All rights reserved.
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
module shell

import os
import readline { Readline }
import cotowali.context { Context }
import cotowali.util { nil_to_none }

pub struct Shell {
mut:
	ctx             &Context
	backend_process &os.Process = 0
	readline        Readline
}

fn new_sh_process(command string) ?&os.Process {
	mut p := os.new_process(os.find_abs_path_of_executable(command) or {
		return error('command not found: $command')
	})

	p.set_redirect_stdio()
	return p
}

pub fn new_shell(sh string, ctx &Context) ?Shell {
	return Shell{
		ctx: ctx
		backend_process: new_sh_process(sh)?
	}
}

fn (shell &Shell) backend_process() ?&os.Process {
	return nil_to_none(shell.backend_process)
}

pub fn (mut shell Shell) is_alive() bool {
	mut p := shell.backend_process() or { return false }
	return p.is_alive()
}

pub fn (mut shell Shell) start() {
	mut p := shell.backend_process() or { return }
	p.run()
}

pub fn (mut shell Shell) close() {
	mut p := shell.backend_process() or { return }
	p.close()
}

pub fn (shell &Shell) exit_code() int {
	p := shell.backend_process() or { return -1 }
	return p.code
}

pub fn (mut shell Shell) stdin_write(s string) {
	mut p := shell.backend_process() or { return }
	p.stdin_write(s)
}

fn get_marker() string {
	return '__lish__command__${util.rand<u64>()}__done__'
}

pub fn (mut shell Shell) stdout_read() string {
	mut p := shell.backend_process() or { return '' }

	// by printing marker, wait to complete command
	done_marker := get_marker()
	p.stdin_write('printf "$done_marker"\n')
	mut out := ''
	for shell.is_alive() && !out.ends_with(done_marker) {
		out += p.stdout_read()
	}
	return out.trim_string_right(done_marker)
}

pub fn (mut shell Shell) stderr_read() string {
	mut p := shell.backend_process() or { return '' }

	// same as stdout_read
	done_marker := get_marker()
	p.stdin_write('printf "$done_marker" >&2 \n')
	mut out := ''
	for shell.is_alive() && !out.ends_with(done_marker) {
		out += p.stderr_read()
	}
	return out.trim_right(done_marker)
}

fn (mut shell Shell) input(prompt string) ?string {
	return shell.readline.read_line(prompt)
}
