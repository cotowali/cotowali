// Copyright (c) 2021-2023 zakuro <z@kuro.red>
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
module checker

import cotowali.ast
import cotowali.context { Context }

pub fn check(mut f ast.File, ctx &Context) {
	mut c := new_checker(ctx)
	c.check(mut f)
}

pub fn (mut c Checker) check(mut f ast.File) {
	c.check_file(mut f)
}

fn (mut c Checker) check_file(mut f ast.File) {
	c.stmts(mut f.stmts)
}
