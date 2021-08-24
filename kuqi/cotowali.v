// Copyright (c) 2021 zakuro <z@kuro.red>. All rights reserved.
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
module kuqi

import cotowali.source { Pos }
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
