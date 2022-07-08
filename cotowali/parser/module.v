// Copyright (c) 2021 zakuro <z@kuro.red>. All rights reserved.
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
module parser

import cotowali.ast

fn (mut p Parser) parse_module() ?ast.ModuleDecl {
	$if trace_parser ? {
		p.trace_begin(@FN)
		defer {
			p.trace_end()
		}
	}

	p.consume_with_assert(.key_module)

	mut ident := p.consume_with_check(.ident)?

	mut depth := 1
	defer {
		for _ in 0 .. depth {
			p.close_scope()
		}
	}

	mut mod := ast.ModuleDecl{
		block: ast.Block{
			scope: p.open_scope(ident.text)
		}
	}
	for p.kind(0) == .coloncolon {
		p.consume_with_assert(.coloncolon)

		depth += 1
		ident = p.consume_with_check(.ident)?
		mod = ast.ModuleDecl{
			block: ast.Block{
				scope: p.open_scope(ident.text)
			}
		}
	}

	mod.block = p.parse_block_without_new_scope()?
	return mod
}
