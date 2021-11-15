// Copyright (c) 2021 zakuro <z@kuro.red>. All rights reserved.
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
module pwsh

import cotowali.ast { CallCommandExpr, CallExpr, FnDecl }

fn (mut e Emitter) call_command_expr(expr CallCommandExpr, opt ExprOpt) {
	panic('unimplemented')
}

fn (mut e Emitter) call_expr(expr CallExpr, opt ExprOpt) {
	panic('unimplemented')
}

fn (mut e Emitter) fn_decl(node FnDecl) {
	if !node.has_body {
		return
	}
	panic('unimplemented')
}
