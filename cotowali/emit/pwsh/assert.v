// Copyright (c) 2021 zakuro <z@kuro.red>. All rights reserved.
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
module pwsh

import cotowali.ast { AssertStmt }

fn (mut e Emitter) assert_stmt(stmt AssertStmt) {
	e.write('if ( -not (')
	e.expr(stmt.args[0])
	e.writeln(') )')

	e.writeln('{')
	e.indent()
	{
		e.write('throw New-Object $pwsh.assertion_error_class -ArgumentList ($stmt.pos.line')
		if msg_expr := stmt.message_expr() {
			e.write(', ')
			e.expr(msg_expr, paren: true)
		}
		e.write(')')
	}
	e.unindent()
	e.writeln('}')
}

const assertion_error_class = 'CotowaliAssertionFailedException'

fn (mut e Emitter) define_assertion_error_class() {
	e.writeln('
class $pwsh.assertion_error_class : $base_exception_class
{
	${pwsh.assertion_error_class}([int]\$line)
		: base(\$line, "Assertion Failed") {}
	${pwsh.assertion_error_class}([int]\$line, [string]\$msg)
		: base(\$line, "Assertion Failed: \$msg") {}
}
')
}
