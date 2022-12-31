// Copyright (c) 2021 zakuro <z@kuro.red>. All rights reserved.
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
module sh

import cotowali.ast
import cotowali.util { must_write }

pub fn (mut e Emitter) emit(f &ast.File) {
	if e.ctx.config.feature.has(.shebang) {
		must_write(mut &e.out, e.ctx.config.backend.shebang() + '\n\n')
	}

	e.builtin()
	e.file(f)
	for k in ordered_code_kinds {
		must_write(mut &e.out, e.codes[k].bytes())
	}
}

fn (mut e Emitter) file(f &ast.File) {
	e.writeln('# file: ${f.source.path}')
	e.stmts(f.stmts)
}
