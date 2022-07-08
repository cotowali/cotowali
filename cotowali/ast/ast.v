// Copyright (c) 2021 zakuro <z@kuro.red>. All rights reserved.
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
module ast

import cotowali.source { Source }
import cotowali.util.checksum

pub type Node = Expr | File | FnParam | Ident | Stmt

[heap]
pub struct File {
pub:
	source &Source
pub mut:
	stmts []Stmt
}

pub fn (f &File) checksum(algo checksum.Algorithm) string {
	return f.source.checksum(algo)
}

fn (mut r Resolver) file(mut f File) {
	$if trace_resolver ? {
		r.trace_begin(@FN)
		defer {
			r.trace_end()
		}
	}

	r.stmts(mut f.stmts)
}
