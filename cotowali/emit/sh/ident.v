// Copyright (c) 2021 zakuro <z@kuro.red>. All rights reserved.
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
module sh

import cotowali.ast { ArrayLiteral, Expr, FnDecl, MapLiteral }
import cotowali.symbols
import cotowali.util { li_panic }

type IdentForValue = ArrayLiteral | Expr | FnDecl | MapLiteral | ast.Var | symbols.Var

fn (mut e Emitter) ident_for(v IdentForValue) string {
	return match v {
		symbols.Var {
			if v.name == '_' {
				e.ident_to_discard
			} else {
				v.name_for_ident()
			}
		}
		FnDecl {
			e.ident_for(v.sym)
		}
		ast.Var {
			sym := v.sym() or { li_panic(@FILE, @LINE, 'sym is nil') }
			e.ident_for(sym)
		}
		ArrayLiteral, MapLiteral {
			e.new_tmp_ident()
		}
		Expr {
			match v {
				// v bug: Segfault
				// ast.Var, ArrayLiteral, MapLiteral { e.ident_for(v) }
				ast.Var {
					sym := v.sym() or { li_panic(@FILE, @LINE, 'sym is nil') }
					e.ident_for(sym)
				}
				ArrayLiteral, MapLiteral {
					e.new_tmp_ident()
				}
				ast.ModuleItem {
					e.ident_for(v.item)
				}
				ast.SelectorExpr {
					e.ident_for(v.ident)
				}
				else {
					li_panic(@FILE, @LINE, 'cannot take ident')
				}
			}
		}
	}
}
