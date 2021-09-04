// Copyright (c) 2021 zakuro <z@kuro.red>. All rights reserved.
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
module sh

import cotowali.ast { ArrayLiteral, Expr, MapLiteral }
import cotowali.symbols
import cotowali.errors { unreachable }
import cotowali.util { panic_and_value }

type IdentForValue = ArrayLiteral | Expr | MapLiteral | ast.Var | symbols.Var

fn (mut e Emitter) ident_for(v IdentForValue) string {
	return match v {
		symbols.Var {
			v.full_name()
		}
		ast.Var {
			e.ident_for(v.sym)
		}
		ArrayLiteral, MapLiteral {
			e.new_tmp_ident()
		}
		Expr {
			match v {
				ast.Var {
					e.ident_for(v.sym)
				}
				ArrayLiteral, MapLiteral {
					e.new_tmp_ident()
				}
				// v bug: Segfault
				// ast.Var, ArrayLiteral, MapLiteral { e.ident_for(v) }
				else {
					panic_and_value(unreachable('cannot take ident'), '')
				}
			}
		}
	}
}
