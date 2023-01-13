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
import cotowali.util { li_panic }
import cotowali.himorogi

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

	base := '${os.file_name(s.path)}_${ulid()}'
	ext := ctx.config.backend.script_ext()
	temp_path := os.join_path(os.temp_dir(), '${base}${ext}')

	mut f := os.create(temp_path) or { li_panic(@FN, @FILE, @LINE, err) }
	c.compile_to(f)?
	defer {
		f.close()
	}
	return temp_path
}

pub fn run(s Source, args []string, ctx &Context) ?int {
	if ctx.config.backend == .himorogi {
		return himorogi.run(s, args, ctx)
	}

	temp_file := compile_to_temp_file(s, ctx)?
	defer {
		os.rm(temp_file) or { li_panic(@FN, @FILE, @LINE, err) }
	}
	executable := ctx.config.backend.find_executable_path() or {
		eprintln(err.msg())
		exit(1)
	}

	mut p := os.new_process('${executable}')
	p.set_args([temp_file])
	p.args << args
	p.wait()

	return p.code
}
