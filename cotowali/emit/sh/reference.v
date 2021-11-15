// Copyright (c) 2021 zakuro <z@kuro.red>. All rights reserved.
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
module sh

import cotowali.ast

fn (mut e Emitter) reference(expr ast.Expr) {
	e.write(match expr {
		ast.PrefixExpr { e.ident_for(expr.expr) }
		else { panic('cannt take reference') }
	})
}
