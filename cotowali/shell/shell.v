// Copyright (c) 2021 zakuro <z@kuro.red>. All rights reserved.
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
module shell

import os
import cotowali.context { Context }

pub struct Shell {
	ctx &Context
	sh  string
}

pub fn new_shell(sh string, ctx &Context) Shell {
	return Shell{
		ctx: ctx
		sh: sh
	}
}

fn (shell &Shell) new_sh_process() ?&os.Process {
	mut sh := os.new_process(os.find_abs_path_of_executable(shell.sh) or {
		return error('command not found: $shell.sh')
	})

	sh.set_redirect_stdio()
	return sh
}
