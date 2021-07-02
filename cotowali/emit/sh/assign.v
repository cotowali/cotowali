module sh

import cotowali.ast
import cotowali.symbols { TypeSymbol }

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

fn (mut e Emitter) assign(name string, value ExprOrString, ts TypeSymbol) {
	if ts.kind() == .array {
		e.array_assign(name, value)
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
	if node.left is ast.IndexExpr {
		name := e.ident_for(node.left.left)
		e.write('array_set $name ')
		e.expr(node.left.index, {})
		e.write(' ')
		e.expr(node.right, writeln: true)
	} else {
		e.assign(e.ident_for(node.left), node.right, node.left.type_symbol())
	}
}
