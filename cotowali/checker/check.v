// Copyright (c) 2021 The Cotowali Authors. All rights reserved.
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
module checker

import cotowali.ast

pub fn (mut c Checker) check_file(mut f ast.File) {
	$if trace_checker ? {
		c.trace_begin(@FN)
		defer {
			c.trace_end()
		}
	}

	old_source := c.source
	defer {
		c.source = old_source
	}
	c.source = f.source
	c.stmts(f.stmts)
}
