// Copyright (c) 2021 zakuro <z@kuro.red>. All rights reserved.
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
module pwsh

import cotowali.ast { ArrayLiteral, Expr, FnDecl, FnParam, MapLiteral }
import cotowali.symbols
import cotowali.util { li_panic }

type ValueOfIdentFor = ArrayLiteral
	| Expr
	| FnDecl
	| FnParam
	| MapLiteral
	| ast.Var
	| string
	| symbols.Var

fn (mut e Emitter) ident_for(v ValueOfIdentFor) string {
	return match v {
		string {
			v
		}
		symbols.Var {
			if v.name == '_' {
				'null'
			} else {
				v.name_for_ident()
			}
		}
		FnDecl {
			e.ident_for(v.sym)
		}
		FnParam {
			e.ident_for(v.var_)
		}
		ast.Var {
			sym := v.sym() or { li_panic(@FN, @FILE, @LINE, 'sym is nil') }
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
					sym := v.sym() or { li_panic(@FN, @FILE, @LINE, 'sym is nil') }
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
					li_panic(@FN, @FILE, @LINE, 'cannot take ident')
				}
			}
		}
	}
}
