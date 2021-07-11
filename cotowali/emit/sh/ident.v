// Copyright (c) 2021 The Cotowali Authors. All rights reserved.
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
module sh

import cotowali.ast { ArrayLiteral, Expr, Var }
import cotowali.errors { unreachable }
import cotowali.util { panic_and_value }

fn (mut e Emitter) ident_for(expr Expr) string {
	return match expr {
		Var { expr.sym.full_name() }
		ArrayLiteral { e.new_tmp_ident() }
		else { panic_and_value(unreachable('cannot take ident'), '') }
	}
}
