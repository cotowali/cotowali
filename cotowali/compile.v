// Copyright (c) 2021 zakuro <z@kuro.red>. All rights reserved.
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
module cotowali

import os
import io
import rand { ulid }
import cotowali.context { Context }
import cotowali.source { Source }
import cotowali.compiler { new_compiler }

pub fn compile(s Source, ctx &Context) ?string {
	c := new_compiler(s, ctx)
	return c.compile()
}

pub fn compile_to(w io.Writer, s Source, ctx &Context) ? {
	c := new_compiler(s, ctx)
	return c.compile_to(w)
}

fn compile_to_temp_file(s Source, ctx &Context) ?string {
	c := new_compiler(s, ctx)

	base := '${os.file_name(s.path)}_$ulid()'
	ext := if ctx.config.backend == .powershell { '.ps1' } else { '.sh' }
	temp_path := os.join_path(os.temp_dir(), '${base}.$ext')

	mut f := os.create(temp_path) or { panic(err) }
	c.compile_to(f) ?
	defer {
		f.close()
	}
	return temp_path
}

fn find_backend_executable(ctx Context) ?string {
	cmds := match ctx.config.backend {
		.powershell { ['pwsh', 'pwsh.exe', 'powershell.exe'] }
		.sh { ['sh'] }
		.dash { ['dash'] }
		.bash { ['bash', 'bash.exe'] }
		.zsh { ['zsh'] }
	}
	for cmd in cmds {
		if found := os.find_abs_path_of_executable(cmd) {
			return found
		}
	}
	return error('$ctx.config.backend not found')
}

pub fn run(s Source, ctx &Context) ?int {
	temp_file := compile_to_temp_file(s, ctx) ?
	defer {
		os.rm(temp_file) or { panic(err) }
	}
	executable := find_backend_executable(ctx) or {
		eprintln(err.msg)
		exit(1)
	}

	exit_code := os.system('$executable "$temp_file"')
	return exit_code
}
