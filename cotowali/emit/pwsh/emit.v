// Copyright (c) 2021 zakuro <z@kuro.red>. All rights reserved.
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
module pwsh

import cotowali.ast { File }
import cotowali.util { must_write }

pub fn (mut e Emitter) emit(f &File) {
	if e.ctx.config.feature.has(.shebang) {
		must_write(mut &e.out, e.ctx.config.backend.shebang() + '\n\n')
	}

	e.builtin()
	e.file(f)
	must_write(mut &e.out, e.code.bytes())
}

fn (mut e Emitter) file(f &File) {
	e.writeln('# file: $f.source.path')
	e.stmts(f.stmts)
}

fn (mut e Emitter) builtin() {
	e.writeln(r'
function read() {
	# read ($original_input) ([ref]$a) ([ref]$b)
  $original_input = $args[0]
  $ok = $original_input.MoveNext()
  if ($ok) {
    $i = 0
    foreach($v in @($original_input.Current)) {
      $args[$i + 1].Value=$v;
      $i++
    }
  }
  return $ok
}
')
}
