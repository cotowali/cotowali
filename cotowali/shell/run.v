// Copyright (c) 2021-2023 zakuro <z@kuro.red>. All rights reserved.
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
module shell

import strings
import os
import cotowali { compile }
import cotowali.context { new_context }
import cotowali.lexer { new_lexer }
import cotowali.source { Source }
import cotowali.errors { PrettyFormatter }

fn (shell &Shell) welcome() {
	println('Welcome to lish (Cotowali interactive shell)')
	println('Type "help" for more information')
}

fn (mut shell Shell) execute_compiled_code(code string) {
	shell.stdin_write(code)
	if !shell.is_alive() {
		return
	}
	mut stdout := shell.stdout_read()
	if stdout.len > 0 {
		print(stdout)
	}
	if !shell.is_alive() {
		return
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

	mut brace_depth := 0
	mut paren_depth := 0
	mut bracket_depth := 0

	for shell.is_alive() {
		prompt := if sb.len == 0 { '>>>' } else { '...' }
		if input := shell.input('${prompt} ') {
			mut s := input.trim_space()

			match s {
				'clear' {
					shell.ctx = new_context(shell.ctx.config)
					continue
				}
				'exit' {
					break
				}
				'help' {
					println([
						'clear\tclear variables, functions, and other environment',
						'exit\texit lish',
						'help\tprint this help message',
					].join('\n'))
					continue
				}
				else {}
			}

			mut is_continue := false
			if s.ends_with(r'\') {
				is_continue = true
				s = s[..s.len - 1]
			}

			lexer := new_lexer(&Source{
				path: source_path
				code: s
			}, shell.ctx)
			for tok in lexer {
				match tok.kind {
					.l_brace { brace_depth += 1 }
					.r_brace { brace_depth -= 1 }
					.l_paren { paren_depth += 1 }
					.r_paren { paren_depth -= 1 }
					.l_bracket { bracket_depth += 1 }
					.r_bracket { bracket_depth -= 1 }
					else {}
				}
			}
			if brace_depth > 0 || paren_depth > 0 || bracket_depth > 0 {
				is_continue = true
			}

			sb.writeln(s)
			if is_continue {
				continue
			}

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
		} else {
			println('')
			break
		}
	}
}
