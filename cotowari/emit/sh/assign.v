module sh

import cotowari.ast
import cotowari.symbols { TypeSymbol }
import cotowari.errors { unreachable }

type AssignValue = ast.Expr | string

fn (mut e Emitter) assign(name string, value AssignValue, ts TypeSymbol) {
	if ts.kind() == .array {
		match value {
			ast.Expr {
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
						e.assign(name, value.out_name(), ts)
					}
					else {}
				}
			}
			string {
				e.writeln('array_assign "$name" \$(array_elements "$value")')
			}
		}
		return
	}
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

fn (mut e Emitter) assign_stmt(node ast.AssignStmt) {
	out_name := match node.left {
		ast.Var {
			node.left.out_name()
		}
		else {
			panic(unreachable)
			''
		}
	}
	e.assign(out_name, node.right, node.left.type_symbol())
}
