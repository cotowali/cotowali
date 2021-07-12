// Copyright (c) 2021 The Cotowali Authors. All rights reserved.
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
module sh

import cotowali.ast
import cotowali.symbols { TypeSymbol }
import cotowali.errors { unreachable }
import cotowali.util { panic_and_value }

fn (mut e Emitter) array_assign(name string, value ExprOrString) {
	match value {
		ast.Expr {
			ident := e.ident_for(value)
			match value {
				ast.ArrayLiteral {
					e.write('array_assign "$name"')
					for elem in value.elements {
						e.write(' ')
						e.expr(elem, as_command: false)
					}
					e.writeln('')
				}
				ast.Var {
					e.array_assign(name, ident)
				}
				else {}
			}
		}
		string {
			e.writeln('array_assign "$name" \$(array_elements "$value")')
		}
	}
}

fn (mut e Emitter) map_assign(name string, value ExprOrString) {
	e.write('map_copy ')
	e.map(name, {})
	e.write(' ')
	match value {
		string {
			e.map(value, {})
			e.writeln('')
		}
		ast.Expr {
			e.expr(value, writeln: true)
		}
	}
}

fn (mut e Emitter) assign(name string, value ExprOrString, ts TypeSymbol) {
	match ts.kind() {
		.array {
			e.array_assign(name, value)
		}
		.map {
			e.map_assign(name, value)
		}
		else {
			match value {
				string {
					e.writeln('$name="$value"')
				}
				ast.Expr {
					e.write('$name=')
					e.expr(value, {})
					e.writeln('')
				}
			}
		}
	}
}

fn (mut e Emitter) assign_stmt(node ast.AssignStmt) {
	if node.left is ast.IndexExpr {
		name := e.ident_for(node.left.left)
		e.write(match node.left.left.type_symbol().kind() {
			.array { 'array_set $name ' }
			.map { 'map_set $name ' }
			else { panic_and_value(unreachable('invalid index left'), '') }
		})
		e.expr(node.left.index, {})
		e.write(' ')
		e.expr(node.right, writeln: true)
	} else {
		e.assign(e.ident_for(node.left), node.right, node.left.type_symbol())
	}
}
