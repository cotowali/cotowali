// Copyright (c) 2021 zakuro <z@kuro.red>. All rights reserved.
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
module sh

import cotowali.ast
import cotowali.symbols { TypeSymbol }
import cotowali.messages { unreachable }

fn (mut e Emitter) array_assign(name string, value ExprOrString) {
	// v bug: `match value` occurs c error at `e.ident_for`
	if value is string {
		e.writeln('array_copy "$name" "$value"')
	} else {
		expr := value as ast.Expr
		match expr {
			ast.ArrayLiteral {
				if expr.is_init_syntax {
					e.write('array_init "$name" ')
					e.expr(expr.len)
					e.write(' ')
					e.expr(expr.init)
				} else {
					e.write('array_assign "$name"')
					for elem in expr.elements {
						e.write(' ')
						e.expr(elem)
					}
				}
				e.writeln('')
			}
			ast.Var {
				ident := e.ident_for(ast.Expr(expr))
				e.array_assign(name, ident)
			}
			ast.DefaultValue {
				e.writeln('array_init "$name" 0')
			}
			ast.StringLiteral {
				$if !prod {
					if !expr.is_glob() {
						panic(unreachable('not a array value'))
					}
				}
				e.write('array_copy "$name" ')
				e.string_literal(expr)
				e.writeln('')
			}
			else {
				panic(unreachable('not a array value'))
			}
		}
	}
}

fn (mut e Emitter) map_assign(name string, value ExprOrString) {
	e.write('map_copy ')
	e.map(name)
	e.write(' ')
	match value {
		string {
			e.map(value)
			e.writeln('')
		}
		ast.Expr {
			e.expr(value, writeln: true)
		}
	}
}

fn (mut e Emitter) fn_assign(name string, value ExprOrString) {
	e.sh_define_function(name, fn (mut e Emitter, value ExprOrString) {
		target := if value is string { value } else { e.ident_for(value as ast.Expr) }
		e.writeln(target + r' "$@"') // passthrough arguments
	}, value)
}

fn (mut e Emitter) assign(name string, value ExprOrString, ts TypeSymbol) {
	match ts.resolved().kind() {
		.array {
			e.array_assign(name, value)
		}
		.map {
			e.map_assign(name, value)
		}
		.function {
			e.fn_assign(name, value)
		}
		else {
			match value {
				string {
					e.writeln('$name="$value"')
				}
				ast.Expr {
					e.write('$name=')
					e.expr(value)
					e.writeln('')
				}
			}
		}
	}
}

fn (mut e Emitter) destructuring_assign(names []string, expr ast.Expr) {
	tuple_info := expr.type_symbol().tuple_info() or {
		panic(unreachable('destrucuturing not tuple value'))
	}
	e.write('set -- ')
	e.expr(expr, writeln: true, quote: false)
	for i, name in names {
		ts := expr.scope().must_lookup_type(tuple_info.elements[i].typ)
		e.assign(name, '\$${i + 1}', ts)
	}
}

fn (mut e Emitter) index_assign(left ast.Expr, index ast.Expr, right ast.Expr) {
	name := e.ident_for(left)
	e.write(match left.type_symbol().resolved().kind() {
		.array { 'array_set $name ' }
		.map { 'map_set $name ' }
		else { panic(unreachable('invalid index left')) }
	})
	e.expr(index)
	e.write(' ')
	e.expr(right, writeln: true)
}

fn (mut e Emitter) assign_stmt(node ast.AssignStmt) {
	match node.left {
		ast.IndexExpr {
			e.index_assign(node.left.left, node.left.index, node.right)
		}
		ast.ParenExpr {
			e.destructuring_assign(node.left.exprs.map(e.ident_for(it)), node.right)
		}
		else {
			e.assign(e.ident_for(node.left), node.right, node.left.type_symbol())
		}
	}
}
