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
	e.writeln('try')
	e.writeln('{')

	e.writeln('')
	e.stmts(f.stmts)
	e.writeln('')

	e.writeln('}')
	e.writeln('catch [$pwsh.base_exception_class]')
	e.writeln('{')
	e.indent()
	{
		e.writeln('[Console]::Error.WriteLine(\$_)')
		e.writeln('exit 1')
	}
	e.unindent()
	e.writeln('}')
	e.writeln('')
}

const base_exception_class = 'CotowaliExecption'

fn (mut e Emitter) builtin() {
	e.writeln('
class $pwsh.base_exception_class: Exception
{
	[int] \$Line

	${pwsh.base_exception_class}([int]\$line)
		: base("LINE \${line}: Cotowali Error")
	{
		\$this.Line = \$line
	}

	${pwsh.base_exception_class}([int]\$line, [string]\$msg)
		: base("LINE \${line}: \$msg")
	{
		\$this.Line = \$line
	}

	[string]ToString() {
		return \$this.Message
	}
}
')
	e.define_assertion_error_class()

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
