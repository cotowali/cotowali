// Copyright (c) 2021 zakuro <z@kuro.red>. All rights reserved.
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
module sh

import cotowali.ast { ArrayLiteral, Expr, FnDecl, MapLiteral }
import cotowali.symbols
import cotowali.errors { unreachable }
import cotowali.util { panic_and_value }

type IdentForValue = ArrayLiteral | Expr | FnDecl | MapLiteral | ast.Var | symbols.Var

fn (mut e Emitter) ident_for(v IdentForValue) string {
	return match v {
		symbols.Var {
			v.full_name()
		}
		FnDecl {
			e.ident_for(v.sym)
		}
		ast.Var {
			if sym := v.sym() {
				e.ident_for(sym)
			} else {
				panic_and_value(unreachable('sym is nil'), '')
			}
		}
		ArrayLiteral, MapLiteral {
			e.new_tmp_ident()
		}
		Expr {
			match v {
				// v bug: Segfault
				// ast.Var, ArrayLiteral, MapLiteral { e.ident_for(v) }
				ast.Var {
					if sym := v.sym() {
						e.ident_for(sym)
					} else {
						panic_and_value(unreachable('sym is nil'), '')
					}
				}
				ArrayLiteral, MapLiteral {
					e.new_tmp_ident()
				}
				ast.NamespaceItem {
					e.ident_for(v.item)
				}
				else {
					panic_and_value(unreachable('cannot take ident'), '')
				}
			}
		}
	}
}
