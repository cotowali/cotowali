// Copyright (c) 2021 zakuro <z@kuro.red>. All rights reserved.
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
module interpreter

import cotowali.ast
import cotowali.util { li_panic }

fn (e &Interpreter) var_(v ast.Var) Value {
	return *e.scope.lookup_var(v.name())
}

fn (mut e Interpreter) assign_stmt(node ast.AssignStmt) {
	e.assign(node.left, node.right, node.is_decl)
}

fn (mut e Interpreter) destructuring_assign(left ast.ParenExpr, right ast.Expr, is_decl bool) {
	todo(@FN, @FILE, @LINE)
}

fn (mut e Interpreter) index_assign(left ast.Expr, index ast.Expr, right ast.Expr) {
	todo(@FN, @FILE, @LINE)
}

fn (mut e Interpreter) assign(left ast.Expr, right ast.Expr, is_decl bool) {
	match left {
		ast.IndexExpr {
			e.index_assign(left.left, left.index, right)
		}
		ast.ParenExpr {
			e.destructuring_assign(left, right, is_decl)
		}
		ast.Var {
			if is_decl {
				e.scope.register_var(left.name(), e.expr(right))
			} else {
				e.scope.set_var(left.name(), e.expr(right))
			}
		}
		else {
			li_panic(@FN, @FILE, @LINE, 'invalid left of assign')
		}
	}
}
