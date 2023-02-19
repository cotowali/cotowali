// Copyright (c) 2021-2023 zakuro <z@kuro.red>. All rights reserved.
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
module kuqi

import cotowali.source { Pos }
import cotowali.context { Context }
import lsp

fn pos_to_range(p Pos) lsp.Range {
	return lsp.Range{
		start: lsp.Position{
			line: p.line - 1
			character: p.col - 1
		}
		end: lsp.Position{
			line: p.last_line - 1
			character: p.last_col
		}
	}
}

[params]
struct ContextOpts {
	no_builtin bool
}

fn new_context(opts ContextOpts) &Context {
	return context.new_context(
		no_emit: true
		no_builtin: opts.no_builtin
		feature: .warn_all
	)
}
