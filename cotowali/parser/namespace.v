// Copyright (c) 2021 zakuro <z@kuro.red>. All rights reserved.
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
module parser

import cotowali.symbols
import cotowali.ast

fn (mut p Parser) parse_namespace() ?ast.NamespaceDecl {
	$if trace_parser ? {
		p.trace_begin(@FN)
		defer {
			p.trace_end()
		}
	}

	p.consume_with_assert(.key_namespace)
	ident := p.consume_with_check(.ident) ?
	block := p.parse_block(ident.text, []) ?
	return ast.NamespaceDecl{
		block: block
	}
}
